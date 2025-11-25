import Map "mo:core/Map";

import Http "mo:http-types";
import Sdk "mo:openchat-bot-sdk";
import Env "mo:openchat-bot-sdk/env";

import Types "types";
import Definition "definition";
import ListVolunteers "commands/list_volunteers";
import ShowCommunityConfig "commands/show_community_config";
import StartFractalSortition "commands/start_fractal_sortition";
import UpdateCommunityConfig "commands/update_community_config";
import Volunteer "commands/volunteer";

persistent actor class FractalSortitionBot(key : Text) {
  // State
  var communityRegistry : Types.CommunityRegistry = Map.empty();

  // Command registry
  transient let ocPublicKey = Sdk.parsePublicKeyOrTrap(key);
  // prettier-ignore
  transient let registry = (
    Sdk.Command.Registry()
      .register(ListVolunteers.build(communityRegistry))
      .register(ShowCommunityConfig.build(communityRegistry))
      .register(StartFractalSortition.build(communityRegistry))
      .register(UpdateCommunityConfig.build(communityRegistry))
      .register(Volunteer.build(communityRegistry))
  );
  transient let router = Sdk.Http.Router().get("/*", Definition.handler(registry.definitions())).post(
    "/execute_command",
    func(request : Sdk.Http.Request) : async Sdk.Http.Response {
      await Sdk.executeCommand(registry, request, ocPublicKey, Env.nowMillis());
    },
  );

  public query func http_request(request : Http.Request) : async Http.Response {
    router.handleQuery(request);
  };

  public func http_request_update(request : Http.UpdateRequest) : async Http.UpdateResponse {
    await router.handleUpdate(request);
  };
};
