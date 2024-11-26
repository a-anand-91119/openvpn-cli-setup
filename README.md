# Open Vpn CLI Automation Scripts

> ⚠️ Heads Up! The steps below will automate your 2FA setup, essentially defeating the whole purpose of having 2FA in
> the first place. Proceed with caution, and perhaps a bit of self-reflection.


## Demo

[![asciicast](https://asciinema.org/a/arOHmXSnNzvDqnry49CpuFhKT.svg)](https://asciinema.org/a/arOHmXSnNzvDqnry49CpuFhKT)

## Pre-requisites

- `tmux`: [get it here](https://github.com/tmux/tmux/wiki/Installing)

> Because you'll need its magical `send-keys` function to bypass your 2FA. If you don't know what tmux is, you're
> probably
> in the wrong place.

- `openvpn cli`: [for mac users](https://formulae.brew.sh/formula/openvpn)

> Surprised to see this here? Maybe rethink your life choices.

- `bitwarden cli`: [get it here](https://bitwarden.com/help/cli/)

> Or any password manager CLI, really. Because security is paramount, right?

## The Setup

### tmux

Just install it. Seriously. Some familiarity with tmux keybindings and session navigation might help, but why bother?
[Learn more here.](https://www.redhat.com/sysadmin/introduction-tmux-linux)

### BitwardenCLI

Install it and log in. The recommended way is via [API Keys](https://bitwarden.com/help/cli/#using-an-api-key).

**How to get API Key for bitwarden account?**

- Log in to Bitwarden Console.
- Navigate to your account settings.
- Go to `Security`, and then to `Keys` tab.

**Using bitwarden [session key](https://bitwarden.com/help/cli/#using-a-session-key)**

- After logging in, you'll get a session key. Note it down because you'll need it for the script.

**Things to add in bitwarden**

- Save your OpenVPN credentials. Each OpenVPN server needs its entry (`username`, `password`, and `totp` if necessary).
- Save the root user (`sudo`) password of your machine in another entry.
- Retrieve the `item ids` for these entries from Bitwarden console:
    - Log in to the bitwarden console and open the item.
    - The item ID is in the URL: `https://bitwarden.notyouraverage.dev/#/vault?itemId=<THIS_IS_YOUR_ITEM_ID>`

> **In summary, you'll need `BW_SESSION` and `itemIds` from Bitwarden CLI.**

> Some machines may prompt for elevated permissions when creating tunnel interfaces.

> The sample script shows how to connect to two environments: `Stage` and `Production`.

### OpenVpn CLI

Install the CLI and download the profiles from the access server. Whether the profile includes the username or not, you
can tweak the script to make it work. Be default the script assumes you do not have username as part of the profile.

### Steps

1. Clone this repo
2. Save your `.ovpn` files inside the `scripts` folder. Name them properly (e.g., `stage.ovpn`, `prod.ovpn`).
3. Edit `scripts/openvpn_connect.sh` script and:
    - Set the `BW_SESSION` value.
    - Set the `rootFolder` value (absolute path to the scripts folder).
    - Add/edit environments as needed.
    - For each environment, set the `itemId` and `envName` (Bitwarden item IDs for each environment).
        - The `envName` will be used to detect `.ovpn` files and display messages.
    - Optionally, change/add the ASCII arts (sadly, no RGB support).
    - Set the `laptopItem` value (Bitwarden item ID for your machine's root password).
4. Adjust the script for your `.ovpn` file, removing unnecessary vault calls and key sends if needed. If username is
   already part of your profile then you can remove these lines. Make any necessary adjustments.
   ```
   username=$(bw get username "${itemId}") 
   tmux send-keys -t openvpn "${username}"
   tmux send-keys -t openvpn Enter
   ```
5. Set the `rootFolder` value in these files as well:
    - `openvpn_current.sh`
    - `openvpn_debug_logs.sh`

### How it works?

These scripts use tmux sessions. A new tmux session called `openvpn` is created to connect to OpenVPN. The script uses
tmux `send-keys` to send credentials fetched from Bitwarden to the openvpn session.

> The session is created in detached mode. To access it, use `attach-session -t openvpn`. Want to learn more? Go study
> tmux.

#### What does all these scripts do?

- `openvpn_connect.sh`: Takes an environment name as a parameter, creates a new tmux session, and connects to the
  environment. Disconnects any existing VPN connection first.
- `openvpn_disconnect.sh`: Disconnects from the current VPN.
- `openvpn_current.sh`: Displays the currently connected VPN environment/profile (remember the ASCII art?).
- `openvpn_logs.sh`: Fetches logs from the active VPN.
- `openvpn_debug_logs.sh`: Fetches logs from the current or previously disconnected VPN.

### Aliases to your bash script

Instead of navigating to the script folder and running each script, add aliases to your bash profile for easier access.
Here's an example setup:

```
# Connect to vpn environment stage
alias vs='/<REPLACE_WITH_ABSOLUTE_PATH>/openvpn_connect.sh stage'

# Connect to vpn environment prod
alias vp='/<REPLACE_WITH_ABSOLUTE_PATH>/openvpn_connect.sh prod'

# See the logs from the currently active vpn session
alias vl='/<REPLACE_WITH_ABSOLUTE_PATH>/openvpn_logs.sh'

# See the logs from the currently active / disconnected session
alias vdl='/<REPLACE_WITH_ABSOLUTE_PATH>/openvpn_debug_logs.sh'

# Disconnect from the currently connected vpn
alias vd='/<REPLACE_WITH_ABSOLUTE_PATH>/openvpn_disconnect.sh'

# Show me which vpn am i currently connected to
alias vc='/<REPLACE_WITH_ABSOLUTE_PATH>/openvpn_current.sh'
```

_**Enjoy your automated 2FA setup, and remember: with great power comes great irresponsibility!**_

### What's Next??

- Figure out the network interface used by VPN and create a script to see network activities in that interface.
- Figure a way to run openvpn cli without root.
- Sometimes the session terminates on its own. Find and fix this.
