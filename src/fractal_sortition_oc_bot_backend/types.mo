import Time "mo:core/Time";
import Map "mo:core/Map";

module {
  public type VolunteerInfo = {
    registered_at : Time.Time;
  };

  public type Community = {
    volunteers : Map.Map<Principal, VolunteerInfo>;
    min_num_volunteers : Nat;
  };

  public type CommunityRegistry = Map.Map<Principal, Community>;
};
