import Iter "mo:core/Iter";
import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Nat32 "mo:core/Nat32";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Time "mo:core/Time";
import Bool "mo:core/Bool";
import { expect; suite; test } "mo:test";

import CreateCohort "../../src/fractal_sortition_oc_bot_backend/lib/create_cohort";
import Volunteer "../../src/fractal_sortition_oc_bot_backend/lib/volunteer";
import Types "../../src/fractal_sortition_oc_bot_backend/types";
import Helpers "./helpers";

func showResult(r : Result.Result<Types.Cohort, Text>) : Text {
    debug_show (r);
};

func equalResult(
    a : Result.Result<Types.Cohort, Text>,
    b : Result.Result<Types.Cohort, Text>,
) : Bool {
    let cohort_a = switch (a) {
        case (#ok(c)) c;
        case (#err(error_message_a)) {
            let error_message_b = switch (b) {
                case (#ok(_)) return false;
                case (#err(m)) m;
            };

            return error_message_a == error_message_b;
        };
    };

    let cohort_b = switch (b) {
        case (#ok(c)) c;
        case (#err(_)) return false; // We can just return false since we do the error message check above
    };

    cohort_a.id == cohort_b.id;
};

suite(
    "Create cohort",
    func() {
        test(
            "Can create cohort",
            func() {
                let title : Text = "Education";
                let config : Types.CohortConfig = {
                    min_num_volunteers = 9;
                    optimization_mode = #meritocracy;
                    selection_mode = #single;
                };
                let community : Types.Community = {
                    id = Principal.fromText("2chl6-4hpzw-vqaaa-aaaaa-c");
                    volunteers = Map.empty<Principal, Types.Volunteer>();
                    cohorts = Map.empty<Nat, Types.Cohort>();
                };
                let channel_id : Nat32 = 6374638;

                // Add volunteers
                for (user_id in Iter.fromArray(Helpers.random_principals())) {
                    ignore Volunteer.volunteer(user_id, community.volunteers);
                };

                // Create cohort
                let result = CreateCohort.create_cohort(title, config, community, channel_id);

                // Check that cohort has been created
                let ?cohort = Map.get(community.cohorts, Nat.compare, 0) else {
                    // We expect the cohort to exist
                    return expect.bool(false).isTrue();
                };

                expect.result<Types.Cohort, Text>(result, showResult, equalResult).equal(#ok(cohort));

                // Validate the cohort parameters
                expect.nat32(cohort.channel_id).equal(channel_id);
                expect.text(cohort.title).equal(title);
                expect.int(cohort.started_at).lessOrEqual(Time.now());
                expect.int(Map.size(cohort.rounds)).equal(0);
                expect.array(cohort.winner_ids, Principal.toText, Principal.equal).size(0);
                expect.int(cohort.config.min_num_volunteers).equal(config.min_num_volunteers);
                assert cohort.config.optimization_mode == config.optimization_mode;
                assert cohort.config.selection_mode == config.selection_mode;
            },
        );

        test(
            "Cannot create cohort without enough volunteers",
            func() {
                let title : Text = "Education";
                let config : Types.CohortConfig = {
                    min_num_volunteers = 9;
                    optimization_mode = #meritocracy;
                    selection_mode = #single;
                };
                let community : Types.Community = {
                    id = Principal.fromText("2chl6-4hpzw-vqaaa-aaaaa-c");
                    volunteers = Map.empty<Principal, Types.Volunteer>();
                    cohorts = Map.empty<Nat, Types.Cohort>();
                };
                let channel_id : Nat32 = 6374638;

                // Add 5 volunteers (9 would be required)
                for (user_id in Iter.take(Iter.fromArray(Helpers.random_principals()), 5)) {
                    ignore Volunteer.volunteer(user_id, community.volunteers);
                };

                // Try to create cohort
                let result = CreateCohort.create_cohort(title, config, community, channel_id);

                // Expect the cohort creation to fail
                expect.result<Types.Cohort, Text>(result, showResult, equalResult).equal(#err("There are not enough volunteers to create the cohort"));

                // Check that no cohort has been added to the community
                expect.option(
                    Map.get(community.cohorts, Nat.compare, 0), 
                    func (c) {
                        debug_show(c);
                    },
                    func (c1: Types.Cohort, c2: Types.Cohort) : Bool {
                        c1.id == c2.id;
                    }
                ).isNull();
            },
        );

        test(
            "Cannot create a cohort if min_num_volunteers is set to less than 9",
            func() {
                let title : Text = "Education";
                let config : Types.CohortConfig = {
                    min_num_volunteers = 8;
                    optimization_mode = #meritocracy;
                    selection_mode = #single;
                };
                let community : Types.Community = {
                    id = Principal.fromText("2chl6-4hpzw-vqaaa-aaaaa-c");
                    volunteers = Map.empty<Principal, Types.Volunteer>();
                    cohorts = Map.empty<Nat, Types.Cohort>();
                };
                let channel_id : Nat32 = 6374638;

                // Try to create cohort
                let result = CreateCohort.create_cohort(title, config, community, channel_id);

                // Expect the cohort creation to fail
                expect.result<Types.Cohort, Text>(result, showResult, equalResult).equal(#err("The minimum number of volunteers has to be set to at least 9"));

                // Check that no cohort has been added to the community
                expect.option(
                    Map.get(community.cohorts, Nat.compare, 0), 
                    func (c) {
                        debug_show(c);
                    },
                    func (c1: Types.Cohort, c2: Types.Cohort) : Bool {
                        c1.id == c2.id;
                    }
                ).isNull();
            }
        );
    },
);
