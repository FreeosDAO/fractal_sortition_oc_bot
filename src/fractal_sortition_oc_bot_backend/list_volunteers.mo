import Sdk "mo:openchat-bot-sdk";
import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";

import Types "types";

// The "list_volunteers" function returns all users that have volunteered
module {
  public func build(getVolunteers : () -> HashMap.HashMap<Principal, Types.VolunteerInfo>) : Sdk.Command.Handler {
    {
      definition = definition();
      execute = func(c : Sdk.OpenChat.Client, ctx : Sdk.Command.Context) : async Sdk.Command.Result {
        await execute(c, ctx, getVolunteers());
      };
    };
  };

  func execute(
    client : Sdk.OpenChat.Client,
    _context : Sdk.Command.Context,
    volunteers : HashMap.HashMap<Principal, Types.VolunteerInfo>,
  ) : async Sdk.Command.Result {
    // Get the number of volunteers
    let count = volunteers.size();
    var text = "Registered volunteers (" # Nat.toText(count) # " total)";

    if (count > 0) {
      text #= ":";
    };

    for ((principal, info) in volunteers.entries()) {
      // Append to text
      // At the moment, there is no great support for formatting the message with line breaks.
      // Also, transforming the principal to a user name is possible but will result in a ping for the user.
      text #= " " # Principal.toText(principal);
    };

    let message = await client.sendTextMessage(text).executeThenReturnMessage(null);

    return #ok { message = message };
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
