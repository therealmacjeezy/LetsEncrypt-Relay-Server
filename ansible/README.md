# Ansible Playbook for Let's Encrypt Relay Server

Here you will find some of the Ansible Playbooks that I have written for the Let's Encrypt Relay Server
- account_config.yml
    - Add a new user to the Let's Encrypt Relay Server and copy their SSH Public Key over
- renew_cert.yml
    - Renews all availble SSL Certs for your service account and copies them down from the Let's Encrypt Relay Server
- create_relay.yml
    - Installs apache and certbot
    - Creates the vhost.conf
    - Copies the wrapper and certmenu onto the server
    - Modifies the sshd_config to point it to the wrapper and adds the Match section to it
    - Creates the certbot group [if set]
