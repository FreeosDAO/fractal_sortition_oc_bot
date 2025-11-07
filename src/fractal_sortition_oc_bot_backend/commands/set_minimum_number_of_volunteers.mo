import Principal "mo:core/Principal";
import Map "mo:core/Map";
import Int "mo:core/Int";

import Sdk "mo:openchat-bot-sdk";

import Types "../types";
import Utils "../utils/get_community";

// The "set_minimum_number_of_volunteers" function sets the number of volunteers that are required to create rounds
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
    let ?(communityId, community) = Utils.getCommunity(context.scope, communityRegistry) else {
      let message = await client.sendTextMessage(
        "Volunteers can only be added from inside of a community."
      ).executeThenReturnMessage(null);

      return #ok { message };
    };
    // Get the passed arg value
    let updated_min_num = Sdk.Command.Arg.int(context.command, "min_number");
    // Create a new Community record, reusing the existing volunteers map
    let updated_community : Types.Community = {
      config = { min_num_volunteers = updated_min_num };
      volunteers = community.volunteers; // We use the existing volunteer map. This is just a reference and not copying the contents.
    };

    Map.add(communityRegistry, Principal.compare, communityId, updated_community);

    let text = "Set required number of volunteers to " # Int.toText(updated_min_num);
    let message = await client.sendTextMessage(text).executeThenReturnMessage(null);

    return #ok { message = message };
  };

  func definition() : Sdk.Definition.Command {
    {
      name = "set_minimum_number_of_volunteers";
      description = ?"Sets number of volunteers required to start rounds.";
      placeholder = ?"Saving configuration...";
      params = [{
        name = "min_number";
        description = ?"The number of volunteers";
        placeholder = ?"Set the number";
        required = true;
        param_type = #IntegerParam {
          min_value = 6; // Having less than 6 volunteers does not allow for creating a meaningful constellation of groups.
          max_value = 9999; // We have to provide a max value. Since we don't really have an upper bound for the number of required volunteers we set this very high
          choices = [];
        };
      }];
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
