import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Time "mo:core/Time";
import Sdk "mo:openchat-bot-sdk";

import Types "../types";
import Utils "../utils/get_community";

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
    // Get community
    let ?(_, community) = Utils.getCommunity(context.scope, communityRegistry) else {
      let message = await client.sendTextMessage(
        "Volunteers can only be added from inside of a community."
      ).executeThenReturnMessage(null);

      return #ok { message };
    };
    // Get the userId of the person volunteering
    let userId = context.command.initiator;

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
      placeholder = ?"Registering...";
      params = [];
      permissions = {
        community = [];
        chat = [];
        message = [#Text];
      };
      default_role = ?#Participant;
      direct_messages = null;
    };
  };
};
