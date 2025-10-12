import Principal "mo:core/Principal";
import Map "mo:core/Map";
import Time "mo:core/Time";

import Sdk "mo:openchat-bot-sdk";
import CommandScope "mo:openchat-bot-sdk/api/common/commandScope";

import Types "types";

// The "volunteer" function registers the person calling it as a volunteer
module {
  public func build(volunteerRegistry : Types.VolunteerRegistry) : Sdk.Command.Handler {
    {
      definition = definition();
      execute = func(c : Sdk.OpenChat.Client, ctx : Sdk.Command.Context) : async Sdk.Command.Result {
        await execute(c, ctx, volunteerRegistry);
      };
    };
  };

  func execute(
    client : Sdk.OpenChat.Client,
    context : Sdk.Command.Context,
    volunteerRegistry : Types.VolunteerRegistry,
  ) : async Sdk.Command.Result {
    // Get the userId of the person volunteering
    let userId = context.command.initiator;
    // Get the location of the bot
    let location = CommandScope.toLocation(context.scope);

    switch (location) {
      // Currently, we only allow volunteering from within communities.
      case (#Community(communityId)) {
        // Retrieve or create the inner map for this community
        switch (Map.get(volunteerRegistry, Principal.compare, communityId)) {
          // There is no list of volunteers for this community yet, so we create one.
          case (null) {
            Map.add(
              volunteerRegistry,
              Principal.compare,
              communityId,
              Map.singleton<Principal, Types.VolunteerInfo>(userId, { registered_at = Time.now() }),
            );
          };

          // We have an existing list of volunteers
          case (?volunteers) {
            // Check whether the user is already included in the community's list of volunteers
            switch (Map.get(volunteers, Principal.compare, userId)) {
              // The user isn't registered yet as a volunteer
              case (null) {
                Map.add(volunteers, Principal.compare, userId, { registered_at = Time.now() });
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
        };

        // Construct the message that is returned when the registration was successful
        let text = "New volunteer in community: @UserId(" # Principal.toText(userId) # ")";
        let message = await client.sendTextMessage(text).executeThenReturnMessage(null);

        return #ok { message = message };
      };

      case (_) {
        // Bot not installed in a community
        let text = "Volunteers can only be added from inside of a community.";
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
