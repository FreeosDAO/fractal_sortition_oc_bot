import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Time "mo:core/Time";
import Sdk "mo:openchat-bot-sdk";

import GetCommunity "../lib/get_community";
import Types "../types";

// The "volunteer" function registers the person calling it as a volunteer
module {
  public func build(community_registry : Types.CommunityRegistry) : Sdk.Command.Handler {
    {
      definition = definition();
      execute = func(c : Sdk.OpenChat.Client, ctx : Sdk.Command.Context) : async Sdk.Command.Result {
        await execute(c, ctx, community_registry);
      };
    };
  };

  func execute(
    client : Sdk.OpenChat.Client,
    context : Sdk.Command.Context,
    community_registry : Types.CommunityRegistry,
  ) : async Sdk.Command.Result {
    // Get community
    let ?(_community_id, community) = GetCommunity.getCommunity(context.scope, community_registry) else {
      let message = await client.sendTextMessage(
        "Volunteers can only be added from inside of a community."
      ).executeThenReturnMessage(null);

      return #ok { message };
    };
    // Get the user_id of the person volunteering
    let user_id = context.command.initiator;

    // Check whether the user is already included in the community's list of volunteers
    switch (Map.get(community.volunteers, Principal.compare, user_id)) {
      // The user isn't registered yet as a volunteer
      case (null) {
        Map.add(
          community.volunteers,
          Principal.compare,
          user_id,
          {
            user_id = user_id;
            registered_at = Time.now();
          },
        );

        // Construct the message that is returned when the registration was successful
        let text = "New volunteer in community: @UserId(" # Principal.toText(user_id) # ")";
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
