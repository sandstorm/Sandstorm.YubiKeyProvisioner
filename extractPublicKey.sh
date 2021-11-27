#!/bin/sh
USERNAME=$(whoami)

# stop yubikey agent - necessary to access the yubikey with pkcs
brew services stop sandstorm-yubikey-agent

# extract public key | replace string at the end with identifier > save it in ~/.ssh/
pkcs15-tool --read-ssh-key 01 | sed -e "s/PIV AUTH pubkey/$USERNAME@YubiKey/g" > ~/.ssh/"$USERNAME".yubikey.pub

# start yubikey agent again
brew services start sandstorm-yubikey-agent
