import Array "mo:core/Array";
import Debug "mo:core/Debug";
import Float "mo:core/Float";
import Iter "mo:core/Iter";
import List "mo:core/List";
import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Nat32 "mo:core/Nat32";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Text "mo:core/Text";
import Time "mo:core/Time";
import Sdk "mo:openchat-bot-sdk";
import Client "mo:openchat-bot-sdk/client";

import GetCommunity "../lib/get_community";
import GetGroupSize "../lib/get_group_size";
import ShuffleVolunteers "../lib/shuffle_volunteers";
import Types "../types";

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

  func create_group(
    context : Sdk.Command.Context,
    client : Sdk.OpenChat.Client,
    community_id : Principal,
    round : Types.Round,
    title : Text,
    participants : Map.Map<Principal, Types.Participant>,
  ) : async Result.Result<(), Text> {
    // Create private channel
    // For now, we are using private channels as there currently is no way to have public channels
    // where only a subset of the community members are able to send messages.
    // We can use public channels once the Bot SDK exposes the functionality to assign roles to users.
    // In the meantime, we could think of ways to create transparency into the discussions going on
    // in private groups through different means such as exporting a transcript of the conversations.
    let channel_result = await client.createChannel(title, false).execute();

    switch (channel_result) {
      case (#ok(#Success channel)) {
        let participant_ids : [Principal] = Iter.toArray(Map.keys(participants));

        // We are using the bot the bot to create the channel, so they are the owner.
        // When calling the bot, the caller doesn't have the permission to invite users to that channel.
        // Therefore, we are using the autonomous client.
        let autonomous_client = Client.OpenChatClient({
          apiGateway = context.apiGateway;
          scope = #Chat(#Channel(community_id, channel.channel_id));
          jwt = null;
          messageId = null;
          thread = null;
        });

        // Invite participants to channel
        let invitation_result = await autonomous_client.inviteUsers(participant_ids).inChannel(?channel.channel_id).execute();

        switch (invitation_result) {
          case (#ok(#Success)) {
            // Save the group in the round
            Map.add(
              round.groups,
              Nat32.compare,
              channel.channel_id,
              {
                channel_id = channel.channel_id;
                title = title;
                participants = participants;
                var winner_ids = List.empty<Principal>();
              },
            );

            return #ok(());
          };

          case _ {
            Debug.print("Failed to invite users " # debug_show (invitation_result));

            return #err("Failed to invite users");
          };
        };
      };

      case _ {
        Debug.print("Failed to create channel " # debug_show (channel_result));

        return #err("Failed to create channel");
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

    // Get the arg values
    let title = Sdk.Command.Arg.text(context.command, "title");
    let min_num_volunteers = Sdk.Command.Arg.int(context.command, "min_num_volunteers");
    let optimization_mode = Sdk.Command.Arg.text(context.command, "optimization_mode");

    // Convert the Text -> OptimizationMode variant
    let ?parsed_optimization_mode : ?Types.OptimizationMode = switch (optimization_mode) {
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
      started_at = Time.now();
      rounds = Map.empty<Nat, Types.Round>();
      config = {
        min_num_volunteers = min_num_volunteers;
        optimization_mode = parsed_optimization_mode;
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

    // Create the initial round
    let round : Types.Round = {
      iteration = 0; // This is the initial iteration, so we start at 0
      started_at = Time.now();
      groups = Map.empty<Nat32, Types.Group>();
    };

    // Save the round in the cohort
    Map.add(
      cohort.rounds,
      Nat.compare,
      round.iteration,
      round,
    );

    // GROUP CREATION

    // We shuffle the list of volunteers before creating the groups.
    let shuffled_volunteers = await ShuffleVolunteers.shuffleVolunteers(Array.fromIter(Map.entries(community.volunteers)));

    // Determine the size and number of groups
    let group_size = GetGroupSize.getGroupSize(
      Map.size(community.volunteers),
      parsed_optimization_mode,
    );
    let number_of_volunteers = shuffled_volunteers.size();
    let number_of_groups = Float.toInt(Float.floor(Float.fromInt(number_of_volunteers) / Float.fromInt(group_size)));

    // Collect the participants for each group
    var participants : [Map.Map<Principal, Types.Participant>] = [];
    var i : Nat = 0;

    // Loop through all groups except the last one because the last one might have to accomodate for additional members that couldn't build their own group.
    while (i < (number_of_groups - 1)) {
      let from = i * group_size;
      let to = (i + 1) * group_size;
      let group_volunteers = Array.sliceToArray(
        shuffled_volunteers,
        from,
        to,
      );
      let group_participants = Map.empty<Principal, Types.Participant>();

      // We create particpants based on the volunteers
      for ((user_id, _volunteer) in group_volunteers.vals()) {
        let participant : Types.Participant = {
          id = user_id;
          var vote = null;
        };

        Map.add(
          group_participants,
          Principal.compare,
          user_id,
          participant,
        );
      };

      participants := Array.concat(participants, [group_participants]);

      i += 1;
    };

    // Add the last group's participants with additional members not being able to form their own group
    let last_volunteers = Array.sliceToArray(
      shuffled_volunteers,
      group_size * (number_of_groups - 1),
      Nat.toInt(number_of_volunteers), // The "to" is exclusive. When it's out of bounds, it will simply be clipped
    );
    let last_participants = Map.empty<Principal, Types.Participant>();

    for ((user_id, _volunteer) in last_volunteers.vals()) {
      let participant : Types.Participant = {
        id = user_id;
        var vote = null;
      };

      Map.add(
        last_participants,
        Principal.compare,
        user_id,
        participant,
      );
    };

    participants := Array.concat(participants, [last_participants]);

    // Create the group channels
    for ((i, participants) in Array.enumerate(participants)) {
      let title = Text.join(
        "",
        [
          "Cohort ",
          cohort.title,
          " - Round ",
          Nat.toText(round.iteration + 1),
          " - Group ",
          Nat.toText(i + 1),
        ].values(),
      );
      let channel_creation = await create_group(
        context,
        client,
        community_id,
        round,
        title,
        participants,
      );

      switch (channel_creation) {
        case (#ok()) {};

        case (#err(error_message)) {
          let message = await client.sendTextMessage(error_message).executeThenReturnMessage(null);

          return #ok { message };
        };
      };
    };

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
