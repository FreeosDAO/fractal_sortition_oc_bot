import Array "mo:core/Array";
import Debug "mo:core/Debug";
import Float "mo:core/Float";
import Iter "mo:core/Iter";
import List "mo:core/List";
import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Nat32 "mo:core/Nat32";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Text "mo:core/Text";
import Time "mo:core/Time";
import Client "mo:openchat-bot-sdk/client";

import Types "../types";
import ShufflePrincipals "../utils/shuffle_principals";
import GetGroupSize "get_group_size";

module {
    public func createRound(
        api_gateway : Principal,
        community_id : Principal,
        cohort_title : Text,
        rounds : Map.Map<Nat, Types.Round>,
        participants : [Principal],
        iteration : Nat,
        optimization_mode : Types.OptimizationMode,
    ) : async () {
        let round : Types.Round = {
            iteration = iteration;
            started_at = Time.now();
            groups = Map.empty<Nat32, Types.Group>();
        };

        // Add the round
        Map.add(
            rounds,
            Nat.compare,
            iteration,
            round,
        );

        // Create the groups for the round
        // Shuffle the participants before creating the groups
        let shuffled_participants = await ShufflePrincipals.shufflePrincipals(participants);
        // Determine the size and number of groups
        let number_of_participants = Array.size(participants);
        let group_size = GetGroupSize.getGroupSize(
            number_of_participants,
            optimization_mode,
        );
        let number_of_groups = Float.toInt(
            Float.floor(
                Float.fromInt(number_of_participants) / Float.fromInt(group_size)
            )
        );

        // Collect the participants for each group
        var grouped_participants = List.empty<Map.Map<Principal, Types.Participant>>();
        var i : Nat = 0;

        // Loop through all groups except the last one because the last one might have to accomodate for additional members that couldn't build their own group.
        while (i < (number_of_groups - 1)) {
            let from = i * group_size;
            let to = (i + 1) * group_size;
            let participant_ids = Array.sliceToArray(
                shuffled_participants,
                from,
                to,
            );
            let group_participants = Map.empty<Principal, Types.Participant>();

            // We create particpants based on the volunteers
            for ((user_id) in Iter.fromArray(participant_ids)) {
                let participant : Types.Participant = {
                    id = user_id;
                    var vote = null;
                };

                Map.add(
                    group_participants,
                    Principal.compare,
                    user_id,
                    participant,
                );
            };

            List.add(grouped_participants, group_participants);

            i += 1;
        };

        // Add the last group's participants with additional members not being able to form their own group
        let last_participants = Array.sliceToArray(
            shuffled_participants,
            group_size * (number_of_groups - 1),
            Nat.toInt(number_of_participants), // The "to" is exclusive. When it's out of bounds, it will simply be clipped
        );
        let last_group_participants = Map.empty<Principal, Types.Participant>();

        for ((user_id) in Iter.fromArray(last_participants)) {
            let participant : Types.Participant = {
                id = user_id;
                var vote = null;
            };

            Map.add(
                last_group_participants,
                Principal.compare,
                user_id,
                participant,
            );
        };

        List.add(grouped_participants, last_group_participants);

        // Create the group channels in the background
        let groups = List.toArray(grouped_participants);

        for (((i, group)) in Iter.enumerate(Iter.fromArray(groups))) {
            ignore async {
                let participants = groups[i];
                let title = Text.join(
                    [
                        "Cohort ",
                        cohort_title,
                        " - Round ",
                        Nat.toText(round.iteration + 1),
                        " - Group ",
                        Nat.toText(i + 1),
                    ].values(),
                    "",
                );

                await createGroup(
                    api_gateway,
                    community_id,
                    round,
                    title,
                    participants,
                );
            };
        };
    };

    func createGroup(
        api_gateway : Principal,
        community_id : Principal,
        round : Types.Round,
        title : Text,
        participants : Map.Map<Principal, Types.Participant>,
    ) : async Result.Result<(), Text> {
        // We are using the bot the bot to create the channel, so they are the owner.
        // When calling the bot, the caller doesn't have the permission to invite users to that channel.
        // Therefore, we are using the autonomous client.
        let client = Client.OpenChatClient({
            apiGateway = api_gateway;
            scope = #Community(community_id);
            jwt = null;
            messageId = null;
            thread = null;
        });

        // Create private channel
        // For now, we are using private channels as there currently is no way to have public channels
        // where only a subset of the community members are able to send messages.
        // We can use public channels once the Bot SDK exposes the functionality to assign roles to users.
        // In the meantime, we could think of ways to create transparency into the discussions going on
        // in private groups through different means such as exporting a transcript of the conversations.
        let channel_result = await client.createChannel(title, false).execute();

        switch (channel_result) {
            case (#ok(#Success channel)) {
                let participant_ids : [Principal] = Iter.toArray(Map.keys(participants));
                // Invite participants to channel
                let invitation_result = await client.inviteUsers(participant_ids).inChannel(?channel.channel_id).execute();

                switch (invitation_result) {
                    case (#ok(#Success)) {
                        // Save the group in the round
                        Map.add(
                            round.groups,
                            Nat32.compare,
                            channel.channel_id,
                            {
                                channel_id = channel.channel_id;
                                title = title;
                                participants = participants;
                                var winner_ids = Array.empty<Principal>();
                            },
                        );

                        return #ok(());
                    };

                    case _ {
                        Debug.print("Failed to invite users " # debug_show (invitation_result));

                        return #err("Failed to invite users");
                    };
                };
            };

            case _ {
                Debug.print("Failed to create channel " # debug_show (channel_result));

                return #err("Failed to create channel");
            };
        };
    };
};
