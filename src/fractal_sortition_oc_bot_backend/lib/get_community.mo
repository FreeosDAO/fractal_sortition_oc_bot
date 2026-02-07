import Map "mo:core/Map";
import Principal "mo:core/Principal";
import CommandScope "mo:openchat-bot-sdk/api/common/commandScope";

import Types "../types";

module {
  // This is a utility function used across multiple commands that require to know the community context.
  // If we don't have a community yet in our registry for the community the command is executed from, we create one here.
  public func getCommunity(
    scope : CommandScope.BotCommandScope,
    community_registry : Types.CommunityRegistry,
  ) : ?(Principal, Types.Community) {
    let #Community(community_id) = CommandScope.toLocation(scope) else {
      return null;
    };

    // Get existing community, or create a new one if it doesn’t exist
    let community = switch (Map.get(community_registry, Principal.compare, community_id)) {
      case (?c) c;
      case (null) {
        // Create a new community
        let new_community : Types.Community = {
          id = community_id;
          volunteers = Map.empty<Principal, Types.Volunteer>();
          cohorts = Map.empty<Nat, Types.Cohort>();
        };

        Map.add(community_registry, Principal.compare, community_id, new_community);

        new_community;
      };
    };

    ?(community_id, community);
  };
};
