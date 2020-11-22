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

# Autoupdater 0.1 for nextcloud installation of all-inkl.com customers
# This script
# - sets the memory_limit in .user.ini
# - makes sure, missing indices and columns are added
# - updates apps, if available
# - updates the nextcloud instance
# - supports multiple instances in one account
#
# Make sure, that this script runs on your installation. It works for me.
# Use it on your own risk

# define the php_limit
php_memory_limit="512M"

# define file with list of installation directories
# see installations.txt.default
# set your installation directory under your root account
# i.e. if your install directory (nextcloud root) is /www/htdocs/w000000/domain.com/nextcloud
# then add "domain.com/nextcloud" to the installations.txt
installations="../installations.txt"

# get account directory from username (/www/htdocs/w000000 in the example above)
# This is especially for all-inkl.com, other providers may need another strategy
account_base="/www/htdocs/${USER//ssh-}"

while read install_dir; do
	nc_base=$account_base/$install_dir

	echo -e " "
	echo -e "\e[33m ==================================\e[0m"
	echo -e "\e[33m =\e[31m $install_dir \e[0m"
	echo -e "\e[33m ==================================\e[0m"
	echo -e "\e[33m - account base: \e[32m$account_base\e[0m"
	echo -e "\e[33m - nextcloud base dir: \e[32m$nc_base\e[0m"

	# set memory_limit to $php_memory_limit, if no memory_limit is set
	if grep -q "memory_limit" $nc_base/.user.ini; then
		echo -e "\e[33m - leave $nc_base/.user.ini untouched, memory_limit is already set\e[0m"
	else
		echo "memory_limit=$php_memory_limit" >> $nc_base/.user.ini
		echo -e "\e[32m - $nc_base/.user.ini memory_limit=$php_memory_limit added\e[0m"
	fi

	# occ db:add-missing-indices and :add-missing-columns is called blind
	echo -e "\e[33m - try db optimizations\e[0m"
	echo -e "\e[33m - run occ db:add-missing-indices\e[0m"
	php -d memory_limit=$php_memory_limit $nc_base/occ db:add-missing-indices
	echo -e "\e[33m - run occ db:add-missing-columns\e[0m"
	php -d memory_limit=$php_memory_limit $nc_base/occ db:add-missing-columns
	echo -e "\e[33m - run occ db:add-missing-primary-keys\e[0m"
	php -d memory_limit=$php_memory_limit $nc_base/occ db:add-missing-primary-keys
	echo -e "\e[33m - run occ db:convert-filecache-bigint\e[0m"
	php -d memory_limit=$php_memory_limit $nc_base/occ db:convert-filecache-bigint

	# assuming that occ update:check still reports the same strings
	# "Everything up to date" means, there are no updates, end script in this case
	# "update for" means there is an update for at least one app
	# "Get more information on how to update" means, there is a Nextcloud update available
	if php -d memory_limit=$php_memory_limit $nc_base/occ update:check | grep -q "Everything up to date"; then
	    echo -e "\e[32m - No Updates available\e[0m"
	else

		if php -d memory_limit=$php_memory_limit $nc_base/occ update:check | grep "update for"; then
			echo -e "\e[32m - app updates are available\e[0m"
			echo -e "\e[33m - start updating apps\e[0m"
			php -d memory_limit=$php_memory_limit $nc_base/occ app:update --all -n
		fi

		if php -d memory_limit=$php_memory_limit $nc_base/occ update:check | grep "Get more information on how to update"; then
			echo -e "\e[32m - new Nextcloud version is available\e[0m"
			echo -e "\e[33m - start update Nextcloud version\e[0m"
			php -d memory_limit=$php_memory_limit $nc_base/updater/updater.phar -n

			echo -e "\e[33m - run occ db:add-missing-indices\e[0m"
			php -d memory_limit=$php_memory_limit $nc_base/occ db:add-missing-indices

			echo -e "\e[33m - run occ db:add-missing-columns\e[0m"
			php -d memory_limit=$php_memory_limit $nc_base/occ db:add-missing-columns

			# check memory_limit again after Nextcloud update
			if grep -q "memory_limit" $nc_base/.user.ini; then
				echo -e "\e[33m - leave $nc_base/.user.ini untouched, memory_limit is already set\e[0m"
			else
				echo "memory_limit=$php_memory_limit" >> $nc_base/.user.ini
				echo -e "\e[32m - $nc_base/.user.ini memory_limit=$php_memory_limit added\e[0m"
			fi

		fi
	fi
done <$installations
