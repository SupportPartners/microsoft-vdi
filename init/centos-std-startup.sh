# Copyright (c) 2019 Teradici Corporation
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

#!/bin/bash

while getopts ":a:b:c:d:e:f:g:h:i:j:" opt; do
  case $opt in
    a) pcoip_registration_code="$OPTARG"
    ;;
    b) ad_service_account_password="$OPTARG"
    ;;
    c) ad_service_account_username="$OPTARG"
    ;;
    d) domain_name="$OPTARG"
    ;;
    e) domain_controller_ip="$OPTARG"
    ;;
    f) appID="$OPTARG"
    ;;
    g) aadClientSecret="$OPTARG"
    ;;
    h) tenantID="$OPTARG"
    ;;
    i) pcoip_reg_secret_key="$OPTARG"
    ;;
    j) ad_pass_secret_key="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&11
    ;;
  esac
done

INST_LOG_PATH="/var/log/teradici/agent/"
INST_LOG_FILE="/var/log/teradici/agent/install.log"

METADATA_BASE_URI="http://metadata.google.internal/computeMetadata/v1/instance"
METADATA_AUTH_URI="$METADATA_BASE_URI/service-accounts/default/token"
DECRYPT_URI="https://login.microsoftonline.com/${kms_cryptokey_id}/oauth2/v2.0/token"

log() {
    local message="$1"
    echo "[$(date)] ${message}" | tee -a "$INST_LOG_FILE"
}

