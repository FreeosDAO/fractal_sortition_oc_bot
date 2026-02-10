import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Time "mo:core/Time";
import Sdk "mo:openchat-bot-sdk";
import CommandScope "mo:openchat-bot-sdk/api/common/commandScope";

import AnalyzeGroup "../lib/analyze_group";
import GetCommunity "../lib/get_community";
import Types "../types";

// The "vote" function registers which group member a person wants to advance to the next round
module {
    public func build(community_registry : Types.CommunityRegistry) : Sdk.Command.Handler {
        {
            definition = definition();
            execute = func(c : Sdk.OpenChat.Client, ctx : Sdk.Command.Context) : async Sdk.Command.Result {
                await execute(c, ctx, community_registry);
            };
        };
    };

    type VoteContext = {
        rounds : Map.Map<Nat, Types.Round>;
        iteration : Nat;
        group : Types.Group;
        cohort_title : Text;
        cohort_config : Types.CohortConfig;
    };

    // For now, we have to iterate through all cohorts and their rounds until we
    // find the group with the right channel ID. These can be a lot of look-ups, but
    // given the current data size, this is acceptable because our code remains
    // easier to reason about. Should the stored data increase significatnly, we can
    // maintain a reverse index from channel IDs to round and cohort IDs.
    func getVoteContext(community : Types.Community, channel_id : Nat32) : ?VoteContext {
        for ((_, cohort) in Map.entries(community.cohorts)) {
            for ((_, round) in Map.entries(cohort.rounds)) {
                for ((_, group) in Map.entries(round.groups)) {
                    if (group.channel_id == channel_id) {
                        return ?{
                            rounds = cohort.rounds;
                            iteration = round.iteration;
                            group = group;
                            cohort_title = cohort.title;
                            cohort_config = cohort.config;
                        };
                    };
                };
            };
        };

        null;
    };

    func execute(
        client : Sdk.OpenChat.Client,
        context : Sdk.Command.Context,
        community_registry : Types.CommunityRegistry,
    ) : async Sdk.Command.Result {
        // Get community
        let ?(community_id, community) = GetCommunity.getCommunity(context.scope, community_registry) else {
            let message = await client.sendTextMessage(
                "Votes can only be casted from inside of a community."
            ).executeThenReturnMessage(null);

            return #ok { message };
        };

        // Get the user who casts the vote
        let voter_id = context.command.initiator;
        // Get the candidate receiving the vote
        let recipient_id = Sdk.Command.Arg.user(context.command, "recipient_id");

        // Make sure the participant doesn't vote for themselves
        if (voter_id == recipient_id) {
            let message = await client.sendTextMessage(
                "You cannot vote for yourself."
            ).executeThenReturnMessage(null);

            return #ok { message };
        };

        // Get the community and channel ID
        let chat_details = switch (CommandScope.chatDetails(context.scope)) {
            case (?details) details;
            case (_) {
                let message = await client.sendTextMessage(
                    "Could not get group ID."
                ).executeThenReturnMessage(null);

                return #ok { message };
            };
        };
        let #Channel(_, channel_id) = chat_details.chat else {
            let message = await client.sendTextMessage(
                "Could not get chat details."
            ).executeThenReturnMessage(null);

            return #ok { message };
        };

        // Retrieve the vote context
        let ?vote_context = getVoteContext(community, channel_id) else {
            let message = await client.sendTextMessage(
                "Could not get vote context."
            ).executeThenReturnMessage(null);

            return #ok { message };
        };

        // Check that the recipient is part of the group's participants
        let ?_recipient = Map.get(vote_context.group.participants, Principal.compare, recipient_id) else {
            let message = await client.sendTextMessage(
                "The recipient is not a participant of this group"
            ).executeThenReturnMessage(null);

            return #ok { message };
        };

        // Check that the user hasn't voted yet
        let ?participant = Map.get(vote_context.group.participants, Principal.compare, voter_id) else {
            let message = await client.sendTextMessage(
                "You are not a participant of this group"
            ).executeThenReturnMessage(null);

            return #ok { message };
        };

        if (participant.vote != null) {
            let message = await client.sendTextMessage(
                "You have voted already"
            ).executeThenReturnMessage(null);

            return #ok { message };
        };

        // Save the vote
        participant.vote := ?{
            voter_id = voter_id;
            recipient_id = recipient_id;
            voted_at = Time.now();
        };

        let text = "The vote has been casted";
        let message = await client.sendTextMessage(text).executeThenReturnMessage(null);

        // We will analyze whether the group has a winner in a detached async task
        ignore async {
            await AnalyzeGroup.analyzeGroup(
                context.apiGateway, 
                community_id, 
                vote_context.cohort_title,
                vote_context.rounds, 
                vote_context.iteration,
                vote_context.group,
                vote_context.cohort_config
            );
        };

        return #ok { message = message };
    };

    func definition() : Sdk.Definition.Command {
        {
            name = "vote";
            description = ?"Vote for a group member";
            placeholder = ?"Casting vote...";
            params = [{
                name = "recipient_id";
                description = ?"The member you want to vote for";
                placeholder = null;
                required = true;
                param_type = #UserParam;
            }];
            permissions = {
                community = [];
                chat = [];
                message = [#Text];
            };
            default_role = ?#Participant;
            direct_messages = null;
        };
    };
};
