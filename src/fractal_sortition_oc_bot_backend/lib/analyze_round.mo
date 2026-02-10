import Types "../types";
import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Array "mo:core/Array";
import List "mo:core/List";
import Iter "mo:core/Iter";
import Principal "mo:core/Principal";
import CreateRound "create_round";

module {
    public func analyzeRound(
        api_gateway : Principal,
        community_id : Principal,
        cohort_title : Text,
        rounds : Map.Map<Nat, Types.Round>, 
        iteration : Nat,
        optimization_mode : Types.OptimizationMode
    ) : async () {
        let ?round = Map.get(rounds, Nat.compare, iteration) else {
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
                cohort_title,
                rounds,
                List.toArray(winners), 
                iteration + 1,
                optimization_mode
            );
        } else {
            await determineCohortWinners(List.toArray(winners));
        }
    };

    func allGroupsHaveWinner(round : Types.Round) : Bool {
        for ((_, group) in Map.entries(round.groups)) {
            if (Array.size(group.winner_ids) == 0) {
                return false;
            };
        };

        return true;
    };

    func determineCohortWinners(finalists : [Principal]) : async () {};
}