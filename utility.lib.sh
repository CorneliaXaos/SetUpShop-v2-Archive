############################
### XInstall Utility Library
############################

# Checks if the requested package is installed.  SPECIFICALLY APT PACKAGES.
function utility_package_installed {
    return `dpkg-query -l "$1" >/dev/null 2>/dev/null`
}

# "Extracts" a json array to something bash can handle.
# Parameter 1 is the JSON array.  Parameter 2 is the desired delimiter.
function utility_extract_json_array {
    local RAW=$1
    RAW=${RAW//[\"/}
    RAW=${RAW//\"]}
    RAW=${RAW//\",\"/$2}
    echo $RAW
}

# Counts the items in an array
function utility_count_items {
    echo $1 | sed "s/$2/\n/g" | wc -l
}
