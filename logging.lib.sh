############################
### XInstall Logging Library
############################

####
## Internal
####

# Performs the actual logging.
function logging_internal {
    echo === LOG === : "$2"
    echo "$2" >> "$1"
}

####
## Initialization / Destruction
####

# Initalizes the logging file.
function logging_init {
    logging_internal "$1" "XInstall - Installing ALL the things!"
    logging_internal "$1" "Installation began on: $2"
}

# Finalizes the logging.
function logging_complete {
    logging_internal "$1" "Installation complete at: `date`"
}

####
## Dependencies and Requirements
####

# Message logged when user has root.
function logging_has_root {
    logging_internal "$1" "User is root."
}

# Message logged when user does not have root.
function logging_not_root {
    logging_internal "$1" "User is NOT root. (ERROR)"
}

# Message logged when user has base dependencies.
function logging_has_depends_base {
    logging_internal "$1" "User has base dependencies."
}

# Message logged when user does not have base dependencies.
function logging_missing_depends_base {
    logging_internal "$1" "User does NOT have base dependencies. (ERROR)"
}

# Message logged when user has operational dependencies.
function logging_has_depends_operational {
    logging_internal "$1" "User has operational dependencies."
}

# Message logged when user does not have operational dependencies.
function logging_missing_depends_operational {
    logging_internal "$1" "User does NOT have operational dependencies. (ERROR)"
}

####
## Group and Package Operations
####

# Message logged when the application fails to read groups.
function logging_no_groups_read {
    logging_internal "$1" "Failed to read group JSON files. (ERROR)"
}

# Message logged when the application reads in groups.
function logging_read_groups {
    logging_internal "$1" "Found the following groups:"
    for GROUP in $2; do
        logging_internal "$1" "    $GROUP"
    done
}

# Message logged when the user selects groups.
function logging_groups_selected {
    logging_internal "$1" "User selected groups:"
    for GROUP in $(echo $2 | sed 's/|/\n/g'); do
        logging_internal "$1" "    $GROUP"
    done
}

# Message logged when the user selects packages in a group.
function logging_packages_selected {
    logging_internal "$1" "User selected packages from group '$2':"
    for PACKAGE in $(echo $3 | sed 's/|/\n/g'); do
        logging_internal "$1" "    $PACKAGE"
    done
}

# Message logged when a package is about to be installed.
function logging_installing_package {
    logging_internal "$1" "Installing package: $2"
}

# Message logged when a package is successfully installed
function logging_package_installed {
    logging_internal "$1" "    [success] Package installed: $2"
}

####
## Install Operations
####

# Messages logged by package operations.
function logging_operation {
    logging_internal "$1" "    $2"
}

# Message logged when a package installation fails.
function logging_install_failed {
    logging_internal "$1" "    [failure] Failed to install package: $2"
}
