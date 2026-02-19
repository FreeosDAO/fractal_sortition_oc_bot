import Array "mo:core/Array";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import { expect; suite; test } "mo:test/async";

import AnalyzeRound "../../src/fractal_sortition_oc_bot_backend/lib/analyze_round";
import Helpers "helpers";

func showResult(r : Result.Result<[Principal], Text>) : Text {
    debug_show (r);
};

func equalResult(
    a : Result.Result<[Principal], Text>,
    b : Result.Result<[Principal], Text>,
) : Bool {
    let winners_a = switch (a) {
        case (#ok(w)) w;
        case (#err(error_message_a)) {
            let error_message_b = switch (b) {
                case (#ok(_)) return false;
                case (#err(m)) m;
            };

            return error_message_a == error_message_b;
        };
    };

    let winners_b = switch (b) {
        case (#ok(w)) w;
        case (#err(_)) return false; // We can just return false since we do the error message check above
    };

    Array.compare<Principal>(winners_a, winners_b, Principal.compare) == #equal;
};

await suite(
    "Analyze round",
    func() : async () {
        await test(
            "Cohort winner selection considers advancement limit for selection mode #panel",
            func() : async () {
                let advancement_limit = 3;

                // Get the winners
                let result = await AnalyzeRound.determineCohortWinners(
                    Helpers.random_principals(),
                    {
                        min_num_volunteers = 9;
                        optimization_mode = #speed;
                        selection_mode = #panel;
                        advancement_limit = ?advancement_limit;
                    },
                );

                // Check we get winners
                expect.result<[Principal], Text>(result, showResult, equalResult).isOk();

                // Check that the number of winners respects the advancement limit
                switch (result) {
                    case (#ok(winners)) {
                        expect.nat(Array.size(winners)).equal(advancement_limit);
                    };
                    case (_) {
                        // We expect to get winners (also checked above)
                        return expect.bool(false).isTrue();
                    };
                };
            },
        );

        await test(
            "Cohort winner selection only returns a single user ID for selection mode #single",
            func() : async () {
                // Get the winners
                let result = await AnalyzeRound.determineCohortWinners(
                    Helpers.random_principals(),
                    {
                        min_num_volunteers = 9;
                        optimization_mode = #speed;
                        selection_mode = #single;
                        advancement_limit = null;
                    },
                );

                // Check we get winners
                expect.result<[Principal], Text>(result, showResult, equalResult).isOk();

                // Check that we only get a single winner
                switch (result) {
                    case (#ok(winners)) {
                        expect.nat(Array.size(winners)).equal(1);
                    };
                    case (_) {
                        // We expect to get winners (also checked above)
                        return expect.bool(false).isTrue();
                    };
                };
            },
        );

        await test(
            "Cohort winner selection checks that the advancement limit is set for selection mode #panel",
            func() : async () {
                // Get the winners
                let result = await AnalyzeRound.determineCohortWinners(
                    Helpers.random_principals(),
                    {
                        min_num_volunteers = 9;
                        optimization_mode = #speed;
                        selection_mode = #panel;
                        advancement_limit = null;
                    },
                );

                // Check we get an error
                expect.result<[Principal], Text>(result, showResult, equalResult).equal(#err("Advancement limit needs to be set"));
            },
        );

        await test(
            "Cohort winner selection checks that the advancement limit is valid for selection mode #panel",
            func() : async () {
                // Get the winners
                let result = await AnalyzeRound.determineCohortWinners(
                    Helpers.random_principals(),
                    {
                        min_num_volunteers = 9;
                        optimization_mode = #speed;
                        selection_mode = #panel;
                        advancement_limit = ?1;
                    },
                );

                // Check we get an error
                expect.result<[Principal], Text>(result, showResult, equalResult).equal(#err("Invalid advancement limit"));
            },
        );
    },
);
