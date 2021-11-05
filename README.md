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

## Getting your existing YubiKey working on a new System

run `./installOrUpdateDependencies.sh`

You may need to set up your ssh config again. In `~/.ssh/config`

**For M1 Macs brew is installed in `/opt/homebrew`**

```yaml
Host *
  IdentityAgent /opt/homebrew/var/run/yubikey-agent.sock 
```

**For Intel Macs brew is installed in `/usr/local`**

```yaml
Host *
  IdentityAgent /usr/local/var/run/yubikey-agent.sock 
```

## The old way (before using` FiloSottile/yubikey-agent)

see OLD_BACKUP.txt for the old guide
