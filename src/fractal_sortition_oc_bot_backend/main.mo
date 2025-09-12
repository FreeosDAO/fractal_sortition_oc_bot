import Http "mo:http-types";
import Sdk "mo:openchat-bot-sdk";
import Env "mo:openchat-bot-sdk/env";

import Definition "definition";
import Volunteer "volunteer";
import ListVolunteers "list_volunteers";
import Types "types";

import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Time "mo:base/Time";
import Iter "mo:base/Iter";

persistent actor class FractalSortitionBot(key : Text) {
  // Stable state
  var stableVolunteers : [(Principal, Types.VolunteerInfo)] = [];

  // In-memory state
  transient var volunteers = HashMap.HashMap<Principal, Types.VolunteerInfo>(
    128,
    Principal.equal,
    Principal.hash,
  );

  // Upgrade hooks
  system func preupgrade() {
    stableVolunteers := Iter.toArray(volunteers.entries());
  };

  system func postupgrade() {
    volunteers := HashMap.fromIter(
      stableVolunteers.vals(),
      128,
      Principal.equal,
      Principal.hash,
    );
  };

  // Storage API
  // We are using this getter function to always use the latest reference of the volunteers, for example, after the load from the stable state.
  func getVolunteers() : HashMap.HashMap<Principal, Types.VolunteerInfo> {
    volunteers;
  };

  // If a user hasn't volunteered yet, we add them to the list of volunteers.
  public func addVolunteer(user : Principal) {
    if (volunteers.get(user) == null) {
      volunteers.put(user, { registered_at = Time.now() });
    };
  };

  // Command registry
  transient let ocPublicKey = Sdk.parsePublicKeyOrTrap(key);
  transient let registry = Sdk.Command.Registry().register(Volunteer.build(addVolunteer)).register(ListVolunteers.build(getVolunteers));
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
