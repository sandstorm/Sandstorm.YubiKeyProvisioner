#!/bin/sh
USERNAME=$(whoami)
FILENAME="$USERNAME".yubikey.pub

# stop yubikey agent - necessary to access the yubikey with pkcs
brew services stop sandstorm-yubikey-agent

# extract public key
pkcs15-tool --read-ssh-key 01 | sed -e "s/PIV AUTH pubkey/$USERNAME@YubiKey/g" > "$FILENAME"
# use mv -i to avoid accidental overrides
mv -i "$FILENAME" ~/.ssh/"$FILENAME"

# clean up, in case the mv command fails
if test -f "$FILENAME"; then
  rm "$FILENAME"
fi

# start yubikey agent again
brew services start sandstorm-yubikey-agent
