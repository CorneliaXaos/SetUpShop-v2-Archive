#!/usr/bin/env bash

#########################################
### XInstall - Installing ALL the things!
#########################################
### Base Dependencies:
###     - zenity
### Operational Dependencies:
###     - apt
###     - snap
###     - jq
###     - wget
###     - curl
#########################################

####
## Initialization
####

# Prep for rough exit.
trap 'exit $EXIT_VAL' TERM
export TOP_PID=$$

# Get directory of this script.
# We'll use it as the source for our default installation source directories:
# 'groups' and 'packages'
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
DIR_GROUPS="$DIR/groups"
DIR_PACKAGES="$DIR/packages"

# Common Variables and Such
DATE=`date`
LOG_FILE="`pwd`/XInstall - `echo $DATE | sed -e s/:/./g`.log"

# Pull in libraries
source $DIR/utility.lib.sh
source $DIR/logging.lib.sh
source $DIR/core.lib.sh
source $DIR/error.lib.sh

# Setup
core_init
logging_init "$LOG_FILE" "$DATE"

# Check for root and dependencies
( core_check_root && logging_has_root "$LOG_FILE" ) ||
    ( logging_not_root "$LOG_FILE" && error_not_root )
( core_check_depends_base && logging_has_depends_base "$LOG_FILE" ) ||
    ( logging_missing_depends_base "$LOG_FILE" && error_missing_depends_base )
( core_check_depends_operational && logging_has_depends_operational "$LOG_FILE" ) ||
    ( logging_missing_depends_operational "$LOG_FILE" && error_missing_depends_operational )

####
## Groups Selection
####

GROUPS_ALL=`
    ( core_read_groups "$DIR_GROUPS" ) ||
    ( logging_no_groups_read "$LOG_FILE" && error_no_groups )
    `
logging_read_groups "$LOG_FILE" "$GROUPS_ALL"

GROUPS_SELECTED=`core_select_groups "$GROUPS_ALL" "$DIR_GROUPS"`
logging_groups_selected "$LOG_FILE" "$GROUPS_SELECTED"

####
## Groups Processing / Package Installation
####

for GROUP in $(echo $GROUPS_SELECTED | sed 's/|/\n/g'); do
    PACKAGES_SELECTED=`core_select_packages "$GROUP" "$DIR_GROUPS" "$DIR_PACKAGES"`
    logging_packages_selected "$LOG_FILE" "$GROUP" "$PACKAGES_SELECTED"
    for PACKAGE in $(echo $PACKAGES_SELECTED | sed 's/|/\n/g'); do
        logging_installing_package "$LOG_FILE" "$PACKAGE"
        ( core_install "$PACKAGE" "$DIR_PACKAGES" "$LOG_FILE" &&
                logging_package_installed "$LOG_FILE" "$PACKAGE" ) ||
            ( logging_install_failed "$LOG_FILE" "$PACKAGE" &&
                    error_install "$PACKAGE" "$LOG_FILE" )
    done
done

####
## Wrap Up
####

logging_complete "$LOG_FILE"
core_quit 0
