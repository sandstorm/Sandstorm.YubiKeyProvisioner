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
brew install sandstorm/tap/sandstorm-yubikey-agent

echo ""
green_echo "Checking SSH configuration..."

config_file="$HOME/.ssh/config"
brewpath=$(brew --prefix)
config_block="Host *
   IdentityAgent $brewpath/var/run/yubikey-agent.sock"

if [[ -f "$config_file" ]] && grep -q "IdentityAgent $brewpath/var/run/yubikey-agent.sock" "$config_file"; then
  echo "Yubikey-Agent is already configured in ~/.ssh/config"
else
  echo "Do you want to use the Yubikey-Agent as your default SSH agent? (yes/no)"
  read -r UseYubikeyAsSSHAgent

  if [[ "$UseYubikeyAsSSHAgent" =~ ^[Yy](es)?$ ]]; then
    mkdir -p ~/.ssh
    echo ""
    echo -e "\n$config_block" >> "$config_file"
    echo "Yubikey-Agent config added to ~/.ssh/config"
  else
    echo ""
    echo "* Add the following lines to your ~/.ssh/config manually:"
    echo
    echo "---------------------------------------------------------"
    echo "$config_block"
    echo "---------------------------------------------------------"
  fi
fi

echo ""
green_echo "STEP 5: starting yubikey service" 
brew services start sandstorm/tap/sandstorm-yubikey-agent
