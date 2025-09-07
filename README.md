# Fractal Sortition OpenChat Bot

This repo is the implementation of the standalone bot proposed in [FreeosDAO/fractal_sortition_bot](https://github.com/FreeosDAO/fractal_sortition_bot).

# Overview

The Fractal Sortition Bot is an experimental implementation of the governance system described in "Revolutionising DAO Governance with Fractal Sortition". This innovative system is designed to fairly and efficiently select delegates in decentralized communities, addressing common issues in DAO governance such as token plutocracy, popularity contests, and passive voting by combining:

Random Selection (Sortition) - Ensures equal opportunity for all members
Peer Evaluation - Incorporates merit through small-group deliberation
Iterative Vetting - Multiple rounds of peer selection refine candidates
Accountability - Non-confidence voting mechanisms maintain delegate responsibility

# How it works

## 1. Volunteer Phase

Community members opt-in to participate.

**Commands**:

`/volunteer`: Registers the user as a volunteer.

## 2. To be continued

# Testing the bot

**Prerequisites**: DFX 0.29.0

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
