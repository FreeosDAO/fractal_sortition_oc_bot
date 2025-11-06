import Principal "mo:core/Principal";
import Map "mo:core/Map";
import Time "mo:core/Time";

import Sdk "mo:openchat-bot-sdk";
import CommandScope "mo:openchat-bot-sdk/api/common/commandScope";

import Types "types";

// The "volunteer" function registers the person calling it as a volunteer
module {
  public func build(communityRegistry : Types.CommunityRegistry) : Sdk.Command.Handler {
    {
      definition = definition();
      execute = func(c : Sdk.OpenChat.Client, ctx : Sdk.Command.Context) : async Sdk.Command.Result {
        await execute(c, ctx, communityRegistry);
      };
    };
  };

  func execute(
    client : Sdk.OpenChat.Client,
    context : Sdk.Command.Context,
    communityRegistry : Types.CommunityRegistry,
  ) : async Sdk.Command.Result {
    // Get the userId of the person volunteering
    let userId = context.command.initiator;
    // Ensure command is executed inside a community
    let #Community(communityId) = CommandScope.toLocation(context.scope) else {
      let message = await client.sendTextMessage(
        "Volunteers can only be added from inside of a community."
      ).executeThenReturnMessage(null);

      return #ok { message };
    };
    // Get existing community, or create a new one if it doesn’t exist
    let community = switch (Map.get(communityRegistry, Principal.compare, communityId)) {
      case (?c) c;
      case (null) {
        // Create a new community
        let newCommunity : Types.Community = {
          volunteers = Map.empty<Principal, Types.VolunteerInfo>();
          min_num_volunteers = 21;
        };

        Map.add(communityRegistry, Principal.compare, communityId, newCommunity);

        newCommunity;
      };
    };

    // Check whether the user is already included in the community's list of volunteers
    switch (Map.get(community.volunteers, Principal.compare, userId)) {
      // The user isn't registered yet as a volunteer
      case (null) {
        Map.add(community.volunteers, Principal.compare, userId, { registered_at = Time.now() });

        // Construct the message that is returned when the registration was successful
        let text = "New volunteer in community: @UserId(" # Principal.toText(userId) # ")";
        let message = await client.sendTextMessage(text).executeThenReturnMessage(null);

        return #ok { message = message };
      };

      // The user has already been registered
      case (?_) {
        // Construct the message that is returned when the user already volunteered in the past
        let text = "You've already registered as a volunteer.";
        let message = await client.sendTextMessage(text).executeThenReturnMessage(null);

        return #ok { message = message };
      };
    };
  };

  func definition() : Sdk.Definition.Command {
    {
      name = "volunteer";
      description = ?"Registers you as a volunteer";
      placeholder = null;
      params = [];
      permissions = {
        community = [];
        chat = [];
        message = [#Text];
      };
      default_role = null;
      direct_messages = null;
    };
  };
};
