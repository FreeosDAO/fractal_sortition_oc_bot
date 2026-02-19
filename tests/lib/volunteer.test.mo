import Iter "mo:core/Iter";
import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Time "mo:core/Time";
import { expect; suite; test } "mo:test";

import Volunteer "../../src/fractal_sortition_oc_bot_backend/lib/volunteer";
import Types "../../src/fractal_sortition_oc_bot_backend/types";
import Helpers "./helpers";

func showResult(r : Result.Result<Bool, Text>) : Text {
    debug_show (r);
};

func equalResult(
    a : Result.Result<Bool, Text>,
    b : Result.Result<Bool, Text>,
) : Bool {
    a == b;
};

suite(
    "Volunteer",
    func() {
        test(
            "Can volunteer",
            func() {
                let volunteers = Map.empty<Principal, Types.Volunteer>();

                for (user_id in Iter.fromArray(Helpers.random_principals())) {
                    // Add user using the volunteer function
                    let result : Result.Result<Bool, Text> = Volunteer.volunteer(user_id, volunteers);

                    expect.result<Bool, Text>(result, showResult, equalResult).equal(#ok(true));

                    // Check that the volunteer has been added correctly
                    let ?volunteer = Map.get(volunteers, Principal.compare, user_id) else {
                        // We expect the volunteer to exist
                        return expect.bool(false).isTrue();
                    };

                    expect.principal(volunteer.user_id).equal(user_id);
                    expect.int(volunteer.registered_at).lessOrEqual(Time.now());
                };
            },
        );

        test(
            "Can't volunteer multiple times",
            func() {
                let volunteers = Map.empty<Principal, Types.Volunteer>();
                let user_id = Principal.fromText("w7x7r-cok77-xa");

                // Add user using the volunteer function
                let result_initial : Result.Result<Bool, Text> = Volunteer.volunteer(user_id, volunteers);

                // We expect that can volunteer initially
                expect.result<Bool, Text>(result_initial, showResult, equalResult).equal(#ok(true));

                // Try to volunteer again
                let result_retry : Result.Result<Bool, Text> = Volunteer.volunteer(user_id, volunteers);

                // We expect an error when they try again
                expect.result<Bool, Text>(result_retry, showResult, equalResult).equal(#err("User already volunteered"));
            },
        );
    },
);
