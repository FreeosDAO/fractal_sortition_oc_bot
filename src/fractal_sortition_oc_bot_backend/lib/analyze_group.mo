import Array "mo:core/Array";
import Iter "mo:core/Iter";
import List "mo:core/List";
import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Principal "mo:core/Principal";
import Random "mo:core/Random";
import Result "mo:core/Result";
import Client "mo:openchat-bot-sdk/client";

import Types "../types";
import AnalyzeRound "./analyze_round";
import ShufflePrincipals "../utils/shuffle_principals";

module {
    // This function checks whether all participants have voted.
    // If yes, it saves the winners in the group if they aren't already.
    public func analyzeGroup(
        api_gateway : Principal,
        community_id : Principal,
        cohort : Types.Cohort,
        group : Types.Group,
        iteration : Nat,
    ) : async Result.Result<(), Text> {
        // Check if all participants have voted
        if (not allParticipantsVoted(group)) {
            return #ok(());
        };

        // Check if group already has a winner
        if (not Array.isEmpty(group.winner_ids)) {
            return #ok(());
        };

        // Tally votes
        let tallies = tallyVotes(group);

        // Save winners on group
        group.winner_ids := switch (await getWinners(tallies, cohort.config)) {
            case (#ok(w)) w;
            case (#err(e)) return #err(e);
        };

        // Send message to the group who won the vote
        let autonomous_client = Client.OpenChatClient({
            apiGateway = api_gateway;
            scope = #Chat(#Channel(community_id, group.channel_id));
            jwt = null;
            messageId = null;
            thread = null;
        });
        var text = if (Array.size(group.winner_ids) > 1) {
            "Group winners:";
        } else {
            "Group winner:";
        };

        for (principal in Iter.fromArray(group.winner_ids)) {
            text #= " @UserId(" # Principal.toText(principal) # ")";
        };

        // Send the message
        ignore await autonomous_client.sendTextMessage(text).execute();

        // We will analyze whether the round has a winner in a detached async task
        ignore async {
            await AnalyzeRound.analyzeRound(
                api_gateway,
                community_id,
                cohort,
                iteration,
            );
        };

        #ok(())
    };

    // Check whether all participants in a group have voted
    func allParticipantsVoted(group : Types.Group) : Bool {
        for ((_, participant) in Map.entries(group.participants)) {
            if (participant.vote == null) {
                return false;
            };
        };

        return true;
    };

    // Count the number of votes participants have received
    func tallyVotes(group : Types.Group) : Map.Map<Principal, Nat> {
        let tallies = Map.empty<Principal, Nat>();

        for ((_, participant) in Map.entries(group.participants)) {
            switch (participant.vote) {
                case (?vote) {
                    let current = switch (Map.get(tallies, Principal.compare, vote.recipient_id)) {
                        case (?n) n;
                        case null 0;
                    };

                    Map.add(tallies, Principal.compare, vote.recipient_id, current + 1);
                };
                case null {};
            };
        };

        return tallies;
    };

    // Get the participant or participants that received the most votes.
    // If there is a tie, the advancement limit is considered.
    public func getWinners(
        tallies : Map.Map<Principal, Nat>,
        config : Types.CohortConfig,
    ) : async Result.Result<[Principal], Text> {
        var max_tally : Nat = 0;
        var winners = List.empty<Principal>();

        for ((principal, tally) in Map.entries(tallies)) {
            if (tally > max_tally) {
                // We found a bigger tally so we update the max tally
                max_tally := tally;
                // We reset the winners
                winners := List.empty<Principal>();

                List.add(winners, principal);
            } else if (tally == max_tally) {
                List.add(winners, principal);
            };
        };

        // Consider the selection mode.
        // If we only want to have a single winner, we have to pick one randomly
        if (config.selection_mode == #single) {
            let number_of_winners = List.size(winners);
            let random_index = await* Random.crypto().natRange(0, number_of_winners); // The second parameter is exclusive

            return #ok([List.toArray(winners)[random_index]]);
        };

        // This is for good measure as this is checked during the cohort creation
        let ?advancement_limit = config.advancement_limit else {
            return #err("Advancement limit needs to be set");
        };

        // This is for good measure as this is checked during the cohort creation
        if (advancement_limit < 2) {
            return #err("Invalid advancement limit");
        };

        // Before applying the advancement limit, we shuffle the winners
        let shuffled_winners = await ShufflePrincipals.shufflePrincipals(List.toArray(winners));

        // Return as many winners as the advancement limit allows
        #ok(Array.sliceToArray(shuffled_winners, 0, advancement_limit))
    };
};
