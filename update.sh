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
#
# Autoupdater for Nextcloud installations on all-inkl.com.

set -Eeuo pipefail

on_error() {
	local status=$?
	printf 'ERROR: command failed (line %s, exit %s): %s\n' "$1" "$status" "$BASH_COMMAND" >&2
	exit "$status"
}
trap 'on_error "$LINENO"' ERR

logger() {
	local text="$1"
	[[ -n "$text" ]] && printf '\033[33m%s\033[0m\n' "$text"
}

fail() {
	logger "ERROR: $1" >&2
	exit 1
}

occ() {
	php -d "memory_limit=$PHP_MEMORY_LIMIT" "$NC_BASE/occ" "$@"
}

occ_add_indices() {
	logger "- add missing database indices, columns and primary keys"
	occ db:add-missing-indices
	occ db:add-missing-columns
	occ db:add-missing-primary-keys
	occ -n db:convert-filecache-bigint
}

set_php_limit() {
	local user_ini="$NC_BASE/.user.ini"
	if [[ -f "$user_ini" ]] && grep -Eq '^[[:space:]]*memory_limit[[:space:]]*=' "$user_ini"; then
		logger "- leave $user_ini untouched; memory_limit is already set"
	else
		printf 'memory_limit=%s\n' "$PHP_MEMORY_LIMIT" >> "$user_ini"
		logger "- set memory_limit=$PHP_MEMORY_LIMIT in $user_ini"
	fi
}

update_nc_version() {
	local updater="$NC_BASE/updater/updater.phar"
	[[ -f "$updater" ]] || fail "Nextcloud updater not found: $updater"
	logger "- run the Nextcloud updater"
	php -d "memory_limit=$PHP_MEMORY_LIMIT" "$updater" --no-interaction
}

update_apps() {
	logger "- update available apps"
	occ app:update --all --no-interaction
}

process_installation() {
	local install_dir="$1"
	NC_BASE="$ACCOUNT_BASE/$install_dir"

	case "$install_dir" in
		/*|..|../*|*/../*|*/..)
			fail "installation path must stay under the account root: $install_dir"
			;;
	esac

	[[ -f "$NC_BASE/occ" ]] || fail "occ not found; check installation path: $NC_BASE"
	[[ -f "$NC_BASE/config/config.php" ]] || fail "Nextcloud config not found: $NC_BASE/config/config.php"

	logger " "
	logger "=================================="
	logger "- Nextcloud installation: $install_dir"
	logger "- Account base: $ACCOUNT_BASE"
	logger "- Nextcloud base: $NC_BASE"
	logger "=================================="

	set_php_limit
	# The updater replaces the code and runs `occ upgrade` after replacement.
	update_nc_version
	occ_add_indices
	update_apps
}

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
[[ -n "${USER:-}" ]] || fail 'USER is not set; cannot determine the All-Inkl account directory'
ACCOUNT_BASE="/www/htdocs/${USER#ssh-}"
INSTALLATIONS="$SCRIPT_DIR/installations.txt"
PHP_MEMORY_LIMIT="512M"
INSTALLATION_COUNT=0

[[ -f "$INSTALLATIONS" ]] || fail "installations.txt missing: $INSTALLATIONS"
[[ -d "$ACCOUNT_BASE" ]] || fail "All-Inkl account directory not found: $ACCOUNT_BASE"

while IFS= read -r install_dir || [[ -n "$install_dir" ]]; do
	install_dir=${install_dir%$'\r'}
	# Ignore blank lines and comments in the installation list.
	[[ -z "$install_dir" || "$install_dir" == \#* ]] && continue
	process_installation "$install_dir"
	INSTALLATION_COUNT=$((INSTALLATION_COUNT + 1))
done < "$INSTALLATIONS"

(( INSTALLATION_COUNT > 0 )) || fail "no installations configured in $INSTALLATIONS"
