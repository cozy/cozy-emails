# Dovecot Testing

This package is used to test IMAP and POP client libraries by giving them a consistent mailbox to work with. This simple
to use library lets developers run their test suites locally using Vagrant and on Travis-CI without having to make any
modifications.

This package can be used for testing libraries in any language. It was originally built to support a PHP library,
[Fetch](https://github.com/tedious/Fetch), so there is some extra support for PHP developers already built in. I encourage
everyone to submit feature requests or, even better, pull requests to help make this package more consumable for other
languages.


## Usage

### SetupEnvironment.sh

The SetupEnvironment.sh file acts as a wrapper around a number of different scripts. It identifies which of the
systems below it is being asked to control and then takes the appropriate steps to get the environment setup for
testing.

The optimal way to utilize this script is to integrate it directly into your test suite, typically as bootstrap or
pretest action. This way you can simply call your test suite as normal and will be assured of a completely consistent
environment.


### Server Settings

* Username: **testuser**
* Password: **applesauce**
* IMAP: **143**
* IMAPS: **993**
* POP: **110**
* POPS: **995**
* Vagrant IP Address: **172.31.1.2**
* Travis IP Address: **127.0.0.1**


### PHP

This package is available via Composer, which makes integrating it into Travis-CI trivial.

First add the relevant line into your composer configuration:

```
"require-dev": {
      "tedivm/dovecottesting": "~1"
  },
```

Then modify your Travis configuration:

```
before_script:
    - composer install --dev
    - vendor/tedivm/dovecottesting/SetupEnvironment.sh
```


### Vagrant Notes

You'll need to have [Vagrant](http://www.vagrantup.com) and [VirtualBox](https://www.virtualbox.org) installed for local
development. Once these packages are installed the only thing left to do is call SetupEnvironment.sh as outlined above.

The first time you start the environment with Vagrant it may need to download the template box. This can add a few
minutes to the start time of the script but will only need to happen once.

If an environment does already exist than this script will simply reset it's email back to the original status so the
test can be run again. This process takes just a few seconds.

The virtual machine will turn itself off 30 minutes after the last time SetupEnvironment.sh was run, which should occur
before every run of your test suite. This keeps the machine running while you're testing so you can have a very quick
turnaround, but also makes sure it isn't left running when not being used.


### Travis CI Notes

Just like with Vagrant, you simply need to run the SetupEnvironment.sh script before running your tests. Getting the
package onto Travis CI can be done through a package manager directly, as with the composer example above, or through
through a wrapper script that pulls it directly from git.


## Adding Additional Emails

This package works by storing a copy of a working Dovecot mail directory and then copying that directory into the test environment. Adding a new email in means sending it to the running instance of Dovecot and then updating the resources directory to make sure those changes stick between uses. This can be done a number of ways.

The preferred way is to connect a mail client to the running instance of Dovecot, and then using that to transfer the email in. Most mail clients, such as Mail.app, allow drag and drop transfer of emails between accounts. This method is simpliest because it does not require setting up an SMTP server, as it simply reuses an existing "real" account to create the message and then transfers it in. This was the method used to creating the initial set of emails.

Another option is to enable postfix directly on the Vagrant instance and to use that to recieve messages. This gets a little more complicated because it does require getting a mail server setup and integrated with Dovecot. 

A final method is to email testuser@tedivm.com with the desired message, and then to open an issue here to request it's inclusion. There is obviously a bit of turnaround here, so please attempt to add it in on your own and feel free to issue a pull request to get it included here.
