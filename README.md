# Sandstorm.YubiKeyProvisioner

This is a collection of scripts that we are using to provision new YubiKeys according
to our security guidelines (currently only available in German) -> [Sicherheitskonzept](https://sandstorm.de/de/datenschutz-und-datensicherheit/sicherheitskonzept.html)

A goal was to automate the recurring task of setting up a new YubiKey and avoiding pitfalls
through manually running commands.

* not using a correct PIN and PUK (invalid characters, invalid length)
* more interactive explanations on what to enter and what to expect
* improved public ssh-key generation
* no recurring prompts for management key, PIN or PUK
* easy install and upgrade of dependencies

For new setups we use [FiloSottile/yubikey-agent](https://github.com/FiloSottile/yubikey-agent). This is a great project
which makes using the YubiKey with SSH really fun. It just works ;)

**For us this is also a documentation that happens to be executable ;)**

## Installing Dependencies

Can be run separately to upgrade needed dependencies  

run `./installOrUpdateDependencies.sh`

## Resetting and Provisioning a new YubiKey

IMPORTANT: this will reset your YubiKey to factory defaults.

run `./resetAndProvisionYubiKey.sh`

# Removing our old YubiKey agent installation

## Preparations

* check where the YubiKey binary is: `which ykpiv-ssh-agent-helper`
* check if it was installed with brew: `brew services list`
* check which user installed the YubiKey agent: `ls -la $(which ykpiv-ssh-agent-helper)` -> results in a path like `/Library/LaunchAgents/com.duosecurity.ykpiv-ssh-agent-helper.plist`

## Uninstall

* remove the autostart entry: `sudo rm /Library/LaunchAgents/com.duosecurity.ykpiv-ssh-agent-helper.plist`
* remove the binary: `sudo rm /usr/local/bin/ykpiv-ssh-agent-helper`
* make sure no processes are running: `killall ykpiv-ssh-agent-helper`

# Migrating to the new YubiKey agent with a previously set up YubiKey

* install our forked YubiKey agent: `brew install sandstorm/tap/yubikey-agent-sandstorm`
* add the agent to autostart: `brew services start sandstorm/tap/yubikey-agent-sandstorm`

Try an ssh connection to any target to get the prompt to enter the YubiKey PIN

* get the PIN from your Keychain, look for `ykpiv`
* enter the PIN in "Pinentry Mac" and save to Keychain
* add the following to .zshrc:

```shell
# we don't override the $SSH_AUTH_SOCK variable, because this would only set it for the current terminal,
# and not for interactive applications like Sequel Pro/Sequel Ace or IntelliJ which open SSH connections.
# That's why we disable the user's built-in SSH agent and override it with the yubikey agent's socket.
if [ "$SSH_AUTH_SOCK" != "/usr/local/var/run/yubikey-agent.sock" ]; then
    rm $SSH_AUTH_SOCK
    ln -s /usr/local/var/run/yubikey-agent.sock $SSH_AUTH_SOCK
fi
```

## The old way (before using `FiloSottile/yubikey-agent`)

see OLD_BACKUP.txt for the old guide
