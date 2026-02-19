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
import ShufflePrincipals "../utils/shuffle_principals";
import CreateRound "create_round";

module {
    public func analyzeRound(
        api_gateway : Principal,
        community_id : Principal,
        cohort : Types.Cohort,
        iteration : Nat,
    ) : async Result.Result<(), Text> {
        let ?round = Map.get(cohort.rounds, Nat.compare, iteration) else {
            return #ok(());
        };

        // Check if all groups of the rounds have winners
        if (not allGroupsHaveWinner(round)) {
            return #ok(());
        };

        // Collect all winners as the participants for the next round
        let winners = List.empty<Principal>();

        for ((_, group) in Map.entries(round.groups)) {
            for (winner in Iter.fromArray(group.winner_ids)) {
                List.add(winners, winner);
            };
        };

        // Check whether we have enough people to form another round
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

            return #ok(());
        };

        // When we don't form another round, we determine the cohort winners
        cohort.winner_ids := switch (
            await determineCohortWinners(
                List.toArray(winners),
                cohort.config,
            )
        ) {
            case (#ok(w)) w;
            case (#err(e)) return #err(e);
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

        #ok(())
    };

    func allGroupsHaveWinner(round : Types.Round) : Bool {
        for ((_, group) in Map.entries(round.groups)) {
            if (Array.size(group.winner_ids) == 0) {
                return false;
            };
        };

        return true;
    };

    public func determineCohortWinners(
        finalists : [Principal],
        config : Types.CohortConfig,
    ) : async Result.Result<[Principal], Text> {
        // Consider the selection mode.
        // If we only want to have a single winner, we have to pick one randomly
        if (config.selection_mode == #single) {
            let number_of_finalists = Array.size(finalists);
            let random_index = await* Random.crypto().natRange(0, number_of_finalists); // The second parameter is exclusive
            let winner = finalists[random_index];

            return #ok([winner]);
        };

        // This is for good measure as this is checked during the cohort creation
        let ?advancement_limit = config.advancement_limit else {
            return #err("Advancement limit needs to be set");
        };

        // This is for good measure as this is checked during the cohort creation
        if (advancement_limit < 2) {
            return #err("Invalid advancement limit");
        };

        // Before applying the advancement limit, we shuffle the finalists
        let shuffled_finalists = await ShufflePrincipals.shufflePrincipals(finalists);

        // Return as many winners as the advancement limit allows
        #ok(Array.sliceToArray(shuffled_finalists, 0, advancement_limit));
    };
};
