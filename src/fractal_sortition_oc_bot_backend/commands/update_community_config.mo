import Principal "mo:core/Principal";
import Map "mo:core/Map";
import Debug "mo:core/Debug";

import Sdk "mo:openchat-bot-sdk";

import Types "../types";
import Utils "../utils/get_community";
import ShowCommunityConfig "./show_community_config";

// The "update_community_config" function sets the parameters of a community
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
        "The config can only be updated from inside of a community."
      ).executeThenReturnMessage(null);

      return #ok { message };
    };
    // Get the passed arg value
    let updated_min_num_volunteers = Sdk.Command.Arg.int(context.command, "min_number");
    let updated_optimization_mode_text = Sdk.Command.Arg.text(context.command, "optimization_mode");
    // Convert the Text -> OptimizationMode variant
    let ?updated_optimization_mode : ?Types.OptimizationMode = switch (updated_optimization_mode_text) {
      case ("meritocracy") ?#meritocracy;
      case ("speed") ?#speed;
      case (invalid_value) {
        Debug.print("Invalid optimization_mode value: " # invalid_value);
        null;
      };
    } else {
      let message = await client.sendTextMessage(
        "Invalid optimization mode"
      ).executeThenReturnMessage(null);

      return #ok { message };
    };
    // Create an updated Community record, reusing the existing volunteers map
    let updated_community : Types.Community = {
      config = {
        min_num_volunteers = updated_min_num_volunteers;
        optimization_mode = updated_optimization_mode;
      };
      volunteers = community.volunteers; // We use the existing volunteer map. This is just a reference and not copying the contents.
    };

    Map.add(communityRegistry, Principal.compare, communityId, updated_community);

    let text = "Updated Configuration: " # ShowCommunityConfig.getConfigText(updated_community);
    let message = await client.sendTextMessage(text).executeThenReturnMessage(null);

    return #ok { message = message };
  };

  func definition() : Sdk.Definition.Command {
    {
      name = "update_community_config";
      description = ?"Updates the community config";
      placeholder = ?"Saving configuration...";
      params = [
        {
          name = "min_number";
          description = ?"The number of volunteers";
          placeholder = ?"Set the number";
          required = true;
          param_type = #IntegerParam {
            min_value = 6; // Having less than 6 volunteers does not allow for creating a meaningful constellation of groups.
            max_value = 9999; // We have to provide a max value. Since we don't really have an upper bound for the number of required volunteers we set this very high
            choices = [];
          };
        },
        {
          name = "optimization_mode";
          description = ?"The optimization mode";
          placeholder = ?"Select a mode";
          required = true;
          param_type = #StringParam {
            min_length = 1; // Required parameter; not relevant
            max_length = 1000; // Required parameter; not relevant
            multi_line = false; // Required parameter; not relevant
            choices = [
              {
                name = "Meritocracy";
                value = "meritocracy";
              },
              {
                name = "Speed";
                value = "speed";
              },
            ];
          };
        },
      ];
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
