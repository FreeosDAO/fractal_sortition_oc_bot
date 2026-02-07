import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Principal "mo:core/Principal";
import Sdk "mo:openchat-bot-sdk";

import GetCommunity "../lib/get_community";
import Types "../types";

// The "list_volunteers" function returns all users that have volunteered in a community
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
        "Volunteers can only be listed from inside of a community."
      ).executeThenReturnMessage(null);

      return #ok { message };
    };
    // Get the volunteers
    let volunteers = community.volunteers;
    let count = Map.size(volunteers);
    // Construct the message
    var text = "Registered volunteers (" # Nat.toText(count) # " total)";

    if (count > 0) text #= ":";

    for ((principal, _) in Map.entries(volunteers)) {
      text #= " " # Principal.toText(principal);
    };

    let message = await client.sendTextMessage(text).executeThenReturnMessage(null);

    return #ok { message };
  };

  func definition() : Sdk.Definition.Command {
    {
      name = "list_volunteers";
      description = ?"Lists all volunteers";
      placeholder = ?"Fetching volunteers...";
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
