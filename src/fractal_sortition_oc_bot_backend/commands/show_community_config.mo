import Sdk "mo:openchat-bot-sdk";
import Int "mo:core/Int";

import Types "../types";
import Utils "../utils/get_community";

// The "show_community_config" function shows the current parameter settings for a community
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
    // Construct message
    // This will have to be adjusted when we add more parameters
    var text = "Required number of volunteers: " # Int.toText(community.config.min_num_volunteers);
    let message = await client.sendTextMessage(text).executeThenReturnMessage(null);

    return #ok { message };
  };

  func definition() : Sdk.Definition.Command {
    {
      name = "show_community_config";
      description = ?"Shows the current configuration of the community";
      placeholder = ?"Retrieving configuration...";
      params = [];
      permissions = {
        community = [];
        chat = [];
        message = [#Text];
      };
      default_role = ?#Admin;
      direct_messages = null;
    };
  };
};
