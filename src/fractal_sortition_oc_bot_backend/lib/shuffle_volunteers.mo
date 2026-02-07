import Array "mo:core/Array";
import Random "mo:core/Random";

import Types "../types";

module {
  // This function takes a list of volunteers and shuffles them.
  // We are using the Fisher-Yates shuffle algorithm (https://en.wikipedia.org/wiki/Fisher–Yates_shuffle)
  public func shuffleVolunteers(volunteers : [(Principal, Types.Volunteer)]) : async [(Principal, Types.Volunteer)] {
    let random = Random.crypto();
    // In order to shuffle elements, we have to create a mutable array
    var result = Array.toVarArray<(Principal, Types.Volunteer)>(volunteers);
    var i = result.size();

    while (i > 1) {
      // Shorten the section to randomize by 1
      i -= 1;

      // Get a random element to switch with the last one
      let j = await* random.natRange(0, i + 1);
      // Store the last element for reference
      let tmp = result[i];
      // Switch the last element with the random one
      result[i] := result[j];
      result[j] := tmp;
    };

    return Array.fromVarArray(result);
  };
};
