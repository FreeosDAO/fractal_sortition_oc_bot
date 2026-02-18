import Result "mo:core/Result";
import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Nat32 "mo:core/Nat32";
import Time "mo:core/Time";
import Array "mo:core/Array";
import Nat "mo:core/Nat";
import Types "../types";

module {
    public func create_cohort(
        title : Text,
        config : Types.CohortConfig,
        community : Types.Community,
        channel_id : Nat32
    ) : Result.Result<Types.Cohort, Text> {
        // Check that the min_num_volunteers is set to at least 9 to allow for a meaningful creation of groups
        if (config.min_num_volunteers < 9) {
            return #err("The minimum number of volunteers has to be set to at least 9");
        };

        // Check the advancement limit configuration when the selection mode is #panel
        if (config.selection_mode == #panel) {
            switch (config.advancement_limit) {
                // Check that the advancement limit is set
                case null {
                    return #err("The advancement limit needs to be set for selection mode #panel");
                };
                // Check that the advancement limit is at least 2
                case (?limit) {
                    if (limit < 2) {
                        return #err("The advancement limit needs to be set to at least 2");
                    };
                };
            };
        };

        // We check that the minimum number of volunteers is reached
        if (Map.size(community.volunteers) < config.min_num_volunteers) {
            return #err("There are not enough volunteers to create the cohort");
        };

        // Create the cohort based on the args.
        let cohort : Types.Cohort = {
            id = community.cohorts.size; // This is an incremental ID so we just take the existing number of cohorts. This if fine since we don't delete cohorts.
            title = title;
            channel_id = channel_id;
            started_at = Time.now();
            rounds = Map.empty<Nat, Types.Round>();
            var winner_ids = Array.empty<Principal>();
            config = config;
        };

        // Save the cohort in the community
        Map.add(
            community.cohorts,
            Nat.compare,
            cohort.id,
            cohort,
        );

        #ok(cohort)
    };
};
