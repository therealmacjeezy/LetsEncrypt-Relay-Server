#!/bin/bash

#################################################
# LE Relay Server Cert Menu
# Joshua Harvey | April 2019
# josh[at]macjeezy.com
# github - therealmacjeezy
#################################################

# NOTES: NEED TO MODIFY THE WEBROOT LOCATION

export TERM=xterm

## Script Variables
sshOption=$(echo "$1" | tr '[:upper:]' '[:lower:]')

# Certbot options to sandbox certbot to each service account's home directory
CERTBOT_OPTS="--webroot -w /var/www/html/gs-3285-le/public_html/ --config-dir /home/$USER/SSL/ --work-dir /home/$USER/.cert_work/ --logs-dir /home/$USER/.cert_logs/"
CERTBOT_OPTS_CREATE="--webroot -w /var/www/html/gs-3285-le/public_html/ --agree-tos -m josh@macjeezy.com --no-eff-email --config-dir /home/"$USER"/SSL/ --work-dir /home/"$USER"/.cert_work/ --logs-dir /home/"$USER"/.cert_logs/"

renewCert() {
    if [[ -z "$2" ]]; then
        # Renews the certificates in the users directory
        certbot renew --webroot -w /var/www/html/gs-3285-le/public_html/ --config-dir /home/$USER/SSL/ --work-dir /home/$USER/.cert_work/ --logs-dir /home/$USER/.cert_logs/
    else
        # Renews one certificate
        echo "Attempting certificate renewal for $2"

        certbot renew --cert-name "$2" --webroot -w /var/www/html/gs-3285-le/public_html/ --config-dir /home/$USER/SSL/ --work-dir /home/$USER/.cert_work/ --logs-dir /home/$USER/.cert_logs/
    fi
}

createCert() {
    echo "#############################################"
    echo "# therealmacjeezy's LetsEncrypt Relay Server"
    echo "# Logged In As: $USER"
    echo "#############################################"
    echo " "
    echo "Enter the FQDN (Domain Name) being used:"
    echo "Example: penguinmetal.macjeezy.com"
    printf 'FQDN: '
    read certDomain

    while [[ -z "$certDomain" ]]; do
        echo "Enter the FQDN (Domain Name) being used:"
        echo "Example: penguinmetal.macjeezy.com"
        printf 'FQDN: '
        read certDomain
    done

    verifyDomain=""

    while [[ -z "$verifyDomain" ]]; do
        echo " "
        echo "Your FQDN is: $certDomain"
        printf 'Is this correct? (Y/N): '
        read verifyInput

        case "$verifyInput" in
            Y|y)
                verifyDomain="done"
                certName="$certDomain"
                ;;
            N|n)
                echo "Enter the FQDN (Domain Name) being used:"
                printf 'FQDN: '
                read certDomain
                ;;
            *)
                echo "Invalid Input"
                ;;
        esac
    done

    printf "Do you have any additional SANs? (Y/N): "
    read addSANS

    case "$addSANS" in
        Y|y)
            echo "Enter SANs seperated by commas"
            echo "Example: penguinmetal.macjeezy.com,nolacontux.macjeezy.com"
            printf 'SANs: '
            read certSANS
            supportSANS="yes"
            ;;
        N|n)
	        echo " "
            ;;
        *)
            echo "Invalid Entry"
            ;;
    esac

    if [[ "$supportSANS" == "yes" ]]; then
        certDomain="$certDomain,$certSANS"
        firstDomain=$(echo "$certDomain" | sed 's/[,].*//g')
    fi

    if [[ -z "$certDomain" ]]; then
        echo "No FQDN was entered. This is required."
        echo "Example: penguinmetal.macjeezy.com"
        echo "Exiting.."
        exit 1
    else
        certbot certonly --webroot -w /var/www/html/gs-3285-le/public_html/ --agree-tos -m josh@macjeezy.com --no-eff-email --config-dir /home/"$USER"/SSL/ --work-dir /home/"$USER"/.cert_work/ --logs-dir /home/"$USER"/.cert_logs/ -d "$certDomain" -q
        # Use below line for testing
        #certbot certonly --webroot -w /var/www/html/gs-3285-le/public_html/ --agree-tos -m josh@macjeezy.com --no-eff-email --config-dir /home/"$USER"/SSL/ --work-dir /home/"$USER"/.cert_work/ --logs-dir /home/"$USER"/.cert_logs/ -d "$certDomain" --test-cert

        getDir=$(ls /home/"$USER"/SSL/live | grep "$firstDomain")

            if [[ -a /home/"$USER"/SSL/live/"$getDir"/fullchain.pem ]]; then
                echo "The certificate for $certDomain has been created"
                echo "Certificate Path: /home/"$USER"/SSL/live/"$getDir""
            else
                echo "Unable to create certificate, check the FQDN and try again."
                exit 1
            fi
    fi
}

