#!/bin/bash
set -o errexit

chmodf() { find $2 -type f -exec chmod -v $1 {} \;
}
chmodd() { find $2 -type d -exec chmod -v $1 {} \;
}

echo -e "\n========================================================"
# If DataDirectory, identity keys or torrc is mounted here,
# ownership needs to be changed to the TOR_USER user
chown -Rv ${TOR_USER}:${TOR_USER} /var/lib/tor
# fix permissions
chmodd 700 /var/lib/tor
chmodf 600 /var/lib/tor

if [ ! -e /tor-config-done ]; then
    touch /tor-config-done   # only run this once

    # Add Nickname from env variable or randomized, if none has been set
    if ! grep -q '^Nickname ' /etc/tor/torrc; then
        if [ ${TOR_NICKNAME} == "Tor4" ] || [ -z "${TOR_NICKNAME}" ]; then
            # if user did not change the default Nickname, genetrate a random pronounceable one
            RPW=$(pwgen -0A 8)
            TOR_NICKNAME="Tor4${RPW}"
            echo "Setting random Nickname: ${TOR_NICKNAME}"
        else
            echo "Setting chosen Nickname: ${TOR_NICKNAME}"
        fi
        echo -e "\nNickname ${TOR_NICKNAME}" >> /etc/tor/torrc
    fi

    # Add Contact_Email from env variable, if none has been set in torrc
    if ! grep -q '^ContactInfo ' /etc/tor/torrc; then
        # if CONTACT_EMAIL is not null
        if [ -n "${CONTACT_EMAIL}" ]; then
            echo "Setting Contact Email: ${CONTACT_EMAIL}"
            echo -e "\nContactInfo ${CONTACT_EMAIL}" >> /etc/tor/torrc
        fi
    fi

    # Port to advertise for incoming Tor connections.
    if ! grep -q '^ORPort ' /etc/tor/torrc; then
        echo -e "\\nORPort 9001" >> /etc/tor/torrc
    fi

    # Run Tor only as a server (no local applications)
    if ! grep -q '^SocksPort ' /etc/tor/torrc; then
        echo -e "\\nSocksPort 0" >> /etc/tor/torrc
    fi

    # Run as a relay only (not as an exit node)
    if ! grep -q '^ExitPolicy ' /etc/tor/torrc; then
        echo -e "\\nExitPolicy reject *:*" >> /etc/tor/torrc
    fi

    # Run Tor as a regular user (do not change this)
    if ! grep -q '^User ' /etc/tor/torrc; then
        echo -e "\\nUser ${TOR_USER}" >> /etc/tor/torrc
    fi

    if ! grep -q '^DataDirectory ' /etc/tor/torrc; then
        echo -e "\\nDataDirectory /var/lib/tor" >> /etc/tor/torrc
    fi
fi

echo -e "\n========================================================"
# Display OS version, Tor version & torrc in log
echo -e "Debian Version: \c" && cat /etc/debian_version
tor --version
obfs4proxy -version
cat /etc/tor/torrc
echo -e "========================================================\n"

# else default to run whatever the user wanted like "bash"
exec "$@"
