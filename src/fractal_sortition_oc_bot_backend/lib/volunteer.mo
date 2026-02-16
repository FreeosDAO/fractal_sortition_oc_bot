import Result "mo:core/Result";
import Bool "mo:core/Bool";
import Text "mo:core/Text";
import Principal "mo:core/Principal";
import Map "mo:core/Map";
import Time "mo:core/Time";
import Types "../types";

module {
    public func volunteer(user_id: Principal, volunteers: Map.Map<Principal, Types.Volunteer>) : Result.Result<Bool, Text> {
        // Check whether the user already volunteered
        switch (Map.get(volunteers, Principal.compare, user_id)) {
            // The user hasn't volunteered yet, so we add them
            case (null) {
                Map.add(
                    volunteers,
                    Principal.compare,
                    user_id,
                    {
                        user_id = user_id;
                        registered_at = Time.now();
                    }
                );

                #ok(true);
            };
            // The user already volunteered
            case (?_) {
                #err("User already volunteered");
            };
        };
    };
};
