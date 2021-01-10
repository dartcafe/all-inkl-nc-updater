# all-inkl-nc-updater
Autoupdater for nextcloud installations of all-inkl.com customers

This script
- sets the memory_limit in .user.ini
- makes sure, missing indices and columns are added
- updates apps, if available
- updates the nextcloud instance
- supports multiple instances in one account

Make sure, that this script runs on your installation. It works for me. Use it on your own risk!
Before the first run, edit your installations.txt as described below and in the updater script.
To update call the update.sh file

# Installation
## Via git (recommended)
* log in to your server via ssh
* create a new directory inyour account i.e. /helpers
* call `git clone https://github.com/dartcafe/all-inkl-nc-updater.git`
* cd into the new created directory (`cd helpers` in this example)
* call `touch installations.txt`
* open installations.txt in your editor and enter your installations relative to your accounts root
  * i.e. if your install directory (nextcloud root) is /www/htdocs/w000000/domain.com/nextcloud
  * then add "domain.com/nextcloud" to the installations.txt
  * for multiple installations add more lines with the correct path to the installation
* call `chmod 744 ./all-inkl-nc-updater/update.sh`

## get updates (via git)
* log in to your server via ssh
* cd into the directory created above (`cd helpers` in this example)
* call `chmod 644 ./all-inkl-nc-updater/update.sh`
* call `git pull`
* call `git fetch`
* call `chmod 744 ./all-inkl-nc-updater/update.sh`
