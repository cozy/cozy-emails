#!/bin/sh

sudo stop dovecot
sudo rm /home/testuser/Maildir/dovecot-uidvalidity
sudo rm /home/testuser/Maildir/dovecot-uidvalidity.*
sudo sed -i s/V1386550439/V1337/g /home/testuser/Maildir/.Sent/dovecot-uidlist
echo "Changed uidvalidity of Sent box from 1386550439 to 1337"
sudo start dovecot