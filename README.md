# Sandstorm.YubiKeyProvisioner

This is a collection of scripts that we are using to provision new YubiKeys according
to our security guidelines (currently only available in German) -> [Sicherheitskonzept](https://sandstorm.de/de/datenschutz-und-datensicherheit/sicherheitskonzept.html)

A goal was to automate the recurring task of setting up a new YubiKey and avoiding pitfalls
through manually running commands.

* not using a correct PIN and PUK (invalid characters, invalid length)
* more interactive explanations on what to enter and what to expect
* improved public ssh-key generation
* no recurring prompts for management key, PIN or PUK
* easy install and upgrade of dependencies

For new setups we use [FiloSottile/yubikey-agent](https://github.com/FiloSottile/yubikey-agent). This is a great project
which makes using the YubiKey with SSH really fun. It just works ;) We currently use our own fork to be able to save the
PIN to the keychain and not type it every time we connect the key. We have opened a [pullrequest](https://github.com/FiloSottile/yubikey-agent/pull/46). Once merged we will switch back.

**For us this is also a documentation that happens to be executable ;)**

## Installing Dependencies

Can be run separately to upgrade needed dependencies  

run `./installOrUpdateDependencies.sh`

## Resetting and Provisioning a new YubiKey

IMPORTANT: this will reset your YubiKey to factory defaults.

run `./resetAndProvisionYubiKey.sh`

## The old way (before using` FiloSottile/yubikey-agent)

**1. disable OTP passwords when touching yubikey**

* `brew install ykman`
* insert yubikey into PC
* show available interfaces:
* `ykman mode`

**2. enable all interfaces except OTP, e.g.:**

* `ykman mode FIDO+CCID`

**3. re-insert yubikey; now when touching yubikey, nothing will happen**

* (instead of OTP token being typed)

**4. install ykpiv-ssh-agent-helper (also containing yubico-piv-tool) from https://github.com/sandstorm/ykpiv-ssh-agent-helper/releases**

**5. set management key to the company-wide management key**

* `/opt/yubico-piv-tool/bin/yubico-piv-tool -a set-mgm-key --touch-policy=always`

**6. set PIN and PUK tries to 3. If asked for PIN, it is "123456" by default.**

* while running this command, you have to TOUCH YOUR YUBIKEY
* `/opt/yubico-piv-tool/bin/yubico-piv-tool -a verify -a pin-retries --pin-retries 3 --puk-retries 3 -k`

**7. generate a new PUK and store it in your PERSONAL vault.**

* Also store the Serial Number of your YubiKey
* A PUK must be 8 ASCII characters; alphanumeric characters are allowed!
* The default PUK (which is asked for) is "12345678"
* `/opt/yubico-piv-tool/bin/yubico-piv-tool -a change-puk`

**8. generate a PIN and store it in the keychain.***

* (optional) Store it in your PERSONAL vault
* `ykpiv-ssh-agent-helper --reset-pin`

**9. generate private key on yubikey to be used for SSH**

* while running this command, you have to TOUCH YOUR YUBIKEY.
* NOTE: we always require a touch for every key interaction!
* NOTE: We are NOT allowed to use --pin-policy=always, as this breaks ykpiv-ssh-agent-helper
* `/opt/yubico-piv-tool/bin/yubico-piv-tool -s 9a -a generate -o public.pem -k --touch-policy=always`

**10. generate self-signed certificate for that key**

* while running this command, you have to TOUCH YOUR YUBIKEY.
* NOTE: we take an expiry time of 10 years; as we cannot change this later.
* `/opt/yubico-piv-tool/bin/yubico-piv-tool -a verify-pin -a selfsign-certificate \
-s 9a -S "/CN=SSH for FIRSTNAME LASTNAME/" -i public.pem -o cert.pem --valid-days=3650`

**11. import the certificate again to the yubikey**

* while running this command, you have to TOUCH YOUR YUBIKEY
* `/opt/yubico-piv-tool/bin/yubico-piv-tool -a import-certificate -s 9a -i cert.pem -k`

**12. extract public SSH key**

* NOTE: shows the error "C_GetAttributeValue failed: 18"; can be ignored
* ```echo `ssh-keygen -D /usr/local/lib/libykcs11.dylib -e` `whoami`@YubiKey > `whoami`.yubikey.pub```

**13. reload SSH agent helper**

* `ykpiv-ssh-agent-helper -r`

**14. in the upcoming confirmation dialog, choose "Always allow" and
confirm by entering your system password**

* now start using the new public ssh key
* and register your YubiKey at auth.sandstorm.de
* for Firefox enable U2F support
