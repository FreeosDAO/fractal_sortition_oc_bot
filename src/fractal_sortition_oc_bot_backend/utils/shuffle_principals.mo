import Array "mo:core/Array";
import Principal "mo:core/Principal";
import Random "mo:core/Random";

module {
    public func shufflePrincipals(array : [Principal]) : async [Principal] {
        let random = Random.crypto();
        // In order to shuffle elements, we have to create a mutable array
        var result = Array.toVarArray<Principal>(array);
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
