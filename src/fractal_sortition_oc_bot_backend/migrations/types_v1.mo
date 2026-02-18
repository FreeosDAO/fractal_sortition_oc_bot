import Principal "mo:base/Principal";
import Map "mo:core/Map";
import Nat32 "mo:core/Nat";
import Text "mo:core/Text";
import Time "mo:core/Time";

// Version of types before adding advancement_limit
module {
    // The bot uses the community registry for storing data
    // of all the communities it is a part of
    public type CommunityRegistry = Map.Map<Principal, Community>;

    // The bot can be installed in OC communities.
    // All members of a community can register as volunteers to participate in cohorts
    public type Community = {
        id : Principal;
        volunteers : Map.Map<Principal, Volunteer>;
        cohorts : Map.Map<Nat, Cohort>;
    };

    // Any member of the community can register as a volunteer.
    public type Volunteer = {
        user_id : Principal;
        registered_at : Time.Time;
    };

    // A cohort is what we call one entire fractal sortition process within a community.
    // They are differenitated by title.
    // A cohort consists of several rounds where members are grouped and vote for each other.
    public type Cohort = {
        id : Nat; // This is a simple counter that is auto-incremented.
        channel_id : Nat32; // Channel IDs in OC are numbers
        title : Text;
        started_at : Time.Time;
        rounds : Map.Map<Nat, Round>;
        var winner_ids : [Principal]; // We want to allow for mechanisms where multiple people can win, e.g., in case of ties
        config : CohortConfig;
    };

    public type CohortConfig = {
        min_num_volunteers : Int;
        optimization_mode : OptimizationMode;
        selection_mode : SelectionMode;
    };

    public type OptimizationMode = {
        #meritocracy;
        #speed;
    };

    public type SelectionMode = {
        #single;
        #panel;
    };

    // A cohort consists of several rounds.
    // The winners of each group will advance to the next round.
    public type Round = {
        iteration : Nat; // This is a simple counter that is auto-incremented
        started_at : Time.Time;
        groups : Map.Map<Nat32, Group>;
    };

    // Each group is taking form as a channel in the OC community.
    // A group has a several participants.
    public type Group = {
        channel_id : Nat32; // Channel IDs in OC are numbers
        title : Text;
        participants : Map.Map<Principal, Participant>;
        var winner_ids : [Principal]; // We want to allow for mechanisms where multiple people can advance, e.g., in case of ties
    };

    // The people in one group are called participants.
    // Within the group, they cast their vote for the other members of their group.
    public type Participant = {
        id : Principal;
        var vote : ?Vote;
    };

    // A vote saves who casted the vote and for whom they voted.
    public type Vote = {
        voter_id : Principal;
        recipient_id : Principal;
        voted_at : Time.Time;
    };
};
