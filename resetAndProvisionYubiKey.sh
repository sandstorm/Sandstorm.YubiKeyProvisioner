#!/usr/bin/env bash
set -e

default_management_key="010203040506070801020304050607080102030405060708"
default_pin="123456"
default_puk="12345678"

# we generate a random PIN and PUK here to enforce safety
# and have the script run through correctly. The user will be prompted
# to safe PIN and PUK to the vault
pin=$(cat /dev/urandom | env LC_CTYPE=C tr -dc a-zA-Z0-9 | head -c 6; echo)
puk=$(cat /dev/urandom | env LC_CTYPE=C tr -dc a-zA-Z0-9 | head -c 8; echo)

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
ykman fido reset
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
echo "  PUK:${puk}"
echo "  PIN:${pin}"
echo
yellow_echo "  * Store your PUK and PIN in your Personal vault!!!"
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
yellow_echo "  * Copy the generated public key ./generated/$currentUser.yubikey.pub) to ~/.ssh"
yellow_echo "  * Add the following lines to you ~/.ssh/config to make sure the YubiKey SSH Agent is used for the sandstorm domain"
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
yellow_echo "  * For more information check out https://github.com/FiloSottile/yubikey-agent"
echo
green_echo "DONE"

