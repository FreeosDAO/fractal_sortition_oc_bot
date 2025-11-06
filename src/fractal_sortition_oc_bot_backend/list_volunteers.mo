import Principal "mo:core/Principal";
import Nat "mo:core/Nat";
import Map "mo:core/Map";

import Sdk "mo:openchat-bot-sdk";
import CommandScope "mo:openchat-bot-sdk/api/common/commandScope";

import Types "types";

// The "list_volunteers" function returns all users that have volunteered in a community
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
    // Get the community ID.
    // We enforce volunteering from inside communities
    // For that, we can rely on the constraint that the installation location must be a community.
    let #Community(communityId) = CommandScope.toLocation(context.scope) else {
      let message = await client.sendTextMessage(
        "The bot is not installed in a community."
      ).executeThenReturnMessage(null);

      return #ok { message };
    };

    // Get the community data
    let ?community = Map.get(communityRegistry, Principal.compare, communityId) else {
      let message = await client.sendTextMessage(
        "There are no registered volunteers." // We only have a community registered when the first person volunteers
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
