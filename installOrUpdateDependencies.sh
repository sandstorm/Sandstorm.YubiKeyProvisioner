#!/usr/bin/env bash
set -e

green_echo() {
  printf "\033[0;32m${1}\033[0m\n"
}

green_echo "STEP 1: installing/upgrading opensc"
# The OpenSSH PKCS11 smartcard integration will not work from High Sierra
# onwards. If you need this functionality, unlink this formula, then install
# the OpenSC cask. (https://formulae.brew.sh/formula/opensc)
brew brew unlink opensc
brew reinstall homebrew/cask/opensc
# Disable SmartCard UI otherwise we will get a pairing notification every time we
# insert a YubiKey
currentUser=`who | grep "console" | cut -d" " -f1`
sudo su - "$currentUser" -c "/usr/sbin/sc_auth pairing_ui -s disable"

green_echo "STEP 2: installing/updating YubiKey management tools"
brew reinstall ykman
brew reinstall yubico-piv-tool

echo ""
green_echo "STEP 3: removing yubikey-agent"
brew services stop yubikey-agent &> /dev/null && echo "Service was stopped" || echo "No service to be stopped"
brew uninstall yubikey-agent &> /dev/null && echo "Agent was uninstalled" || echo "Nothing to uninstall"
brew untap filippo.io/yubikey-agent &> /dev/null && echo "filippo.io/yubikey-agent was untaped" || echo "Nothing to untap"

echo ""
green_echo "STEP 4: installing yubikey-agent sandstorm fork"
brew install sandstorm/tap/yubikey-agent
brew services start yubikey-agent
