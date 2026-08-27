#!/bin/sh
USERNAME=$(whoami)
FILENAME="$USERNAME".yubikey.pub

# stop yubikey agent - necessary to access the yubikey with pkcs
brew services stop sandstorm-yubikey-agent

# extract public key
pkcs15-tool --read-ssh-key 01 | sed -E "s/^(ssh-[^ ]+ [^ ]+) .*/\1 $USERNAME@YubiKey/" > "$FILENAME"
# create the .ssh directory if it does not exist
mkdir -p ~/.ssh/
# use mv -i to avoid accidental overrides
mv -i "$FILENAME" ~/.ssh/"$FILENAME"

# clean up, in case the mv command fails
if test -f "$FILENAME"; then
  rm "$FILENAME"
fi

# start yubikey agent again
brew services start sandstorm-yubikey-agent
