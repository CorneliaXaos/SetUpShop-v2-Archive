# SetUpShop-v2-Archive

This repo is a (somewhat active, kinda) archive of an installation "script" that is most responsible for inspiring a more ambitious project I'm calling "Set Up Shop".  This particular archive is FUNCTIONAL (at least on Ubuntu) and EXTENSIBLE.  I may more may not accept pull requests that extend the archive of installable packages or adds features as I plan to make a more reasonable (read sane) version later that doesn't rely entirely on shell scripting and may even be portable enough to work on other Operating Systems besides Linux!  Don't hold your breath, though, I don't know when I'll get to it. :P

To see the devil that spawned this demonic script, take a look at [SetUpShop-v1-Archive.][1]  Eventually I'll have a link here to version 3 of the program.. which should no longer be a shell-script of DOOM.

## Usage

To use this script:

1. Clone this Repo to wherever you desire.
2. Navigate to the script using a terminal of your choice.
3. Give the main script file execution permissions: `chmod +x main.sh`
4. Run the script as root: `sudo ./main.sh`

Note that you will need to have a GUI environment in order to use the script as, while it is executed from the terminal, it uses a (hacked together) GUI to query the user for packages to install.  It's a strange setup but I made this thing in, like, 10 hours while hacking away in bash so....

## WARNING!!!

In order to use this script you **must** run it as root.  This means you should probably inspect what the packages you're installaing will actually DO before you install them as they can run arbitrary code as root.  This is usually executing installation instructions with the `apt` or `snap` commands but sometimes it does other things because apt and snap are insufficient.  So.. before you install any packages you don't trust.. INSPECT THEIR JSON FILES! (And read the indemnification clause in the license, yo..)

[1]: https://github.com/CorneliaXaos/SetUpShop-v1-Archive
