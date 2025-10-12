import Time "mo:core/Time";
import Map "mo:core/Map";

module {
  public type VolunteerInfo = {
    registered_at : Time.Time;
  };

  public type VolunteerRegistry = Map.Map<Principal, Map.Map<Principal, VolunteerInfo>>;
};
