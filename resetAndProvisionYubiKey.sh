#!/usr/bin/env bash
set -e
default_management_key="010203040506070801020304050607080102030405060708"
default_pin="123456"
default_puk="12345678"
# we generate a random PIN and PUK here to enforce safety
# and have the script run through correctly. The user will be prompted
# to safe PIN and PUK to the vault
currentUser=`whoami`
# We need to know where brew was installed to use the correct location for
# the yubikey socket. This can be different depending on processor generation and OS version
brewPrefix=$(brew --prefix)
green_echo() {
  printf "\033[0;32m%s\033[0m\n" "${1}"
}
yellow_echo() {
  printf "\033[1;33m%s\033[0m\n" "${1}"
}
red_echo() {
  printf "\033[0;31m%s\033[0m\n" "${1}"
}
grey_echo() {
  printf "\033[0;37m%s\033[0m\n" "${1}"
}
# RESETTTING
green_echo "STEP 1 - Resetting YubiKey"
echo
echo "-> Reset Fido"
ykman fido reset || echo "Failed to reset FIDO (can be ignored)"
echo
echo "-> Reset Oath"
ykman oath reset --force
echo
echo "-> Reset Piv"
ykman piv reset --force
ykman piv access set-retries  3 3 \
  --pin "123456" \
  --management-key $default_management_key \
  --force
echo
echo
green_echo "STEP 2 - Setting YubiKey Mode"
echo "enables all interfaces except OTP"
ykman config mode FIDO+CCID
echo
echo
# MANAGEMENT KEY
green_echo "STEP 3 - Setting A Management Key"
yellow_echo "Please provide the company-wide management key. Ask your Admin"
while true; do
    read -r -s -p "management key: " management_key
    echo
    read -r -s -p "management key (again): " management_key_repeat
    echo
    [ "$management_key" = "$management_key_repeat" ] && break
    echo "Please try again"
done
echo
ykman piv access change-management-key \
  --touch --new-management-key "$management_key" \
  --management-key "$default_management_key" \
  || { red_echo "Make sure that you do NOT run this script for an already provisioned YubiKey!!!"; exit; }
echo
echo
# PUK AND PIN
green_echo "STEP 4 - Generating & Setting A PUK And PIN"
puk_pattern='^[a-zA-Z0-9]{8}$'
pin_pattern='^[a-zA-Z0-9]{6}$'
echo "  Use your personal vault to generate (and save) the PUK and the PIN."
grey_echo "  The PUK must be 8 characters long and must only contain numbers, uppercase letters"
grey_echo "  and lowercase letters."
grey_echo "  The PIN must be 6 characters long and must only contain numbers, uppercase letters"
grey_echo "  and lowercase letters."
while true; do
    echo
    read -r -s -p "    Enter PUK: " puk
    if [[ ! ${puk} =~ ${puk_pattern} ]] ; then
        echo
        yellow_echo "    The PUK must be 8 characters long and only contain the following characters: a-zA-Z0-9"
        echo "    Please try again"
        echo
        continue
    fi
    green_echo "OK"
    read -r -s -p "    Repeat PUK: " puk_repeat
    [[ $puk == "$puk_repeat" ]] && green_echo "OK" && break
    echo
    yellow_echo "    PUKs do not match"
    echo "    Please try again"
done
while true; do
    echo
    read -r -s -p "    Enter PIN: " pin
    if [[ ! ${pin} =~ ${pin_pattern} ]] ; then
        echo
        yellow_echo "    The PIN must be 6 characters long and only contain the following characters: a-zA-Z0-9"
        echo "    Please try again"
        echo
        continue
    fi
    green_echo "OK"
    read -r -s -p "    Repeat PIN: " pin_repeat
    [[ $pin == "$pin_repeat" ]] && green_echo "OK" && break
    echo
    yellow_echo "    PINs do not match"
    echo "    Please try again"
done
echo
yellow_echo "  * Store your PUK and PIN in your personal vault!!!"
yellow_echo "  * Also store the Serial Number of your YubiKey. This is as list of connected devices:"
echo "    * $(ykman list)"
echo
read -r -p "Press enter to continue. PUK and PIN will be provisioned."
ykman piv access change-puk --puk $default_puk --new-puk "$puk" \
  || { red_echo "Make sure that you do NOT run this script for an already provisioned YubiKey!!!"; exit; }
ykman piv access change-pin --pin $default_pin --new-pin "$pin" \
  || { red_echo "Make sure that you do NOT run this script for an already provisioned YubiKey!!!"; exit; }
echo
echo
# SHH KEYS
green_echo "STEP 5 - Generating SSH Keys"
echo "Please enter your personal information."
echo "It will be used as the Subject common name (CN) for the certificate like so 'CN=SSH for {first_name} {last_name}'"
echo
read -r -p "First Name: " first_name
read -r -p "Last Name: " last_name
echo
rm -rf generated &> /dev/null
mkdir -p generated &> /dev/null
pushd ./generated &> /dev/null
echo "-> generate private key on yubikey to be used for SSH"
echo "   this might take a while, keep tapping the yubikey"
ykman piv keys generate --management-key "$management_key" --touch-policy CACHED --pin-policy ONCE 9a public.pem
echo "-> generate self-signed certificate for that key"
echo "   this might take a while, keep tapping the yubikey"
ykman piv certificates generate --management-key "$management_key" --pin "$pin" -d 3650 -s "CN=SSH for $first_name $last_name" 9a public.pem
rm public.pem
echo "-> extract public SSH key from YubiKey"
pkcs15-tool --read-ssh-key 01 | sed -e "s/PIV AUTH pubkey/$currentUser@YubiKey/g" > "$currentUser".yubikey.pub
echo
echo
# DISPLAYING HELP FOR MANUAL STEPS
green_echo "STEP 6 - Manual Steps to finalize"
echo
yellow_echo "  * Register your YubiKey at auth.sandstorm.de"
yellow_echo "  * Copy the generated public key to your ssh directory (for reference): mkdir -p ~/.ssh/ && cp ./generated/$currentUser.yubikey.pub ~/.ssh/"
yellow_echo "  * Add the following lines to your ~/.ssh/config to make sure the YubiKey SSH Agent is used for all SSH connections. If the config-file does not exist, add it using \`mkdir ~/.ssh; touch ~/.ssh/config\`"
echo
echo "---------------------------------------------------------"
echo "Host *"
echo "   IdentityAgent $brewPrefix/var/run/yubikey-agent.sock"
echo "---------------------------------------------------------"
echo
red_echo "  * Always using the YubiKey for SSH connections is strongly advised!!!"
yellow_echo "  * Add your public key where needed, e.g. gitlab"
echo
echo "---------------------------------------------------------"
cat "$(whoami)".yubikey.pub
echo "---------------------------------------------------------"
echo
yellow_echo "  * Clone a repo and check if the YubiKey is working. You should be prompted for your PIN. Make sure to check 'Save to Keychain'"
yellow_echo "  * You do NOT need to override SSH_AUTH_SOCK anymore - the above setup has been tested and works for command line, IntelliJ, Fork, Sourcetree."
yellow_echo "  * ensure that no SSH_AUTH_SOCK line is present in .zshrc -> run \`cat ~/.zshrc | grep SSH_AUTH_SOCK\` which should NOT output anything."
yellow_echo "  * For more information check out https://github.com/FiloSottile/yubikey-agent"
echo
green_echo "DONE"
