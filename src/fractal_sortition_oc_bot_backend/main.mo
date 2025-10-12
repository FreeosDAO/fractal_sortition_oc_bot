import Map "mo:core/Map";

import Http "mo:http-types";
import Sdk "mo:openchat-bot-sdk";
import Env "mo:openchat-bot-sdk/env";

import Types "types";
import Definition "definition";
import Volunteer "volunteer";
import ListVolunteers "list_volunteers";

persistent actor class FractalSortitionBot(key : Text) {
  // State
  var volunteerRegistry : Types.VolunteerRegistry = Map.empty();

  // Command registry
  transient let ocPublicKey = Sdk.parsePublicKeyOrTrap(key);
  transient let registry = Sdk.Command.Registry().register(Volunteer.build(volunteerRegistry)).register(ListVolunteers.build(volunteerRegistry));
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