get_access_token() {
    accessToken=`curl -X POST -d "grant_type=client_credentials&client_id=$1&client_secret=$2&resource=https%3A%2F%2Fvault.azure.net" https://login.microsoftonline.com/$3/oauth2/token`
    token=$(echo $accessToken | jq ".access_token" -r)
    log "$token"
    output=`curl -X GET -H "Authorization: Bearer $token" -H "Content-Type: application/json" --url "$4?api-version=2016-10-01"`
    log "$output"
    output=$(echo $output | jq '.value')
    chrlen=${#output}
    output=${output:1:$chrlen-2}
}

get_credentials() {
    # Check if we need to get secret from Azure Key Vault
    if [[ -z "$1" || -z "$2" || -z "$3" || -z "$4" || -z "$5" ]]; then
       log "Not getting secrets from Azure Key Vault: $2, $1, $3, $4, $5"
    else
       log "Using following passed data to decrypt: $2, $1, $3, $4, $5"
       get_access_token $2 $1 $3 $4
       pcoip_registration_code=$output
       log "REG: $pcoip_registration_code"
       get_access_token $2 $1 $3 $5
       ad_service_account_password=$output
       log "AD PASS: $ad_service_account_password"
    fi
}


exit_and_restart()
{
    log "--> Rebooting"
    (sleep 1; reboot -p) &
    exit
}

install_pcoip_agent() {
    if ! (rpm -q pcoip-agent-standard)
    then
        log "--> Start to install pcoip agent ..."
        # Get the Teradici pubkey
        log "--> Get Teradici pubkey"
        rpm --import https://downloads.teradici.com/rhel/teradici.pub.gpg

        # Get pcoip repo
        log "--> Get Teradici pcoip agent repo"
        wget --retry-connrefused --tries=3 --waitretry=5 -O /etc/yum.repos.d/pcoip.repo https://downloads.teradici.com/rhel/pcoip.repo

        # Install latest epel-release and GraphicsMagick which is required for pcoip-agent install
        log "--> Get epel-release and grapicsmagick-c++"
        yum -y install epel-release
        yum -y install GraphicsMagick-c++

        log "--> Install PCoIP standard agent ..."
        yum -y install pcoip-agent-standard
        if [ $? -ne 0 ]; then
            log "--> Failed to install PCoIP agent."
            exit 1
        fi
        log "--> PCoIP agent installed successfully."

        log "--> Register pcoip agent license ..."
        n=0
        while true; do
            /usr/sbin/pcoip-register-host --registration-code="$pcoip_registration_code" && break
            log "--> $?"
            n=$[$n+1]

            if [ $n -ge 10 ]; then
                log "--> Failed to register PCoIP agent after $n tries."
                log "--> $pcoip_registration_code"
                exit 1
            fi

            log "--> Failed to register PCoIP agent. Retrying in 10s..."
            sleep 10
        done
        log "--> Pcoip agent is registered successfully"
    fi
}

# Join domain
join_domain()
{
    local dns_record_file="dns_record"
    if [[ ! -f "$dns_record_file" ]]
    then
        log "--> DOMAIN NAME: ${domain_name}"
        log "--> USERNAME: ${ad_service_account_username}"
        log "--> PASSWORD: ${ad_service_account_password}"
        log "--> DOMAIN CONTROLLER: ${domain_controller_ip}"
        log "--> HOSTNAME: $HOSTNAME"

        VM_NAME=$(hostname)

        log "--> VM_NAME: $VM_NAME"

        # Wait for AD service account to be set up
        counter=0
        yum -v -y install openldap-clients
        log "$_"
        log "--> Wait for AD account ${ad_service_account_username}@${domain_name} to be available"
        until ldapwhoami -H ldap://${domain_controller_ip} -D ${ad_service_account_username}@${domain_name} -w "${ad_service_account_password}" -o nettimeout=3 > /dev/null 2>&1
        do
            counter=$(($counter + 1))
            log "${ad_service_account_username}@${domain_name} not available yet, retrying in 10 seconds..."
            sleep 10
            if [ $counter -ge 360 ]; then
                log "--> Failed to join domain controller after $counter tries."
                break
            fi
        done

        # Join domain
        log "--> Install required packages to join domain"
        yum -y install sssd realmd oddjob oddjob-mkhomedir adcli samba-common samba-common-tools krb5-workstation openldap-clients policycoreutils-python

        log "--> Restarting messagebus service"
        if ! (systemctl restart messagebus)
        then
            log "--> Failed to restart messagebus service"
            return 106
        fi

        log "--> Enable and start sssd service"
        if ! (systemctl enable sssd --now)
        then
            log "Failed to start sssd service"
            return 106
        fi

        log "--> Joining the domain"
        if [[ -n "$OU" ]]
        then
            echo "${ad_service_account_password}" | realm join --user="${ad_service_account_username}" --computer-ou="$OU" "${domain_name}" >&2
        else
            echo "${ad_service_account_password}" | realm join --user="${ad_service_account_username}" "${domain_name}" >&2
        fi
        exitCode=$?
        if [[ $exitCode -eq 0 ]]
        then
            log "--> Joined Domain '${domain_name}' and OU '$OU'"
        else
            log "--> Failed to join Domain '${domain_name}' and OU '$OU'"
            return 106
        fi

        log "--> Configuring settings"
        sed -i '$ a\dyndns_update = True\ndyndns_ttl = 3600\ndyndns_refresh_interval = 43200\ndyndns_update_ptr = True\nldap_user_principal = nosuchattribute' /etc/sssd/sssd.conf
        sed -c -i "s/\\(use_fully_qualified_names *= *\\).*/\\1False/" /etc/sssd/sssd.conf
        sed -c -i "s/\\(fallback_homedir *= *\\).*/\\1\\/home\\/%u/" /etc/sssd/sssd.conf
        domainname "$VM_NAME.${domain_name}"
        echo "%${domain_name}\\\\Domain\\ Admins ALL=(ALL) ALL" > /etc/sudoers.d/sudoers

        log "--> Registering with DNS"
        DOMAIN_UPPER=$(echo "${domain_name}" | tr '[:lower:]' '[:upper:]')
        IP_ADDRESS=$(hostname -I | grep -Eo '10.([0-9]*\.){2}[0-9]*')
        echo "${ad_service_account_password}" | kinit "${ad_service_account_username}"@"$DOMAIN_UPPER"
        touch "$dns_record_file"
        echo "server ${domain_controller_ip}" > "$dns_record_file"
        echo "update add $VM_NAME.${domain_name} 600 a $IP_ADDRESS" >> "$dns_record_file"
        echo "send" >> "$dns_record_file"
        nsupdate -g "$dns_record_file"
    fi
}

# ------------------------------------------------------------
# start from here
# ------------------------------------------------------------

if (rpm -q pcoip-agent-standard); then
    exit
fi

if [[ ! -f "$INST_LOG_FILE" ]]
then
    mkdir -p "$INST_LOG_PATH"
    touch "$INST_LOG_FILE"
    chmod +644 "$INST_LOG_FILE"
fi

log "$(date)"

yum -v -y update

yum -v -y install wget

yum -v -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

yum -v -y install jq

# Install GNOME and set it as the desktop
log "--> Install Linux GUI ..."
yum -yv groupinstall "GNOME Desktop" "Graphical Administration Tools"
# yum -y groupinstall "Server with GUI"

log "--> Set default to graphical target"
systemctl set-default graphical.target

log "Passed Variables: $2, $1, $3, $4, $5"
get_credentials $aadClientSecret $appID $tenantID $pcoip_reg_secret_key $ad_pass_secret_key

log "$domain_name ;; $domain_controller_ip"

if [[ -z domain_name && -z domain_controller_ip ]]; then
    log "--> Not joining domain controller"
else
    log "--> Joining domain controller"
    join_domain
fi

install_pcoip_agent

log "--> Installation is completed !!!"

exit_and_restart
