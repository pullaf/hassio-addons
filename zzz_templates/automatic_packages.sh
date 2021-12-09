#!/bin/bash
set +e 2>/dev/null

##################
# INIT VARIABLES #
##################

PACKAGES=${PACKAGES:-""}
PACKMANAGER="apk"

############################
# CHECK WHICH BASE IS USED #
############################

if [[ "$(apk -h 2>/dev/null)" ]]; then
# If apk based
PACKMANAGER="apk"
PACKAGES="apk add --no-cache $PACKAGES"
else
# If apt-get based
PACKMANAGER="apt"
PACKAGES="apt-get clean \
    && apt-get update \
    && apt-get install -y --no-install-recommends $PACKAGES"
fi

###################
# DEFINE PACKAGES #
###################

# ADD GENERAL ELEMENTS
######################

PACKAGES="$PACKAGES jq curl"

# FOR EACH SCRIPT, SELECT PACKAGES
##################################

# In etc
if ls /etc/nginx 1> /dev/null 2>&1; then
    [ $PACKMANAGER = "apk" ] && PACKAGES="$PACKAGES nginx"
    [ $PACKMANAGER = "apt" ] && PACKAGES="$PACKAGES nginx"
    mv /etc/nginx /etc/ngin2
fi

# Scripts
for files in "/scripts" "/etc/cont-init.d"; do

    if ls $files/*smb* 1> /dev/null 2>&1; then
    [ $PACKMANAGER = "apk" ] && PACKAGES="$PACKAGES cifs-utils keyutils samba samba-client"
    [ $PACKMANAGER = "apt" ] && PACKAGES="$PACKAGES cifs-utils keyutils samba smbclient"
    fi

    if ls $files/*vpn* 1> /dev/null 2>&1; then
    [ $PACKMANAGER = "apk" ] && PACKAGES="$PACKAGES coreutils openvpn"
    [ $PACKMANAGER = "apt" ] && PACKAGES="$PACKAGES coreutils openvpn"
    fi

    if ls $files/*global_var* 1> /dev/null 2>&1; then
    [ $PACKMANAGER = "apk" ] && PACKAGES="$PACKAGES jq"
    [ $PACKMANAGER = "apt" ] && PACKAGES="$PACKAGES jq"
    fi

    if ls $files/*yaml* 1> /dev/null 2>&1; then
    [ $PACKMANAGER = "apk" ] && PACKAGES="$PACKAGES yamllint"
    [ $PACKMANAGER = "apt" ] && PACKAGES="$PACKAGES yamllint"
    fi

    if [[ $(grep -rnw "$files/" -e 'git') ]]; then
    [ $PACKMANAGER = "apk" ] && PACKAGES="$PACKAGES git"
    [ $PACKMANAGER = "apt" ] && PACKAGES="$PACKAGES git"
    fi

    if [[ $(grep -rnw "$files/" -e 'sponge') ]]; then
    [ $PACKMANAGER = "apk" ] && PACKAGES="$PACKAGES moreutils"
    [ $PACKMANAGER = "apt" ] && PACKAGES="$PACKAGES moreutils"
    fi

    if [[ $(grep -rnw "$files/" -e 'sqlite') ]]; then
    [ $PACKMANAGER = "apk" ] && PACKAGES="$PACKAGES sqlite"
    [ $PACKMANAGER = "apt" ] && PACKAGES="$PACKAGES sqlite3"
    fi

    if [[ $(grep -rnw "$files/" -e 'lastversion') ]]; then
    [ $PACKMANAGER = "apk" ] && [[ $(pip -V) ]] \
      || apk add --no-cache py3-pip \
      && pip install lastversion
    [ $PACKMANAGER = "apt" ] && [[ $(pip -V) ]] \
      || apt-get install -y python-pip \
      && pip install lastversion
    fi

done

####################
# INSTALL ELEMENTS #
####################

echo "installing packages $PACKAGES" 
eval "$PACKAGES" 

# Replace nginx if installed
if [ -d /etc/nginx2 ]; then
    cp -rlf /etc/nginx2 /etc/nginx && rm -r /etc/nginx2
    mkdir -p /var/log/nginx 
    touch /var/log/nginx/error.log
fi

##################
# INSTALL BASHIO #
##################

mkdir -p /tmp/bashio
curl -L -f -s "https://github.com/hassio-addons/bashio/archive/v${BASHIO_VERSION}.tar.gz" | tar -xzf - --strip 1 -C /tmp/bashio
mv /tmp/bashio/lib /usr/lib/bashio
ln -s /usr/lib/bashio/bashio /usr/bin/bashio
rm -rf /tmp/bashio