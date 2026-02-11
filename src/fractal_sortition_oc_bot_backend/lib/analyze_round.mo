import Array "mo:core/Array";
import Iter "mo:core/Iter";
import List "mo:core/List";
import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Principal "mo:core/Principal";
import Random "mo:core/Random";
import Client "mo:openchat-bot-sdk/client";

import Types "../types";
import CreateRound "create_round";

module {
    public func analyzeRound(
        api_gateway : Principal,
        community_id : Principal,
        cohort : Types.Cohort,
        iteration : Nat,
    ) : async () {
        let ?round = Map.get(cohort.rounds, Nat.compare, iteration) else {
            return;
        };

        // Check if all groups of the rounds have winners
        if (not allGroupsHaveWinner(round)) {
            return;
        };

        // Collect all winners as the participants for the next round
        let winners = List.empty<Principal>();

        for ((_, group) in Map.entries(round.groups)) {
            for (winner in Iter.fromArray(group.winner_ids)) {
                List.add(winners, winner);
            };
        };

        // Check whether we have enough people to form another round
        // TODO: Currently, a cohort could be endless if all members always receive the same amount of votes
        if (List.size(winners) >= 3) {
            await CreateRound.createRound(
                api_gateway,
                community_id,
                cohort.title,
                cohort.rounds,
                List.toArray(winners),
                iteration + 1,
                cohort.config.optimization_mode,
            );
        } else {
            await determineCohortWinners(
                api_gateway,
                community_id,
                List.toArray(winners),
                cohort,
            );
        };
    };

    func allGroupsHaveWinner(round : Types.Round) : Bool {
        for ((_, group) in Map.entries(round.groups)) {
            if (Array.size(group.winner_ids) == 0) {
                return false;
            };
        };

        return true;
    };

    func determineCohortWinners(
        api_gateway : Principal,
        community_id : Principal,
        finalists : [Principal],
        cohort : Types.Cohort,
    ) : async () {
        // If we can only have a single winner, we pick a random one
        if (cohort.config.selection_mode == #single) {
            let number_of_finalists = Array.size(finalists);
            let random_index = await* Random.crypto().natRange(0, number_of_finalists); // The second parameter is exclusive
            let winner = finalists[random_index];

            cohort.winner_ids := [winner];
        } else {
            cohort.winner_ids := finalists;
        };

        // Send message to the main channel who won the cohort
        let autonomous_client = Client.OpenChatClient({
            apiGateway = api_gateway;
            scope = #Chat(#Channel(community_id, cohort.channel_id));
            jwt = null;
            messageId = null;
            thread = null;
        });
        var text = if (Array.size(cohort.winner_ids) > 1) {
            "Winners of cohort " # cohort.title # ":";
        } else {
            "Winner of cohort " # cohort.title # ":";
        };

        for (principal in Iter.fromArray(cohort.winner_ids)) {
            text #= " @UserId(" # Principal.toText(principal) # ")";
        };

        // Send the message
        ignore await autonomous_client.sendTextMessage(text).execute();
    };
};
