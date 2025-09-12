import Principal "mo:base/Principal";
import Sdk "mo:openchat-bot-sdk";

// The "volunteer" function registers the person calling it as a volunteer
module {
  public func build(addVolunteer : shared (user : Principal) -> ()) : Sdk.Command.Handler {
    {
      definition = definition();
      execute = func(c : Sdk.OpenChat.Client, ctx : Sdk.Command.Context) : async Sdk.Command.Result {
        await execute(c, ctx, addVolunteer);
      };
    };
  };

  func execute(
    client : Sdk.OpenChat.Client,
    context : Sdk.Command.Context,
    addVolunteer : shared (user : Principal) -> (),
  ) : async Sdk.Command.Result {
    // Get the userId of the person volunteering
    let userId = context.command.initiator;

    // Add the user to the list of volunteers
    addVolunteer(userId);

    // TODO: Check if the user already volunteered.

    // Construct the message that is returned when the registration was successful
    let text = "New volunteer: @UserId(" # Principal.toText(userId) # ")";
    let message = await client.sendTextMessage(text).executeThenReturnMessage(null);

    return #ok { message = message };
  };

  func definition() : Sdk.Definition.Command {
    {
      name = "volunteer";
      description = ?"Registers you as a volunteer";
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
