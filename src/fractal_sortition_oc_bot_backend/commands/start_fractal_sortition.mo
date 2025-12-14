import Sdk "mo:openchat-bot-sdk";
import Map "mo:core/Map";
import Array "mo:core/Array";
import Iter "mo:core/Iter";
import Principal "mo:core/Principal";
import Nat "mo:core/Nat";

import Types "../types";
import CommunityUtils "../utils/get_community";
import VolunteerUtils "../utils/shuffle_volunteers";
import GroupSizeUtils "../utils/get_group_size";

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
    let group_size = GroupSizeUtils.get_group_size(
      Map.size(community.volunteers),
      community.config.optimization_mode,
    );
    var text = "Created groups of size " # Nat.toText(group_size) # " ";

    for ((principal, _) in Iter.fromArray(shuffled_volunteers)) {
      text #= " " # Principal.toText(principal);
    };

    let message = await client.sendTextMessage(text).executeThenReturnMessage(null);

    return #ok { message };
  };

  func definition() : Sdk.Definition.Command {
    {
      name = "start_fractal_sortition";
      description = ?"Creates groups based on the list of volunteers";
      placeholder = ?"Creating groups...";
      params = [];
      permissions = {
        community = [#CreatePrivateChannel];
        chat = [];
        message = [#Text];
      };
      default_role = ?#Admin;
      direct_messages = null;
    };
  };
};
