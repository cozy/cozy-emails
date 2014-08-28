#!/bin/sh

echo 'Provisioning Environment with Dovecot and Test Messages'

# Install and Configure Dovecot

  if which dovecot > /dev/null; then
    echo 'Dovecot is already installed'
  else

    echo 'Updating apt-get repositories'
    sudo apt-get -qq update


    echo 'Installing Dovecot'
    sudo apt-get -qq -y install dovecot-imapd dovecot-pop3d
    sudo touch /etc/dovecot/local.conf
    sudo echo 'mail_location = maildir:/home/%u/Maildir' >> /etc/dovecot/local.conf
    sudo echo 'disable_plaintext_auth = no' >> /etc/dovecot/local.conf
    sudo echo 'mail_max_userip_connections = 10000' >> /etc/dovecot/local.conf
    sudo restart dovecot
    echo 'Dovecot has been installed'
  fi


# Create "testuser"

  if getent passwd testuser > /dev/null; then
    echo 'testuser already exists'
  else
    echo 'Creating User "testuser" with password "applesauce"'
    sudo useradd testuser -m -s /bin/bash
    echo "testuser:applesauce" | sudo chpasswd
    echo 'User created'
  fi


# Setup Email

  echo 'Refreshing the test mailbox.'

  sudo stop dovecot
  [ -d "/home/testuser/Maildir" ] && sudo rm -R /home/testuser/Maildir
  sudo cp -Rp /resources/Maildir /home/testuser/
  sudo chown -R testuser:testuser /home/testuser/Maildir
  sudo start dovecot

  echo 'Test mailbox restored'.


# Done!

echo ''
echo ''
echo 'Dovecot has been provisioned with the test mailbox.'
echo ''
echo ''