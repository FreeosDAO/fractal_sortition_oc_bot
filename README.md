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

# Testing the bot

**Prerequisites**: DFX 0.29.1

In order to test the bot, you need a locally running instance of OpenChat running.

Please refer to the [OpenChat README.md](https://github.com/open-chat-labs/open-chat#testing-locally) for setting up a local instance.

Once you have OpenChat running, you can deploy the bot by running the deployment script:

```zsh
./deploy.sh
```

If the deploy has been successful, the script will print out the **principal** and the **endpoint**. You will need these values when registering the bot in a group chat.

To register the bot, type `/register_bot` in the message field within a group chat and hit ENTER. This will open a modal for you to enter the bot's details.

After registering the bot, you will still have to "invite" it to the channel by clicking the "Members" icon and navigating to "Bots". The Fractal Sortition bot will be visible under "Available" and ready to be added.

Once the bot is added to the channel, you can use its commands.

For more detailed instructions on how to add the bot, please refer to the [Bot SDK's "Get Started" guide](https://github.com/open-chat-labs/open-chat-bots/blob/main/GETSTARTED.md).

## Updating the bot

If you add new commands to the bot, there currently isn't a way to seemlessly upgrade the bot commands from a running OpenChat instance.

In order to test new commands, you have to:

- Delete the `.dfx/` at the root
- Restart your DFX with `dfx start --clean`
- Re-install OpenChat
- Re-deploy the bot
- Create a group chat and register the bot

It is also recommended to clear the browser cache.
