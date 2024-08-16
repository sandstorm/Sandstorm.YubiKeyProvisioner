# Sandstorm.YubiKeyProvisioner

This is a collection of scripts that we use to provision new YubiKeys according
to our security guidelines -> [Sicherheitskonzept German only](https://sandstorm.de/de/datenschutz-und-datensicherheit/sicherheitskonzept.html)

## How to use

1. Clone this repository to your local machine
2. Check prerequisites: homebrew installed on your machine
3. run `./installOrUpdateDependencies.sh` locally in the cloned folder
4. OPTIONAL run `./resetAndProvisionYubiKey.sh` to RESET and setup your YubiKey

## Why we use these scripts

A goal was to automate the recurring task of setting up a new YubiKey and avoiding pitfalls
through manually running commands.

* not using a correct PIN and PUK (invalid characters, invalid length)
* more interactive explanations on what to enter and what to expect
* improved public ssh-key generation
* no recurring prompts for management key, PIN or PUK
* easy install and upgrade of dependencies

For new setups we use [a custom fork of FiloSottile/yubikey-agent](https://github.com/sandstorm/yubikey-agent).
This is a great project which makes using the YubiKey with SSH really fun. It just works ;)

**For us this is also a documentation that is executable :)**

## Installing Dependencies

Can be run to install or upgrade needed dependencies. Does not do anything to the YubiKey.  

(in the project directory) run `./installOrUpdateDependencies.sh`

## Resetting and Provisioning a new YubiKey

**IMPORTANT: This will reset your YubiKey to factory defaults.**

(in your local project directory) run `./resetAndProvisionYubiKey.sh`

## Getting your existing YubiKey working on a new System

(in your local project directory) run `./installOrUpdateDependencies.sh`

Read the script output and follow the steps to complete the YubiKey setup. You may need to set up your ssh config again. In `~/.ssh/config`

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

## Extracting the Public Key

Sometimes it might be useful to extract the public when you are on a new machine, after disaster recovery or if you
simply misplaced it.
In that case you can run `./extractPublicKey.sh`. Which extracts and saves the public key to your `~/.ssh` directory.
The file will be named <yourUserName>.yubikey.pub. If such a file already exists, you will be asked if you want to
replace it.


## Interactive Tools

You do not need to mess with the `$SSH_AUTH_SOCK` variable, because the `IdentityAgent` setting from above
works at least in the following tools:

- Command Line
- IntelliJ
- Fork
- SourceTree
- Visual Studio Code

## UPDATE 11/2021: No fiddling with SSH_AUTH_SOCK anymore

We again use a forked version of yubikey-agent, because we need to be able to hotfix things if things go wrong.

1. To migrate to the hotfixed version, do:

    ```
    brew services stop yubikey-agent
    brew uninstall yubikey-agent
    brew install sandstorm/tap/sandstorm-yubikey-agent
    brew services start sandstorm/tap/sandstorm-yubikey-agent
    ```

2. Please ensure that the `~/.ssh/config` file exists (you may need to create it) and contains the following contents:

    **for Intel Macs**

    ```
    Host *
        IdentityAgent /usr/local/var/run/yubikey-agent.sock
    ```

    **for M1 Macs**

    ```
    Host *
        IdentityAgent /opt/homebrew/var/run/yubikey-agent.sock
    ```

3. Additionally, also check that **the SSH_AUTH_SOCK is not manipulated** in ~/.zshrc:

    ```bash
    # the following line should NOT OUTPUT ANYTHING
    cat ~/.zshrc | grep SSH_AUTH_SOCK
    ```

    In case the above output shows anything, edit the file and remove that
    section completely.


The above steps has been tested on Mac OS 12.0 on an M1 Mac with:

- Command Line
- IntelliJ
- Fork
- SourceTree
- Visual Studio Code

## Troubleshooting

**Problem**

* Running `./resetAndProvisionYubiKey.sh` fails with a trace ending with something like `Unable to connect with protocol: T0 or T1. Sharing violation.`

**Solution**

* Unplug and plug in your YubiKey again and retry running the script. Something has blocked the Key to be accessed by the YubiKey manager.
