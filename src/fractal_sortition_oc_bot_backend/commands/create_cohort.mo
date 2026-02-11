import Array "mo:core/Array";
import Iter "mo:core/Iter";
import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Principal "mo:core/Principal";
import Time "mo:core/Time";
import CommandScope "mo:openchat-bot-sdk/api/common/commandScope";
import Sdk "mo:openchat-bot-sdk";

import GetCommunity "../lib/get_community";
import Types "../types";
import CreateRound "../lib/create_round";

// The "create_cohort" command creates a cohort and the initial set of groups based on the list of volunteers
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
    let ?(community_id, community) = GetCommunity.getCommunity(context.scope, community_registry) else {
      let message = await client.sendTextMessage(
        "A cohort can only be created from inside of a community."
      ).executeThenReturnMessage(null);

      return #ok { message };
    };

    // Get the channel ID
    let (?{ chat }) = CommandScope.chatDetails(context.scope) else return #err("Could not extract chat details");
    let channel_id = switch (chat) {
      case (#Channel(_, id)) id;
      case (_) return #err("Could not extract channel ID");
    };

    // Get the arg values
    let title = Sdk.Command.Arg.text(context.command, "title");
    let min_num_volunteers = Sdk.Command.Arg.int(context.command, "min_num_volunteers");
    let optimization_mode_arg = Sdk.Command.Arg.text(context.command, "optimization_mode");
    let selection_mode_arg = Sdk.Command.Arg.text(context.command, "selection_mode");

    // Convert the Text -> OptimizationMode variant
    let optimization_mode : Types.OptimizationMode = switch (optimization_mode_arg) {
      case ("meritocracy") #meritocracy;
      case ("speed") #speed;
      case (invalid_value) {
        let message = await client.sendTextMessage(
          "Invalid optimization mode " # invalid_value
        ).executeThenReturnMessage(null);

        return #ok { message };
      };
    };

    // Convert the Text -> SelectionMode variant
    let selection_mode : Types.SelectionMode = switch (selection_mode_arg) {
      case ("single") #single;
      case ("panel") #panel;
      case (invalid_value) {
        let message = await client.sendTextMessage(
          "Invalid selection mode " # invalid_value
        ).executeThenReturnMessage(null);

        return #ok { message };
      };
    };

    // First, we check that the minimum number of volunteers is reached
    if (Map.size(community.volunteers) < min_num_volunteers) {
      let message = await client.sendTextMessage(
        "There are not enough volunteers to create the cohort"
      ).executeThenReturnMessage(null);

      return #ok { message };
    };

    // COHORT CREATION

    // Create the cohort based on the args.
    let cohort : Types.Cohort = {
      id = community.cohorts.size; // This is an incremental ID so we just take the existing number of cohorts. This if fine since we don't delete cohorts.
      title = title;
      channel_id = channel_id;
      started_at = Time.now();
      rounds = Map.empty<Nat, Types.Round>();
      var winner_ids = Array.empty<Principal>();
      config = {
        min_num_volunteers = min_num_volunteers;
        optimization_mode = optimization_mode;
        selection_mode = selection_mode;
      };
    };

    // Save the cohort in the community
    Map.add(
      community.cohorts,
      Nat.compare,
      cohort.id,
      cohort,
    );

    // ROUND CREATION
    let participants : [Principal] = Array.fromIter(
      Iter.map(
        Map.entries(community.volunteers),
        func((user_id, _volunteer)) = user_id,
      )
    );

    await CreateRound.createRound(
      context.apiGateway,
      community_id,
      title,
      cohort.rounds,
      participants,
      0,
      optimization_mode,
    );

    let message = await client.sendTextMessage("Created cohort.").executeThenReturnMessage(null);

    return #ok { message };
  };

  func definition() : Sdk.Definition.Command {
    {
      name = "create_cohort";
      description = ?"Creates a new cohort and the group channels for the first round based on the list of volunteers";
      placeholder = ?"Creating cohort...";
      params = [
        {
          name = "title";
          description = ?"The title of the cohort";
          placeholder = ?"Enter title";
          required = true;
          param_type = #StringParam {
            min_length = 1; // Required parameter; not relevant
            max_length = 1000; // Required parameter; not relevant
            multi_line = false; // Required parameter; not relevant
            choices = []; // Required parameter; not relevant
          };
        },
        {
          name = "min_num_volunteers";
          description = ?"The required number of volunteers";
          placeholder = ?"Set minimum";
          required = true;
          param_type = #IntegerParam {
            min_value = 9; // Having less than 9 volunteers does not allow for creating a meaningful constellation of groups.
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
        {
          name = "selection_mode";
          description = ?"The selection mode";
          placeholder = ?"Select a mode";
          required = true;
          param_type = #StringParam {
            min_length = 1; // Required parameter; not relevant
            max_length = 1000; // Required parameter; not relevant
            multi_line = false; // Required parameter; not relevant
            choices = [
              {
                name = "Single";
                value = "single";
              },
              {
                name = "Panel";
                value = "panel";
              },
            ];
          };
        },
      ];
      permissions = {
        community = [#CreatePrivateChannel];
        chat = [#InviteUsers];
        message = [#Text];
      };
      default_role = ?#Admin;
      direct_messages = null;
    };
  };
};
