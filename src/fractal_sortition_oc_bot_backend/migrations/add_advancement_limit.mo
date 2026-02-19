import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Principal "mo:core/Principal";

import Types "../types";
import TypesV1 "./types_v1";

// We have added the advancement limit to the cohort config
module AddAdvancementLimitMigration {
    public func migration(old : { var community_registry : TypesV1.CommunityRegistry }) : {
        var community_registry : Types.CommunityRegistry;
    } {
        let newRegistry = Map.map<Principal, TypesV1.Community, Types.Community>(
            old.community_registry,
            func(_community_id, community) {
                let new_cohorts = Map.map<Nat, TypesV1.Cohort, Types.Cohort>(
                    community.cohorts,
                    func(_cohort_id, cohort) {
                        let new_config : Types.CohortConfig = {
                            min_num_volunteers = cohort.config.min_num_volunteers;
                            optimization_mode = cohort.config.optimization_mode;
                            selection_mode = cohort.config.selection_mode;
                            advancement_limit = null; // New field we added. Default to null
                        };

                        {
                            id = cohort.id;
                            channel_id = cohort.channel_id;
                            title = cohort.title;
                            started_at = cohort.started_at;
                            rounds = cohort.rounds;
                            var winner_ids = cohort.winner_ids;
                            config = new_config;
                        };
                    },
                );

                {
                    id = community.id;
                    volunteers = community.volunteers;
                    cohorts = new_cohorts;
                };
            },
        );

        { var community_registry = newRegistry };
    };
};
