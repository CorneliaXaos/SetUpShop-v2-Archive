##########################
### XInstall Error Library
##########################

####
## Dependencies and Requirements
####

# Handles the error: User did not run as root.
function error_not_root {
    echo "XInstall needs to be ran as root!"
    core_quit 1
}

# Handles the error: User is missing the base dependencies.
function error_missing_depends_base {
    echo "You are missing some or all of the base dependencies."
    echo "Would you like to install them now?"
    select RESPONSE in "Yes" "No"; do
        case $RESPONSE in
            Yes)
                apt install -y zenity || ( echo Automatic install failed! && core_quit 2 )
                ;;
            No)
                core_quit 0
                ;;
        esac
    done
}

# Handles the error: User is missing the operation dependencies.
function error_missing_depends_operational {
    zenity --width=600 --height=400  --question --text "You are missing some or all of the operational dependencies. Would you like to install them now?" || core_quit 0
        
    apt install -y snapd jq curl ||
        (zenity --notification --text "Automatic install failed!" && core_quit 3)
}

####
## Group and Package Operations
####

# Handles the error: No groups found during read operation.
function error_no_groups {
    zenity --width=600 --height=400 --warning --text="XInstall was unable to find any groups to display and will now shutdown.  This is likely an error.  Please check the groups  directory and ensure groups are present."
    core_quit 4
}

# Handles the error: Failure to install package.
function error_install {
    ( zenity --width=600 --height=400 --question --text="XInstall failed to install the package '$1'.  Would you like to stop the installation process?  (If not, XInstall will skip this package and move on.)" &&
        core_quit 5 ) || logging_operation "$2" "[skip] This package has been skipped by the user due to error."
}
