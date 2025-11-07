import Time "mo:core/Time";
import Map "mo:core/Map";

module {
  public type VolunteerInfo = {
    registered_at : Time.Time;
  };

  public type Community = {
    config : {
      min_num_volunteers : Int;
    };
    volunteers : Map.Map<Principal, VolunteerInfo>;
  };

  public type CommunityRegistry = Map.Map<Principal, Community>;
};
