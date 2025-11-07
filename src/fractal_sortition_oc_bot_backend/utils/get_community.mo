import Principal "mo:core/Principal";
import Map "mo:core/Map";

import CommandScope "mo:openchat-bot-sdk/api/common/commandScope";

import Types "../types";

module {
  // This is a utility function used across multiple commands that require to know the community context.
  // If we don't have a community yet in our registry for the community the command is executed from, we create one here.
  public func getCommunity(
    scope : CommandScope.BotCommandScope,
    communityRegistry : Types.CommunityRegistry,
  ) : ?(Principal, Types.Community) {
    let #Community(communityId) = CommandScope.toLocation(scope) else {
      return null;
    };

    // Get existing community, or create a new one if it doesn’t exist
    let community = switch (Map.get(communityRegistry, Principal.compare, communityId)) {
      case (?c) c;
      case (null) {
        // Create a new community
        let newCommunity : Types.Community = {
          config = {
            min_num_volunteers = 21; // This is the default number of volunteers we require to start rounds.
            optimization_mode = #meritocracy; // By default, we want to encourage more discussions.
          };
          volunteers = Map.empty<Principal, Types.VolunteerInfo>();
        };

        Map.add(communityRegistry, Principal.compare, communityId, newCommunity);

        newCommunity;
      };
    };

    ?(communityId, community);
  };
};
