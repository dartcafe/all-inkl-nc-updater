#!/bin/bash

# - @copyright Copyright (c) 2020 René Gieling <github@dartcafe.de>
# -
# - @author René Gieling <github@dartcafe.de>
# -
# - @license GNU AGPL version 3 or any later version
# -
# - This program is free software: you can redistribute it and/or modify
# - it under the terms of the GNU Affero General Public License as
# - published by the Free Software Foundation, either version 3 of the
# - License, or (at your option) any later version.
# -
# - This program is distributed in the hope that it will be useful,
# - but WITHOUT ANY WARRANTY; without even the implied warranty of
# - MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# - GNU Affero General Public License for more details.
# -
# - You should have received a copy of the GNU Affero General Public License
# - along with this program. If not, see <http://www.gnu.org/licenses/>.

# Autoupdater 0.2 for nextcloud installation of all-inkl.com customers
# This script
# - sets the memory_limit in .user.ini
# - makes sure, missing indices and columns are added
# - updates apps, if available
# - updates the nextcloud instance
# - supports multiple instances in one account
#
# Make sure, that this script runs on your installation. It works for me.
# Use it at your own risk

function test_installations() {
    if [[ ! -f ${installations} ]]; then
        logger "- installations.txt missing"
        exit 1
    fi
}

function logger()
{
    local text="$1"
    if [[ "${text}" != "" ]] ; then
			echo -e "\e[33m${text}\e[0m"
    fi
}

function occ_add_indices()
{
	# occ db:add-missing-indices and :add-missing-columns is called blind
	logger "- run occ db:add-missing-indices"
	php -d memory_limit=$php_memory_limit $nc_base/occ db:add-missing-indices
	logger "- run occ db:add-missing-columns"
	php -d memory_limit=$php_memory_limit $nc_base/occ db:add-missing-columns
	logger "- run occ db:add-missing-primary-keys"
	php -d memory_limit=$php_memory_limit $nc_base/occ db:add-missing-primary-keys
	logger "- run occ -n db:convert-filecache-bigint"
	php -d memory_limit=$php_memory_limit $nc_base/occ -n db:convert-filecache-bigint
}

function set_php_limit()
{
	# set memory_limit to $php_memory_limit, if no memory_limit is set
	if grep -q "memory_limit" $nc_base/.user.ini; then
		logger "- leave $nc_base/.user.ini untouched, memory_limit is already set"
	else
		echo "memory_limit=$php_memory_limit" >> $nc_base/.user.ini
		logger "- $nc_base/.user.ini memory_limit=$php_memory_limit added"
	fi
}

function occ_upgrade()
{
	# run occ upgrade to make sure, all apps are up to date
	logger "- make sure everything is up to date before update"
	logger "- run occ upgrade first"
	php -d memory_limit=$php_memory_limit $nc_base/occ upgrade
}

function occ_update_check() {
	logger "- run occ update:check"
	if php -d memory_limit=$php_memory_limit $nc_base/occ update:check | grep -q "Everything up to date"; then
	    logger "- No Updates available"
		update_available=0
	else
		logger "- Updates available"
		update_available=1
	fi

	if php -d memory_limit=$php_memory_limit $nc_base/occ update:check | grep "Get more information on how to update"; then
		logger "- New Nextcloud version is available"
		update_available=2
	fi
}

function occ_app_update()
{
	logger "- start updating apps"
	php -d memory_limit=$php_memory_limit $nc_base/occ app:update --all -n
}

function update_nc_version()
{
	logger "- start update Nextcloud version"
	php -d memory_limit=$php_memory_limit $nc_base/updater/updater.phar -n
}

# init check variables
update_available=0

script_dir=$(dirname "$0")
# get account directory from username (/www/htdocs/w000000 in the example above)
# This is especially for all-inkl.com, other providers may need another strategy
account_base="/www/htdocs/${USER//ssh-}"

# define file with list of installation directories
# see installations.txt.default
# set your installation directory under your root account
# i.e. if your install directory (nextcloud root) is /www/htdocs/w000000/domain.com/nextcloud
# then add "domain.com/nextcloud" to the installations.txt
installations="$script_dir/installations.txt"

# define the php_memory_limit
php_memory_limit="512M"

while read install_dir; do
	nc_base=$account_base/$install_dir

	logger " "
	logger "=================================="
	logger "- nextcloud installation: \e[96m$install_dir"
	logger "=================================="
	logger "- account base: \e[32m$account_base"
	logger "- nextcloud base dir: \e[32m$nc_base"
	logger "=================================="

	logger "- chmod 744 $nc_base/occ"
	chmod 744 $nc_base/occ

	set_php_limit
	occ_upgrade
	occ_add_indices
	occ_app_update
	occ_update_check

	# assuming that occ update:check still reports the same strings
	# "Everything up to date" means, there are no updates, end script in this case
	# "update for" means there is an update for at least one app
	# "Get more information on how to update" means, there is a Nextcloud update available
	if [ "${update_available}" != "0" ] ; then
		logger "- start updating apps"
		occ_app_update

		if [ "${update_available}" = "2" ] ; then
			update_nc_version
			occ_add_indices
			set_php_limit
		fi
	fi
done <$installations
