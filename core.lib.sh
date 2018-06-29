#########################
### XInstall Core Library
#########################

####
## Initialization / Destruction
####

# Performs XInstall General Initialization
# Mainly, puts us in a temporary directory so we don't screw with user files.
function core_init {
    pushd $(mktemp -d)
}

# Wraps things up and quits.
function core_quit {
    popd
    export EXIT_VAL=$1
    kill -s TERM $TOP_PID
}

####
## Dependencies and Requirements
####

# Checks if the script was run as root.  If not, this function fails.
function core_check_root {
    if [ $(id -u) == 0 ]; then
        return 0
    else
        return 1
    fi
}

# Checks if the user has base dependencies installed.  If not, this function fails.
function core_check_depends_base {
    local DEPENDENCIES="zenity"
    for DEPENDENCY in $DEPENDENCIES; do
        utility_package_installed $DEPENDENCY || return 1
    done
    
    return 0
}

# Checks if the user has operational dependencies installed.  If not, this function fails.
function core_check_depends_operational {
    local DEPENDENCIES="apt snap jq wget curl"
    for DEPENDENCY in $DEPENDENCIES; do
        utility_package_installed $DEPENDENCY || return 1
    done
    
    return 0
}

####
## Group and Package Operations
####

# Reads the groups from the provided directory.
function core_read_groups {
    local RAW=`(find $1 -name *.json || return 1)`
    local XGROUPS=""
    for ITEM in $RAW; do
        local FILE=$(basename "${ITEM%.*}")
        if [ "$XGROUPS" == "" ]; then
            XGROUPS="$FILE"
        else
            XGROUPS="$XGROUPS $FILE"
        fi
    done
    
    echo $XGROUPS
    return 0
}

# Prompts the user to select groups from the provided list.
function core_select_groups {
    local COMMAND="zenity --title 'XInstall: Select Groups' --width=600 --height=400 --list --text 'Select groups for installation.' --checklist --column Pick --column Group --column Description"
    for GROUP in $1; do
        local DESCRIPTION=`cat "$2/$GROUP.json" | jq -re '.description'` || return 1
        COMMAND="$COMMAND FALSE \"$GROUP\" \"$DESCRIPTION\""
    done
    
    local SELECTED=`eval $COMMAND`
    echo $SELECTED
    
    return 0
}

# Selects packages out of a group to install.
function core_select_packages {
    local COMMAND="zenity --title 'XInstall: Select Packages ($1)' --width=600 --height=400 --list --text 'Select packages to install.' --checklist --column Pick --column Package --column Description"
    local PACKAGES=`cat "$2/$1.json" | jq -rec '.packages'` || return 1
    PACKAGES=`utility_extract_json_array "$PACKAGES" "|||"`
    for PACKAGE in $(echo $PACKAGES | sed 's/|||/\n/g'); do
        local DESCRIPTION=`cat "$3/$PACKAGE" | jq -re '.description'` || return 1
        COMMAND="$COMMAND TRUE \"${PACKAGE%.*}\" \"$DESCRIPTION\""
    done
    
    local SELECTED=`eval $COMMAND`
    echo $SELECTED
    
    return 0
}

####
## Install Operations
####

# Executes a list of commands based on a delimiter
function core_internal_execute_list {
    IFS=$'\n' # HACKY
    for COMMAND in $(echo "$1" | sed "s/$2/\n/g"); do
        COMMAND=`echo "$COMMAND" | sed 's/\\\"/"/g'` # a little pruning because JSON
        unset IFS # HACKY
        eval "$COMMAND" || return 1
        IFS=$'\n' # HACKY
    done
    unset IFS # HACKY
    
    return 0
}

# Detects if the install / remove mode is valid.  If not, this function fails.
function core_internal_validate_mode {
    case $1 in
        apt)
            ;;
        snap)
            ;;
        *)
            return 1
            ;;
    esac
    
    return 0
}

# Check for a pre-execute group in the provided package file and execute it if present.
function core_op_pre_exec {
    local COMMANDS=`cat "$2/$1.json" | jq -rec '.["pre-exec"]'`
    if [ "$COMMANDS" == "null" ]; then return 0; fi
    COMMANDS=`utility_extract_json_array "$COMMANDS" "|||"`
    
    local COUNT=`utility_count_items "$COMMANDS" "|||"`
    logging_operation "$3" "[pre-exec] Executing $COUNT instructions."
    
    core_internal_execute_list "$COMMANDS" "|||" || return 1
    return 0
}

