import Principal "mo:base/Principal";
import Sdk "mo:openchat-bot-sdk";

module {
    public func build() : Sdk.Command.Handler {
        {
            definition = definition();
            execute = execute;
        };
    };

    func execute(client : Sdk.OpenChat.Client, context : Sdk.Command.Context) : async Sdk.Command.Result {
        let userId = context.command.initiator;

        // TODO: Save user as volunteer

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
}