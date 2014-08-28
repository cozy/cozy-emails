#!/bin/sh

/bin/bash /resources/Scripts/Provision.sh


## Since we don't want Vagrant to be forgotten and left running, but also don't
## want to have to reboot it between each test, we set a delayed shutdown.
## Every time the host is reset (which presumably corresponds with a test being
## run) the old timer is killed and a new one created.

# Stop any previous shutdown timers
sudo killall sleep

# Start a new shutdown timer.
sudo sleep 1800 && shutdown -h now &