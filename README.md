# Fractal Sortition OpenChat Bot

This repo is the implementation of the standalone bot proposed in [FreeosDAO/fractal_sortition_bot](https://github.com/FreeosDAO/fractal_sortition_bot).

# Overview

The Fractal Sortition Bot is an experimental implementation of the governance system described in "Revolutionising DAO Governance with Fractal Sortition". This innovative system is designed to fairly and efficiently select delegates in decentralized communities, addressing common issues in DAO governance such as token plutocracy, popularity contests, and passive voting by combining:

Random Selection (Sortition) - Ensures equal opportunity for all members
Peer Evaluation - Incorporates merit through small-group deliberation
Iterative Vetting - Multiple rounds of peer selection refine candidates
Accountability - Non-confidence voting mechanisms maintain delegate responsibility

# How it works

When the bot is installed in an OC community, the Fractal Sortition
process can be run multiple times.

One entire Fractal Sortition process is what we call a "cohort".

A cohort consists of "rounds". For each round, we have several "groups".
In these groups, we have "participants" that have been polled based
on the list of "volunteers". In each group, participants vote for 
other participants. The winners of each group advance to the next round.

## 1. Volunteer Phase

Community members opt-in to participate.

**Commands**:

`/volunteer`: Registers the user as a volunteer.

`/list_volunteers`: Lists all users who registered as volunteers.

## 2. Discussion and Voting Phase

Once the Fractal Sortition started, the volunteers are grouped and discuss in dedicated channels. 
In each round, they are voting for someone to advance.

**Commands**:

`/create_cohort`: This starts the Fractal Sortition process for a given topic.

`/vote`: Participants vote for others in their group to advance to the next round.

## Cohort Configuration

### Minimum number of volunteers

This parameter specifies how many people in the community need to have registered as
volunteers to create the cohort.

The minimum required value is `9` to be able to form a meaningful constellation of groups.
Here, we have to consider that the selection mode might be set to `single`.
This means we want at least `3` groups with at least `3` participants each to start with
so that everybody has at least `2` options for their vote in all rounds.

### Optimization mode

For cohorts with many members, the optimization mode influences how big the groups of a
round are.

If we want less rounds, `speed` should be selected. This means we have larger groups.

If `meritocracy` is selected, then we have smaller groups but more rounds.

### Selection mode

When all votes are in, we might have situations where multiple members received the same
amount of votes. In order to dertermine who is the winner of a vote, the selection mode
is the determining factor.

When the selection mode is `single`, then one random person is selected out of the ties.

If the selection mode is `panel`, then multiple people are randomly selected out of the ties.

### Advancement limit

When the selection mode is set to `panel`, then the advancement limit determines how many
people are randomly picked out of the ties. 

The advancement limit is an upper bound. For example, should we have `5` ties and the 
advancement limit is set to `3`, then `3` people are randomly selected. Should we have
only `2` ties while the advancement limit is set to `3`, then both people are the winners.

# Testing the bot

OpenChat is still using `dfx`. Therefore, for local deployment we also have to use it since we need to verify the OC token during deployment.

**Prerequisites**: `dfx 0.31.0-beta.1`

In order to test the bot, you need a locally running instance of OpenChat running.

Please refer to the [OpenChat README.md](https://github.com/open-chat-labs/open-chat#testing-locally) for setting up a local instance.

Once you have OpenChat running, you can deploy the bot by running the deployment script:

```zsh
./scripts/deploy-local.sh
```

If the deploy has been successful, the script will print out the **principal** and the **endpoint**. You will need these values when registering the bot in a group chat.

To register the bot, type `/register_bot` in the message field within a group chat and hit ENTER. This will open a modal for you to enter the bot's details.

After registering the bot, you will still have to "invite" it to the channel by clicking the "Members" icon and navigating to "Bots". The Fractal Sortition bot will be visible under "Available" and ready to be added.

Once the bot is added to the channel, you can use its commands.

For more detailed instructions on how to add the bot, please refer to the [Bot SDK's "Get Started" guide](https://github.com/open-chat-labs/open-chat-bots/blob/main/GETSTARTED.md).

# Migrations

When we change our types, we might have to migrate data. 

For that, write explicit migration functions and reference the old types under `src/fractal_sortition_oc_bot_backend/migrations`.

Apply the migration once by adding it to the actor class in `src/fractal_sortition_oc_bot_backend/main.mo` as `(with migration)`.

Once the migration is applied, simply remove the `(with migration)`.