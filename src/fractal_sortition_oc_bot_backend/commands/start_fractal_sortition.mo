import Array "mo:core/Array";
import Debug "mo:core/Debug";
import Float "mo:core/Float";
import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Sdk "mo:openchat-bot-sdk";

import Types "../types";
import CommunityUtils "../utils/get_community";
import GroupSizeUtils "../utils/get_group_size";
import VolunteerUtils "../utils/shuffle_volunteers";

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

  func create_group_channel(client : Sdk.OpenChat.Client, channel_name : Text, group : [(Principal, Types.VolunteerInfo)]) : async Result.Result<(), Text> {
    // Create private channel
    // For now, we are using private channels as there currently is no way to have public channels
    // where only a subset of the community members are able to send messages.
    // We can use public channels once the Bot SDK exposes the functionality to assign roles to users.
    // In the meantime, we could think of ways to create transparency into the discussions going on
    // in private groups through different means such as exporting a transcript of the conversations.
    let channel_result = await client.createChannel(channel_name, false).execute();

    switch (channel_result) {
      case (#ok(#Success channel)) {
        let user_ids : [Principal] = Array.map<(Principal, Types.VolunteerInfo), Principal>(
          group,
          func((p, _)) { p },
        );

        // Invite members to channel
        // DISCLAIMER: This currently adds users to the channel from which the command has been initiated. This seems to be a bug in OC
        let invitation_result = await client.inviteUsers(user_ids).inChannel(?channel.channel_id).execute();

        switch (invitation_result) {
          case (#ok(#Success)) {
            return #ok(());
          };

          case _ {
            Debug.print(debug_show (invitation_result));

            return #err("Failed to invite users");
          };
        };
      };

      case _ {
        Debug.print(debug_show (channel_result));

        return #err("Failed to create channel");
      };
    };
  };

  func execute(
    client : Sdk.OpenChat.Client,
    context : Sdk.Command.Context,
    communityRegistry : Types.CommunityRegistry,
  ) : async Sdk.Command.Result {
    // Get community
    let ?(_, community) = CommunityUtils.getCommunity(context.scope, communityRegistry) else {
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

    // We shuffle the list of volunteers before creating the groups.
    let shuffled_volunteers = await VolunteerUtils.shuffleVolunteers(Array.fromIter(Map.entries(community.volunteers)));

    // Determine the size and number of groups
    let group_size = GroupSizeUtils.get_group_size(
      Map.size(community.volunteers),
      community.config.optimization_mode,
    );
    let number_of_volunteers = shuffled_volunteers.size();
    let number_of_groups = Float.toInt(Float.floor(Float.fromInt(number_of_volunteers) / Float.fromInt(group_size)));

    // Put the volunteers into groups
    var groups : [[(Principal, Types.VolunteerInfo)]] = [];
    var i : Nat = 0;

    // Loop through all groups except the last one because the last one might have to accomodate for additional members that couldn't build their own group.
    while (i < (number_of_groups - 1)) {
      let from = i * group_size;
      let to = (i + 1) * group_size;
      let group = Array.sliceToArray(
        shuffled_volunteers,
        from,
        to,
      );

      groups := Array.concat(groups, [group]);

      i += 1;
    };

    // Add the last group with additional members not being able to form their own group
    let last_group = Array.sliceToArray(
      shuffled_volunteers,
      group_size * (number_of_groups - 1),
      Nat.toInt(number_of_volunteers), // The "to" is exclusive. When it's out of bounds, it will simply be clipped
    );

    groups := Array.concat(groups, [last_group]);

    // Create the group channels
    for ((i, group) in Array.enumerate(groups)) {
      let channel_name = "Round 1 - Group " # Nat.toText(i + 1);
      let channel_creation = await create_group_channel(client, channel_name, group);

      switch (channel_creation) {
        case (#ok()) {};

        case (#err(error_message)) {
          let message = await client.sendTextMessage(error_message).executeThenReturnMessage(null);

          return #ok { message };
        };
      };
    };

    let message = await client.sendTextMessage("Created group channels.").executeThenReturnMessage(null);

    return #ok { message };
  };

  func definition() : Sdk.Definition.Command {
    {
      name = "start_fractal_sortition";
      description = ?"Creates group channels based on the list of volunteers";
      placeholder = ?"Creating group channels...";
      params = [];
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
