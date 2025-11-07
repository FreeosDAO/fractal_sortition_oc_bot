import Time "mo:core/Time";
import Map "mo:core/Map";

module {
  public type VolunteerInfo = {
    registered_at : Time.Time;
  };

  public type OptimizationMode = {
    #meritocracy;
    #speed;
  };

  public func optimizationModeToText(mode : OptimizationMode) : Text {
    switch (mode) {
      case (#meritocracy) "Meritocracy";
      case (#speed) "Speed";
    };
  };

  public type Community = {
    config : {
      min_num_volunteers : Int;
      optimization_mode : OptimizationMode;
    };
    volunteers : Map.Map<Principal, VolunteerInfo>;
  };

  public type CommunityRegistry = Map.Map<Principal, Community>;
};