# Check for a remove group in the provided package and remove the listed targets.
function core_op_remove {
    local MODE=`cat "$2/$1.json" | jq -rec '.remove.mode'`
    if [ "$MODE" == "null" ]; then return 0; fi
    core_internal_validate_mode "$MODE" || return 1
    
    local TARGETS=`cat "$2/$1.json" | jq -rec '.remove.targets'` || return 1
    TARGETS=`utility_extract_json_array "$TARGETS" "|||"`
    local COUNT=`utility_count_items "$TARGETS" "|||"`
    logging_operation "$3" "[remove] Removing $COUNT targets of type '$MODE'."
    
    for TARGET in $(echo $TARGETS | sed 's/|||/\n/g'); do
        case $MODE in
            apt)
                apt autoremove -y "$TARGET" || return 1
                ;;
            snap)
                snap remove "$TARGET" || return 1
                ;;
        esac
    done
    
    return 0
}

# Check for a ppa group in the provided package and add the listed repositories, updating afterwards.
function core_op_ppa {
    local PPAS=`cat "$2/$1.json" | jq -rec '.ppa'`
    if [ "$PPAS" == "null" ]; then return 0; fi
    PPAS=`utility_extract_json_array "$PPAS" "|||"`
    
    local COUNT=`utility_count_items "$PPAS" "|||"`
    logging_operation "$3" "[ppa] Adding $COUNT ppa repositories."
    
    for PPA in $(echo $PPAS | sed 's/|||/\n/g'); do
        add-apt-repository -y "$PPA" ||
            ( add-apt-repository -y --remove "$PPA" && return 1 )
    done
    
    return 0
}

# Check for an execute group in the provided package file and execute it if present.
function core_op_exec {
    local COMMANDS=`cat "$2/$1.json" | jq -rec '.exec'`
    if [ "$COMMANDS" == "null" ]; then return 0; fi
    COMMANDS=`utility_extract_json_array "$COMMANDS" "|||"`
    
    local COUNT=`utility_count_items "$COMMANDS" "|||"`
    logging_operation "$3" "[exec] Executing $COUNT instructions."
    
    core_internal_execute_list "$COMMANDS" "|||" || return 1
    return 0
}

# Check for an install group in the provided package and install the listed targets.
function core_op_install {
    local MODE=`cat "$2/$1.json" | jq -rec '.install.mode'`
    if [ "$MODE" == "null" ]; then return 0; fi
    core_internal_validate_mode "$MODE" || return 1
    
    local TARGETS=`cat "$2/$1.json" | jq -rec '.install.targets'` || return 1
    TARGETS=`utility_extract_json_array "$TARGETS" "|||"`
    local COUNT=`utility_count_items "$TARGETS" "|||"`
    logging_operation "$3" "[install] Installing $COUNT targets of type '$MODE'."
    
    IFS=$'\n' # HACKY
    for TARGET in $(echo $TARGETS | sed 's/|||/\n/g'); do
        unset IFS # HACKY
        case "$MODE" in
            apt)
                apt install -y $TARGET || return 1
                ;;
            snap)
                snap install $TARGET || return 1
                ;;
        esac
        IFS=$'\n' # HACKY
    done
    unset IFS # HACKY
    
    return 0
}

# Check for a post-execute group in the provided package file and execute it if present.
function core_op_post_exec {
    local COMMANDS=`cat "$2/$1.json" | jq -rec '.["post-exec"]'`
    if [ "$COMMANDS" == "null" ]; then return 0; fi
    COMMANDS=`utility_extract_json_array "$COMMANDS" "|||"`
    
    local COUNT=`utility_count_items "$COMMANDS" "|||"`
    logging_operation "$3" "[post-exec] Executing $COUNT instructions."
    
    core_internal_execute_list "$COMMANDS" "|||" || return 1
    return 0
}

# Installs a package.
function core_install {
    core_op_pre_exec "$1" "$2" "$3" || return 1
    core_op_remove "$1" "$2" "$3" || return 1
    core_op_ppa "$1" "$2" "$3" || return 1
    core_op_exec "$1" "$2" "$3" || return 1
    core_op_install "$1" "$2" "$3" || return 1
    core_op_post_exec "$1" "$2" "$3" || return 1
}
