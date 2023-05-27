# all-inkl-nc-updater
Autoupdater for nextcloud installations of all-inkl.com customers

This script
- sets the memory_limit in .user.ini
- makes sure, missing indices and columns are added
- updates apps, if available
- updates the nextcloud instance
- allow eval() for defined installations
- supports multiple instances inside one hoster account

Make sure, that this script runs on your installation. It works for me. Use it on your own risk!
Before the first run, edit your installations.txt as described below and in the updater script.
To update call the update.sh file

# Important changes
* moved the installations.txt to the script directory

# Installation
## Via git (recommended)
* log in to your server via ssh
* create a new directory in your account i.e. /helpers
* call `git clone https://github.com/dartcafe/all-inkl-nc-updater.git`
* cd into the new created directory (`cd helpers/all-inkl-nc-updater` in this example)
* call `chmod 744 ./all-inkl-nc-updater/update.sh`
* call `touch installations.txt`
* call `touch alloweval.txt`
* open installations.txt in your editor and enter your installations relative to your accounts root
  * i.e. if your install directory (nextcloud root) is /www/htdocs/w000000/domain.com/nextcloud
  * then add "domain.com/nextcloud" to the `installations.txt`
  * for multiple installations add more lines with the correct path to the installation (see `installations.txt.sample`)
* open alloweval.txt and add your installations, where eval() should be allowed
  * the schema is identical to installations.txt
## get updates (via git)
* log in to your server via ssh
* cd into the directory created above (`cd helpers` in this example)
* call `chmod 644 ./all-inkl-nc-updater/update.sh`
* call `git pull`
* call `git fetch`
* call `chmod 744 ./all-inkl-nc-updater/update.sh`
