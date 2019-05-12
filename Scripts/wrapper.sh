#!/bin/bash

#################################################
# LE Relay Server SSH Wrapper
# Joshua Harvey | April 2019
# josh[at]macjeezy.com
# github - therealmacjeezy
#################################################


if [[ "${SSH_ORIGINAL_COMMAND:0:3}" == "scp" ]]; then
  # scp
  eval $SSH_ORIGINAL_COMMAND
elif [[ "$SSH_ORIGINAL_COMMAND" == "/usr/libexec/openssh/sftp-server" ]]; then
  # sftp
  /usr/libexec/openssh/sftp-server $SSH_ORIGINAL_COMMAND
else
  # ssh for command
  /opt/cert/certmenu.sh $SSH_ORIGINAL_COMMAND
fi