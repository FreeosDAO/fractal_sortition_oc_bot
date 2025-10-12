import Principal "mo:core/Principal";
import Nat "mo:core/Nat";
import Map "mo:core/Map";

import Sdk "mo:openchat-bot-sdk";
import CommandScope "mo:openchat-bot-sdk/api/common/commandScope";

import Types "types";

// The "list_volunteers" function returns all users that have volunteered in a community
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
    // Get the communityCanister.
    // We enforce volunteering from inside communities, so we can rely on the installation location being a community.
    switch (CommandScope.toLocation(context.scope)) {
      case (#Community(communityId)) {
        switch (Map.get(volunteerRegistry, Principal.compare, communityId)) {
          case (null) {
            let message = await client.sendTextMessage("There are no registered volunteers.").executeThenReturnMessage(null);

            return #ok { message = message };
          };

          case (?volunteers) {
            // Get the number of volunteers
            let count = Map.size(volunteers);
            var text = "Registered volunteers (" # Nat.toText(count) # " total)";

            if (count > 0) {
              text #= ":";
            };

            for ((principal, info) in Map.entries(volunteers)) {
              // Append to text
              // At the moment, there is no great support for formatting the message with line breaks.
              // Also, transforming the principal to a user name is possible but will result in a ping for the user.
              text #= " " # Principal.toText(principal);
            };

            let message = await client.sendTextMessage(text).executeThenReturnMessage(null);

            return #ok { message = message };
          };
        };
      };

      case (_) {
        let message = await client.sendTextMessage("The bot is not installed in a community").executeThenReturnMessage(null);

        return #ok { message = message };
      };
    };
  };

  func definition() : Sdk.Definition.Command {
    {
      name = "list_volunteers";
      description = ?"Lists all volunteers";
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
