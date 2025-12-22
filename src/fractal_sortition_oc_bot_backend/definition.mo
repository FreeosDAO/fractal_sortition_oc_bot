import Sdk "mo:openchat-bot-sdk";

module {
  public func handler(commands : [Sdk.Definition.Command]) : Sdk.Http.QueryHandler {
    let definition : Sdk.Definition.Bot = {
      description = "A bot to create and manage a fractal sortition setup.";
      commands = commands;
      autonomous_config = ?{
        permissions = ?{
          community = [#CreatePrivateChannel];
          chat = [#InviteUsers];
          message = [#Text];
        }
      };
      default_subscriptions = null;
      restricted_locations = ?[#Community];
    };

    let response = Sdk.Http.ResponseBuilder().withAllowHeaders().withJson(Sdk.Definition.serialize(definition)).build();

    func(_ : Sdk.Http.Request) : Sdk.Http.Response {
      response;
    };
  };
};
