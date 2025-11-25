import Sdk "mo:openchat-bot-sdk";
import Map "mo:core/Map";

import Types "../types";
import Utils "../utils/get_community";

// The "start_fractal_sortition" command creates the initial set of groups based on the list of volunteers
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
        "Fractal sortition can only be started from inside of a community."
      ).executeThenReturnMessage(null);

      return #ok { message };
    };

    // First, we check that the minimum number of volunteers is reached
    if (Map.size(community.volunteers) < community.config.min_num_volunteers) {
      let message = await client.sendTextMessage(
        "There are not enough volunteers to start the fractal sortition"
      ).executeThenReturnMessage(null);

      return #ok { message };
    };

    let message = await client.sendTextMessage("Created groups").executeThenReturnMessage(null);

    return #ok { message };
  };

  func definition() : Sdk.Definition.Command {
    {
      name = "start_fractal_sortition";
      description = ?"Creates groups based on the list of volunteers";
      placeholder = ?"Creating groups...";
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
