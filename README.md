# all-inkl-nc-updater

Autoupdater for nextcloud installations of all-inkl.com customers

This script

- sets the memory_limit in .user.ini
- makes sure, missing indices and columns are added
- updates apps, if available
- updates the nextcloud instance
- supports multiple instances inside one hoster account

Make sure, that this script runs on your installation. It works for me. Use it on your own risk!
Before the first run, edit your installations.txt as described below and in the updater script.
To update call the update.sh file

# Important changes

- Moved the installations.txt to the script directory
- Patching $evalScriptAllowed is not necessary anymore and got removed

# Installation

## Via git (recommended)

- log into your server via ssh
- create a new directory in your account i.e. /helpers
- cd into it
- clone the repository
- make the script executable
- create the definition file
  ```shell
  mkdir helpers
  cd helpers
  git clone https://github.com/dartcafe/all-inkl-nc-updater.git
  chmod 744 ./all-inkl-nc-updater/update.sh
  touch ./all-inkl-nc-updater/installations.txt
  ```
- open installations.txt in your editor and enter your installations relative to your accounts root
  - i.e. if your install directory (nextcloud root) is /www/htdocs/w000000/domain.com/nextcloud
  - then add "domain.com/nextcloud" to the `installations.txt`
  - for multiple installations add more lines with the correct path to the installation (see [`installations.txt.sample`](https://github.com/dartcafe/all-inkl-nc-updater/blob/master/installations.txt.sample))

## Get updates (via git)

- log in to your server via ssh
- cd into the script directory cloned by git (`helpers/all-inkl-nc-updater` in this example)
  ```shell
  cd helpers/all-inkl-nc-updater
  ```
- execute the following commands:
  ```shell
  chmod 644 update.sh
  git fetch
  git pull
  chmod 744 update.sh
  ```
- You may want to remove alloweval.txt
  ```shell
  rm ./alloweval.txt
  ```
