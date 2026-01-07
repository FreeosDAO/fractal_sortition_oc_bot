import Types "../types";

module {
  // This function determines the group size based on the optimization mode and number of volunteers
  public func getGroupSize(number_of_volunteers : Nat, optimization_mode : Types.OptimizationMode) : Nat {
    // We set default group sizes based on the optimization mode
    var group_size = if (optimization_mode == #meritocracy) {
      5;
    } else {
      10;
    };

    // For each optimization mode, we want a minimum number of groups
    var mininum_number_of_groups = if (optimization_mode == #meritocracy) {
      8;
    } else {
      4;
    };

    // We will need at least three people to have a meaningful voting scenario.
    // That we will have at least two groups with 3 people is ensured by the minimum number of volunteers in the community config.
    while (group_size > 3) {
      // If we have more than or as many groups as required, we return the current group size
      if ((number_of_volunteers / group_size) >= mininum_number_of_groups) {
        return group_size;
      };

      // Otherwise, we will make the group size smaller to reach the required number of groups
      group_size -= 1;
    };

    return group_size;
  };
};
