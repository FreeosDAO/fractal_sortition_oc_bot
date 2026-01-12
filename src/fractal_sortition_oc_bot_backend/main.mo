import Map "mo:core/Map";
import Http "mo:http-types";
import Sdk "mo:openchat-bot-sdk";
import Env "mo:openchat-bot-sdk/env";

import CreateCohort "commands/create_cohort";
import ListVolunteers "commands/list_volunteers";
import Volunteer "commands/volunteer";
import Vote "commands/vote";
import Definition "definition";
import Types "types";
persistent actor class FractalSortitionBot(key : Text) {
  // State
  var community_registry : Types.CommunityRegistry = Map.empty();

  // Command registry
  transient let oc_public_key = Sdk.parsePublicKeyOrTrap(key);
  // prettier-ignore
  transient let registry = (
    Sdk.Command.Registry()
      .register(CreateCohort.build(community_registry))
      .register(ListVolunteers.build(community_registry))
      .register(Volunteer.build(community_registry))
      .register(Vote.build(community_registry))
  );
  transient let router = Sdk.Http.Router().get("/*", Definition.handler(registry.definitions())).post(
    "/execute_command",
    func(request : Sdk.Http.Request) : async Sdk.Http.Response {
      await Sdk.executeCommand(registry, request, oc_public_key, Env.nowMillis());
    },
  );

  public query func http_request(request : Http.Request) : async Http.Response {
    router.handleQuery(request);
  };

  public func http_request_update(request : Http.UpdateRequest) : async Http.UpdateResponse {
    await router.handleUpdate(request);
  };
};
