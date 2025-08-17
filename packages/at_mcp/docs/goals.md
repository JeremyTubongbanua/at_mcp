# goals

This document outlines the goal of at_mcp

## Main Goal

The core goal of at_mcp is to offer LLMs an easy way for Coding developers to debug their code using atPlatform tools

## MCP Tools

### VirtualEnv tool

- Run the virtual environment using docker-compose

- pkamLoad

- Compose DDown

- check_docker_readiness, which sends an atSign like "gary" to vip.ve.atsign.zone:64 and sees if it gets a "vip.ve.atsign.zone:*" response.

## MCP Resources

### DEMO DATA

- <https://github.com/atsign-foundation/at_demos> for demo data, PKAM keys, CRAM keys, and more. Look into packages/at_demo_data. For example, to get the PKAM keys, you can go to packages/at_demo_data/lib/assets/atkeys/@gary_key.atKeys. For example, you can get a CRAM key from `https://github.com/atsign-foundation/at_demos/blob/trunk/packages/at_demo_data/lib/src/at_demo_keys.dart`, go to line 862-866 and find:

```
/// All keys class for `@gary` // same as kevin
class GaryKeys {
  /// CRAM key for `@gary`
  static const String _cramKey =
      'e0d06915c3f81561fb5f8929caae64a7231db34fdeaff939aacac3cb736be8328c2843b518a2fc7a58fcec8c0aa98c735c0ce5f8ce880e97cd61cf1f2751efc5';
```

And get the _cramKey string which will be Gary's cram key, which can be used to onboard Gary's atSign in the virtual environment.

### Virtualenv

Link: <https://github.com/atsign-foundation/at_server/blob/trunk/tools/virtualenv/docker-compose.yaml>

```yaml
# Virtual env docker compose file

# Use this with docker compose to quickly spin up a virtual environment

version: '3.7'

services:
  virtualenv:
    container_name: atsign_virtualenv
    image: atsigncompany/virtualenv:vip
    ports:
      - '127.0.0.1:6379:6379'
      - '64:64'
      - '127.0.0.1:9001:9001'
      - '25000-25039:25000-25039'
    extra_hosts:
      - 'vip.ve.atsign.zone:127.0.0.1'
# Remove these comments to run a DNS Masq service locally
# This enables you to code and test offline and use physical devices
# connecting to your Virtual Environment, not needed if you have
# a network connection
#   masqdns:
#     image: atsigncompany/masqdns:vip
#     ports:
#       - "127.0.0.1:5380:8080"
#       - "53:53/udp"
```

**Description**

A virtualenv is a Docker container that runs multiple services

- a Root Server (similar to DNS, you send it an atSign like "alice" and it will give back a host & port of where you can access that atServer like "vip.ve.atsign.zone:25000")
- 40 atServers, each with their own atSign. You can think of an atServer as a key-value database.
- There's a supervisord process called "pkamLoad" which will be useful, and should be an MCP tool. You can execute the supervisord thing via similar command like `docker exec atsign_virtualenv supervisorctl start pkamLoad`

**Notes**:

- It's good if you add vip.ve.atsign.zone 127.0.0.1 to your `/etc/hosts/` before running this Dockerfile.
- WHen you first start up a virtual environment, each atSign is not onboarded yet. To onboard them, you use the CRAM Keys resource to get the cram key of a specific atSIgn, then onboard it with that CRAM key. ONce onboarded, a set of atKeys (a file) is created and this atSign is "activated" and initial onboarding is completed. Any subsequent authentication is done through PKAM (AtOnboardingService).

## Use Case Example

Let me illustrate an example of how a Dart developer who wishes to create an atPlatform application can leverage at_mcp.

Let's say they're creating an application called "at_talk". at_talk has two actors: @xavier and @gary. They can talk to each other using atPlatform's notify/monitor features, which is similar to pub/sub. These two atSigns are atSigns within the virtual environment.

at_talk will 1. start a REPL that reads stdin for messages, and if a message is received from stdin from teh user, it will send a notification to teh `-t`atSign. at_talk wil also start a monitor session that listens for messages from @gary then output them to the user into stdout. When at_talk specifies the `-a` flag, it will authenticate with that atSign.

Once the LLM is done coding the etnire application, the LLM does something like this:

- bash 1: run the virtual environment using docker-compose. USe tools like `check_docker_readiness` to check that the virtual environment is all good. Also will use `pkamLoad` which makes the virtualenvironemnt atSigns PKAM Authenticatable. Once it ran pkam load, it has to get @xavier and @gary's keys from the at_demos repo where it will look into the at_demo_data package and get XavierKeys and GaryKeys files and save them locally. These keys are required for the processes to authenticate with their associated atServers.

- bash 2: dart run bin/at_talk.dart -a @xavier -t @gary --root-server vip.ve.atsign.zone:64 --keys @xavier_key.atKeys
- bash 3: dart run bin/at_talk.dart -a @gary -t @xavier --root-server vip.ve.atsign.zone:64 --keys @gary_key.atKeys

It will pipe messages into bash 2 and bash 3 and see test if the application works.
