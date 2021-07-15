#!/usr/bin/env bash
set -e

green_echo() {
  printf "\033[0;32m${1}\033[0m\n"
}

green_echo "STEP 1: installing/upgrading opensc"
# The OpenSSH PKCS11 smartcard integration will not work from High Sierra
# onwards. If you need this functionality, unlink this formula, then install
# the OpenSC cask. (https://formulae.brew.sh/formula/opensc)
brew unlink opensc || true
brew reinstall homebrew/cask/opensc
# Disable SmartCard UI otherwise we will get a pairing notification every time we
# insert a YubiKey
currentUser=`whoami`
sudo su - "$currentUser" -c "/usr/sbin/sc_auth pairing_ui -s disable"

green_echo "STEP 2: installing/updating YubiKey management tools"
rm -f /usr/local/lib/libykcs11.dylib
brew reinstall ykman
brew reinstall yubico-piv-tool && echo "Installed PIV tool" || echo "Failed to install PIV tool"
brew link --overwrite yubico-piv-tool || true

echo ""
green_echo "STEP 3: removing yubikey-agent"
brew services stop yubikey-agent &> /dev/null && echo "Service was stopped" || echo "No service to be stopped"
# we make sure to uninstall the old fork here or an older version
brew uninstall yubikey-agent &> /dev/null && echo "Agent was uninstalled" || echo "Nothing to uninstall"

echo ""
green_echo "STEP 4: installing yubikey-agent"
brew install yubikey-agent

echo ""
green_echo "STEP 5: starting yubikey service" 
brew services start yubikey-agent
