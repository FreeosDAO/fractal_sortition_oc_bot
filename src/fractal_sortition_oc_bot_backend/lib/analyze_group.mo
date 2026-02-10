import List "mo:core/List";
import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Principal "mo:core/Principal";
import Array "mo:core/Array";
import Random "mo:core/Random";
import Iter "mo:core/Iter";
import Client "mo:openchat-bot-sdk/client";

import Types "../types";
import AnalyzeRound "./analyze_round";

module {
    // This function checks whether all participants have voted.
    // If yes, it saves the winners in the group if they aren't already.
    public func analyzeGroup(
        api_gateway : Principal,
        community_id : Principal,
        cohort_title : Text,
        rounds : Map.Map<Nat, Types.Round>, 
        iteration : Nat,
        group : Types.Group,
        cohort_config : Types.CohortConfig,
    ) : async () {
        // Check if all participants have voted
        if (not allParticipantsVoted(group)) {
            return;
        };

        // Check if group already has a winner
        if (not Array.isEmpty(group.winner_ids)) {
            return;
        };

        // Tally votes
        let tallies = tallyVotes(group);

        // Save winners on group
        group.winner_ids := await getWinners(tallies, cohort_config.selection_mode);

        // Send message to the group who won the vote
        let autonomous_client = Client.OpenChatClient({
            apiGateway = api_gateway;
            scope = #Chat(#Channel(community_id, group.channel_id));
            jwt = null;
            messageId = null;
            thread = null;
        });
        var text = if (Array.size(group.winner_ids) > 1) {
            "Winners:";
        } else {
            "Winner:";
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
                cohort_title,
                rounds,
                iteration,
                cohort_config.optimization_mode
            );
        };
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
    // If there is a tie, all participants with that vote count are returned.
    func getWinners(tallies : Map.Map<Principal, Nat>, selection_mode : Types.SelectionMode) : async [Principal] {
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
        if (selection_mode == #single) {
            let number_of_winners = List.size(winners);
            let random_index = await* Random.crypto().natRange(0, number_of_winners); // The second parameter is exclusive

            return [List.toArray(winners)[random_index]];
        };

        return List.toArray(winners);
    };
};
