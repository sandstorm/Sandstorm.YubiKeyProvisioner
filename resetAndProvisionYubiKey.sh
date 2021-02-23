#!/usr/bin/env bash
set -e

default_management_key="010203040506070801020304050607080102030405060708"
default_pin="123456"
default_puk="12345678"

# we generate a random PIN and PUK here to enforce safety
# and have the script run through correctly. The user will be prompted
# to safe PIN and PUK to the vault

currentUser=`who | grep "console" | cut -d" " -f1`

green_echo() {
  printf "\033[0;32m${1}\033[0m\n"
}

yellow_echo() {
  printf "\033[1;33m${1}\033[0m\n"
}

red_echo() {
  printf "\033[0;31m${1}\033[0m\n"
}

grey_echo() {
  printf "\033[0;37m${1}\033[0m\n"
}

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
ykman piv set-pin-retries  3 3 \
  --pin "123456" \
  --management-key $default_management_key \
  --force
echo
echo
green_echo "STEP 2 - Setting YubiKey Mode"
echo "enables all interfaces except OTP"
ykman mode FIDO+CCID
echo
echo
green_echo "STEP 3 - Setting A Management Key"
yellow_echo "Please provide the company-wide management key. Ask your Admin"

while true; do
    read -s -p "management key: " management_key
    echo
    read -s -p "management key (again): " management_key_repeat
    echo
    [ "$management_key" = "$management_key_repeat" ] && break
    echo "Please try again"
done
echo
ykman piv change-management-key \
  --touch --new-management-key "$management_key" \
  --management-key "$default_management_key" \
  || { red_echo "Make sure that you do NOT run this script for an already provisioned YubiKey!!!"; exit; }
echo
echo
green_echo "STEP 4 - Generating & Setting A PUK And PIN"
pin_pattern=^[a-zA-Z0-9]{6}$
puk_pattern=^[a-zA-Z0-9]{8}$
echo "  Use your personal vault to generate (and save) a PIN and a PUK."
grey_echo "  The PUK must be 8 characters long and must only contain numbers, uppercase letters"
grey_echo "  and lowercase letters."
grey_echo "  The PIN must be 6 characters long and must only contain numbers, uppercase letters"
grey_echo "  and lowercase letters."
while true; do
    echo
    read -s -p "    Enter PUK: " puk
    [[ $puk =~ $puk_pattern ]] && green_echo "OK" && break
    echo
    yellow_echo "    The PUK must be 8 characters long and only contain the following characters: a-zA-Z0-9"
    echo "    Please try again"
done
while true; do
    echo
    read -s -p "    Enter PIN: " pin
    [[ $pin =~ $pin_pattern ]] && green_echo "OK" && break
    echo
    yellow_echo "    The PIN must be 6 characters long and only contain the following characters: a-zA-Z0-9"
    echo "    Please try again"
done
echo
echo "  PUK: ${puk}"
echo "  PIN: ${pin}"
echo
yellow_echo "  * Store your PUK and PIN in your personal vault!!!"
yellow_echo "  * Also store the Serial Number of your YubiKey. This is as list of connected devices:"
echo "    * $(ykman list)"
echo
read -p "Press enter to continue. PUK and PIN will be provisioned."

ykman piv change-puk --puk $default_puk --new-puk $puk \
  || { red_echo "Make sure that you do NOT run this script for an already provisioned YubiKey!!!"; exit; }
ykman piv change-pin --pin $default_pin --new-pin $pin \
  || { red_echo "Make sure that you do NOT run this script for an already provisioned YubiKey!!!"; exit; }
echo
echo
green_echo "STEP 5 - Generating SSH Keys"
echo "Please enter your personal information."
echo "It will be used as the Subject common name (CN) for the certificate like so 'CN=SSH for {first_name} {last_name}'"
echo
read -p "First Name: " first_name
read -p "Last Name: " last_name
echo
rm -rf generated &> /dev/null
mkdir -p generated &> /dev/null

pushd ./generated &> /dev/null
echo "-> generate private key on yubikey to be used for SSH"
ykman piv generate-key --management-key "$management_key" --touch-policy CACHED --pin-policy ONCE 9a public.pem
echo "-> generate self-signed certificate for that key"
ykman piv generate-certificate --management-key "$management_key" --pin "$pin" -d 3650 -s "/CN=SSH for $first_name $last_name/" 9a public.pem
rm public.pem
echo "-> extract public SSH key from YubiKey"
pkcs15-tool --read-ssh-key 01 | sed -e "s/PIV AUTH pubkey/$currentUser@YubiKey/g" > "$currentUser".yubikey.pub
echo
echo
green_echo "STEP 6 - Manual Steps to finalize"
echo
yellow_echo "  * Register your YubiKey at auth.sandstorm.de"
yellow_echo "  * For Firefox enable U2F support"
yellow_echo "  * Copy the generated public key to your ssh directory: cp ./generated/$currentUser.yubikey.pub ~/.ssh/"
yellow_echo "  * Add the following lines to your ~/.ssh/config to make sure the YubiKey SSH Agent is used for the sandstorm domain"
cat << EOF
---------------------------------------------------------
Host *
    IdentityAgent /usr/local/var/run/yubikey-agent.sock
---------------------------------------------------------
EOF
red_echo "  * Always using the YubiKey for SSH connections is strongly advised!!!"
yellow_echo "  * Add your public key where needed, e.g. gitlab"
echo
echo "---------------------------------------------------------"
cat "$(whoami)".yubikey.pub
echo "---------------------------------------------------------"
echo
yellow_echo "  * Clone a repo and check if the YubiKey is working. You should be prompted for your PIN. Make sure to check 'Save to Keychain'"
yellow_echo "  * Add the following lines to your ~/.zshrc file to ensure the Yubikey works in interactive applications"
cat << EOF
---------------------------------------------------------
# and not for interactive applications like Sequel Pro/Sequel Ace or IntelliJ which open SSH connections.
# That's why we disable the user's built-in SSH agent and override it with the yubikey agent's socket.
if [ "$SSH_AUTH_SOCK" != "/usr/local/var/run/yubikey-agent.sock" ]; then
    rm $SSH_AUTH_SOCK
    ln -s /usr/local/var/run/yubikey-agent.sock $SSH_AUTH_SOCK
fi
---------------------------------------------------------
EOF

yellow_echo "  * For more information check out https://github.com/FiloSottile/yubikey-agent"
echo
green_echo "DONE"