listAll() {
    certbot certificates --webroot -w /var/www/html/gs-3285-le/public_html/ --config-dir /home/$USER/SSL/ --work-dir /home/$USER/.cert_work/ --logs-dir /home/$USER/.cert_logs/
}

scriptUsage() {

cat <<helptext

therealmacjeezy's LetsEncrypt Proxy Server
Updated: April 2019

Usage:
	> ssh svcaccount@le.macjeezy.com '[Option]'

Options:
create - Create a LetsEncrypt Certificate
    If create is used without any additional options, you will get an interactive menu asking for the domain name and if any additional SANs are needed.

    If create is used with additonal options (see examples below), it will skip the interactive menu and start the certificate creation process.

    You will also be able to create a .pfx file after the certificate has been successfully created

	NOTE: If additional SANs are needed, list them seperated by commas and no spaces in between
	- Examples:
		> ssh svcaccount@le.macjeezy.com create
		> ssh svcaccount@le.macjeezy.com 'create penguinmetal.macjeezy.com'

renew - Renews a LetsEncrypt Certificate
	If create is used without any additonal options, it will automatically check each certificate in your home directory and renew them if needed.

    If create is used WITH additional options (see examples below), it will only check the certifcate name that was entered

	- Examples:
		> ssh svcaccount@le.macjeezy.com renew
		> ssh svcaccount@le.macjeezy.com 'renew penguinmetal.macjeezy.com'

pfx - Creates a pfx file from the LetsEncrypt certificates
    If the certificate name is not used with this option, you will get an error stating it is unable to create the pfx file.

    - Example:
        > ssh svcaccount@le.macjeezy.com 'pfx penguinmetal.macjeezy.com'

list - Returns a list of all the certificates in your home directory and information about each one
	- Examples:
		> ssh svcaccount@le.macjeezy.com list

help|? - Displays this usage menu

Notes:
	When copying the LetsEncrypt certificate from this server to your webserver, you can use the scp/sftp commands as normal. There is no option inside this script to copy.
helptext
}


winExport_renew() {
    openssl pkcs12 -export -out /home/"$USER"/SSL/live/"$leCert"/iisCert.pfx -inkey /home/"$USER"/SSL/live/"$leCert"/privkey.pem -in /home/"$USER"/SSL/live/"$leCert"/cert.pem -certfile /home/"$USER"/SSL/live/"$leCert"/fullchain.pem

    if [[ -a "/home/$USER/SSL/live/"$leCert"/iisCert.pfx" ]]; then
        echo "PFX Location: /home/$USER/SSL/live/"$leCert"/iisCert.pfx"
    else
        echo "Unable to create PFX Certificate"
    fi
}


case "$sshOption" in
    renew)
        renewCert
        ;;
    pfx)
        if [[ ! -z "$2" ]]; then
            leCert="$2"
	        winExport_renew
        elif [[ -z "$2" ]]; then
            echo "Missing Required Certificate Name"
            echo "Example: ssh svcaccount@le.macjeezy.com 'pfx penguinmetal.macjeezy.com'"
            scriptUsage
        fi
        ;;
    create)
        if [[ -z "$2" ]]; then
            createCert
        elif [[ ! -z "$2" ]]; then
            certDomain="$2"
	    firstDomain=$(echo "$certDomain" | sed 's/[,].*//g')
            echo "$firstDomain"
	    certbot certonly --webroot -w /var/www/html/gs-3285-le/public_html/ --agree-tos -m josh@macjeezy.com --no-eff-email --config-dir /home/"$USER"/SSL/ --work-dir /home/"$USER"/.cert_work/ --logs-dir /home/"$USER"/.cert_logs/ -d "$certDomain"
            #certbot certonly --webroot -w /var/www/html/gs-3285-le/public_html/ --agree-tos -m josh@macjeezy.com --no-eff-email --config-dir /home/"$USER"/SSL/ --work-dir /home/"$USER"/.cert_work/ --logs-dir /home/"$USER"/.cert_logs/ -d "$certDomain" --test-cert

            getDir=$(ls /home/"$USER"/SSL/live/ | grep "$firstDomain")

	    #echo "$getDir"

            if [[ -a /home/"$USER"/SSL/live/"$getDir"/fullchain.pem ]]; then
                echo "The certificate for $certDomain has been created"
                echo "Certificate Path: /home/"$USER"/SSL/live/"$getDir""
                echo " "
            else
                echo "Unable to create certificate, check the FQDN and try again."
                exit 1
            fi
        fi
        ;;
    help|?)
        scriptUsage
        ;;
    list)
        listAll
        ;;
    *)
        echo "Invalid/Missing Option"
        echo " "
        scriptUsage
        exit 1
        ;;
esac

exit 0