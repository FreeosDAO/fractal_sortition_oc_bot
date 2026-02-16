import Principal "mo:core/Principal";
import Sdk "mo:openchat-bot-sdk";

import GetCommunity "../lib/get_community";
import Volunteer "../lib/volunteer";
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

    switch (Volunteer.volunteer(user_id, community.volunteers)) {
      case (#ok(_)) {
        let text = "New volunteer in community: @UserId(" # Principal.toText(user_id) # ")";
        let message = await client.sendTextMessage(text).executeThenReturnMessage(null);

        return #ok { message = message };
      };
      case (#err(error_message)) {
        let message = await client.sendTextMessage(error_message).executeThenReturnMessage(null);

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
