#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="retrofe"
rp_module_desc="RetroFE emulator frontend"
rp_module_licence="GPL3 https://bitbucket.org/phulshof/retrofe/raw/default/LICENSE.txt"
rp_module_section="exp"
rp_module_flags="frontend"

#
# The directory containing RetroFE config files
#
function _get_configdir_retrofe() {
    echo "$configdir/all/retrofe"
}

#
# Location of the shell script wrapper for the RetroFE binary.  Puts RetroFE 
# in the user's path.  Same approach used by EmulationStation.
# See @install_wrapper_retrofe
# 
#
function _get_wrapper_retrofe() {
    echo "/usr/bin/retrofe"
}

#
# This is invoked by the retropie_setup script whenever installed
# packages are updated.  It does not appear to be called when the RetroFE
# package is updated individually.
#
function _update_hook_retrofe() {
	echo "Running the update hook for RetroFE"
    # This only appears to run when executing the global update script,
    # not when only updating this individual module from source
    if rp_isInstalled "$md_idx"; then
        return
    fi
}

#
# This is invoked by the retropie_setup script when a new system is enabled
# through the installation of a particular emulator.
# 
# TODO: Add logic to support RetroFE
#
function _add_system_retrofe() {
    echo "Adding system: $1 ($2) to RetroFE"
    local retrofe_dir="$md_inst"
    [[ ! -d "$retrofe_dir" || ! -f /usr/bin/retrofe ]] && return 0

    local fullname="$1"
    local name="$2"
    local path="$3"
    local extensions="$4"
    local command="$5"
    local platform="$6"
    local theme="$7"
    
    # Create a collection directory based on the platform name
    mkdir -pf "$retrofe_dir/collections/$platform"
    
    # Create a launcher
    
    # Create an info file
}

#
# This is invoked by the retropie_setup script when a system is disabled
# through the removal of a particular emulator.
#
# TODO: Add logic to support RetroFE
#
function _del_system_retrofe() {
	echo "Deleting system: $1 ($2) from RetroFE"
    local retrofe_dir="$md_inst"
    [[ ! -d "$retrofe_dir" ]] && return 0

    local fullname="$1"
    local name="$2"
}

#
# This is invoked by the retropie_setup script when a new rom is added
# to a system.  Used to build the gamelist.xml files for EmulationStation.
#
# TODO: Add logic to support RetroFE
#
function _add_rom_retrofe() {
    echo "Adding rom: $1 ($2): $4 to RetroFE"
    local retrofe_dir="$md_inst"
    [[ ! -d "$retrofe_dir" ]] && return 0

    local system_name="$1"
    local system_fullname="$2"
    local path="$3"
    local name="$4"
    local desc="$5"
    local image="$6"
}

#
# Creates a shell script that wraps the RetroFE binary, which should be the 
# primary entry point into launching the frontend.  Uses the same approach and 
# logic as EmulationStation.  Could be used to perform some config/setup 
# validations prior to launch.
#
function install_wrapper_retrofe() {
    echo "Installing the wrapper script for the RetroFE binary at $(_get_wrapper_retrofe)"
    cat > $(_get_wrapper_retrofe) << _EOF_
#!/bin/bash
source "$scriptdir/scriptmodules/inifuncs.sh"

if [[ \$(id -u) -eq 0 ]]; then
    echo "retrofe should not be run as root. If you used 'sudo retrofe' please run without sudo."
    exit 1
fi

# save current tty/vt number for use with X so it can be launched on the correct tty
tty=\$(tty)
export TTY="\${tty:8:1}"

# point to the retropie install directory for retrofe
export RETROFE_PATH="$md_inst"

clear
tput civis
"$md_inst/retrofe" "\$@"
tput cnorm
_EOF_

    chmod +x $(_get_wrapper_retrofe)
}

#
# Creates RetroFE launchers for all available systems in RetroPie, as defined in
# the platforms.cfg files.
#
# TODO: Add to update hook?
#
function install_launchers_retrofe() {
    echo "Installing RetroFE launchers for runcommand.sh"
    # Open the two platform files and iterate on their entries
    for platcfg in "$configdir/all/platforms.cfg" "$scriptdir/platforms.cfg"; do
    	if [ ! -f $platcfg ]; then continue; fi
		grep "_exts=" $platcfg | while read -r line; do 
			platform=$(echo "$line" | cut -d'_' -f 1)
			# Don't modify any launchers that already exist
			if [ -f "$md_inst/launchers/$platform.conf" ]; then continue; fi
			cat > "$md_inst/launchers/$platform.conf" << _EOF_
executable = $rootdir/supplementary/runcommand/runcommand.sh
arguments = 0 _SYS_ $platform "%ITEM_FILEPATH%"
_EOF_
		done    
    done
    
    # Create launchers for alias systems (ie. genesis = megadrive)
    cp "$md_inst/launchers/megadrive.conf" "$md_inst/launchers/genesis.conf"
}

#
# Configure keyboard and joystick/gamepad controls for RetroFE.
# If EmulationStation & RetroArch inputs have already been configured,
# apply those same configs to RetroFE.
#
# TODO: Implement control mapping (just a placeholder for now)
#
function configure_controls_retrofe() {
    echo "Configuring controls for RetroFE"
    local controls="$md_inst/controls.conf"
}

#
# Creates a custom RetroFE collection for RetroPie menu utilities
#
# TODO: Include icons for items that dont have them (Restart, Shutdown, ??...)
# TODO: Use xmlstarlet to process the ES gamelist.xml file for these utilities and populate the list dynamically
# TODO: Add to update hook?
#
function install_retropie_collection_retrofe() {
    echo "Installing the RetroPie collection"
	local rpcollname="retropiemenu"
	local rpcolldir="$md_inst/collections/$rpcollname"
	
	# Don't install the RetroPie Setup collection if it already exists
	[[ -f "$rpcolldir" ]] && return 0
	
	su -c "$md_inst/retrofe -createcollection $rpcollname" $user
	echo "sudo $scriptdir/retropie_packages.sh retropiemenu launch $datadir/retropiemenu/bluetooth.rp" >> "$rpcolldir/roms/Bluetooth.sh"
	echo "sudo $scriptdir/retropie_packages.sh retropiemenu launch $datadir/retropiemenu/configedit.rp" >> "$rpcolldir/roms/Configuration Editor.sh"
	echo "sudo $scriptdir/retropie_packages.sh retropiemenu launch $datadir/retropiemenu/filemanager.rp" >> "$rpcolldir/roms/File Manager.sh"
	echo "sudo $scriptdir/retropie_packages.sh retropiemenu launch $datadir/retropiemenu/retroarch.rp" >> "$rpcolldir/roms/RetroArch Setup.sh"
	echo "sudo $scriptdir/retropie_packages.sh retropiemenu launch $datadir/retropiemenu/retronetplay.rp" >> "$rpcolldir/roms/RetroArch Netplay.sh"
	echo "sudo $scriptdir/retropie_packages.sh retropiemenu launch $datadir/retropiemenu/rpsetup.rp" >> "$rpcolldir/roms/RetroPie Setup.sh"
	echo "sudo $scriptdir/retropie_packages.sh retropiemenu launch $datadir/retropiemenu/runcommand.rp" >> "$rpcolldir/roms/RunCommand.sh"
	echo "sudo $scriptdir/retropie_packages.sh retropiemenu launch $datadir/retropiemenu/showip.rp" >> "$rpcolldir/roms/Show IP Address.sh"
	echo "sudo reboot" >> "$rpcolldir/roms/Reboot.sh"
	echo "sudo poweroff" >> "$rpcolldir/roms/Shutdown.sh"

    # RaspberryPi-specific tools
    if isPlatform "rpi"; then
	    echo "sudo $scriptdir/retropie_packages.sh retropiemenu launch $datadir/retropiemenu/audiosettings.rp" >> "$rpcolldir/roms/Audio Settings.sh"
	    echo "sudo $scriptdir/retropie_packages.sh retropiemenu launch $datadir/retropiemenu/wifi.rp" >> "$rpcolldir/roms/Configure Wifi.sh"
	    echo "sudo $scriptdir/retropie_packages.sh retropiemenu launch $datadir/retropiemenu/raspiconfig.rp" >> "$rpcolldir/roms/Raspberry Pi Setup.sh"
	    echo "sudo $scriptdir/retropie_packages.sh retropiemenu launch $datadir/retropiemenu/splashscreen.rp" >> "$rpcolldir/roms/Splash Screen.sh"    
    fi
    
	chmod +x "$rpcolldir/roms/"*.sh

	for artdir in "screenshot" "logo"; do
		cp "$datadir/retropiemenu/icons/audiosettings.png" "$rpcolldir/medium_artwork/$artdir/Audio Settings.png"
		cp "$datadir/retropiemenu/icons/bluetooth.png" "$rpcolldir/medium_artwork/$artdir/Bluetooth.png"
		cp "$datadir/retropiemenu/icons/configedit.png" "$rpcolldir/medium_artwork/$artdir/Configuration Editor.png"
		cp "$datadir/retropiemenu/icons/wifi.png" "$rpcolldir/medium_artwork/$artdir/Configure Wifi.png"
		cp "$datadir/retropiemenu/icons/filemanager.png" "$rpcolldir/medium_artwork/$artdir/File Manager.png"
		cp "$datadir/retropiemenu/icons/raspiconfig.png" "$rpcolldir/medium_artwork/$artdir/Raspberry Pi Setup.png"
		cp "$datadir/retropiemenu/icons/retroarch.png" "$rpcolldir/medium_artwork/$artdir/RetroArch Setup.png"
		cp "$datadir/retropiemenu/icons/retronetplay.png" "$rpcolldir/medium_artwork/$artdir/RetroArch Netplay.png"
		cp "$datadir/retropiemenu/icons/rpsetup.png" "$rpcolldir/medium_artwork/$artdir/RetroPie Setup.png"
		cp "$datadir/retropiemenu/icons/runcommand.png" "$rpcolldir/medium_artwork/$artdir/RunCommand.png"
		cp "$datadir/retropiemenu/icons/showip.png" "$rpcolldir/medium_artwork/$artdir/Show IP Address.png"
		cp "$datadir/retropiemenu/icons/splashscreen.png" "$rpcolldir/medium_artwork/$artdir/Splash Screen.png"
	done
	
	convert -background none "/etc/emulationstation/themes/carbon/retropie/art/system.svg" "$rpcolldir/system_artwork/logo.png"
	cp "$datadir/retropiemenu/icons/rpsetup.png" "$rpcolldir/system_artwork/device.png"
	
	cat > "$rpcolldir/info.conf" << _EOF_
lb_manufacturer = RetroPie
manufacturer    = Configuration Settings
_EOF_

	cat > "$rpcolldir/system_artwork/story.txt" << _EOF_
Configuration settings for RetroPie
_EOF_

	cat > "$rpcolldir/settings.conf" << _EOF_
list.path = $rpcolldir/roms
list.extensions = sh
launcher = $rpcollname
_EOF_

	cat > "$md_inst/launchers/$rpcollname.conf" << _EOF_
executable = /bin/bash
arguments = "%ITEM_FILEPATH%"
_EOF_

    # Add this collection to the Main menu
    if ! grep -qe "^$rpcollname" "$md_inst/collections/Main/menu.txt"; then
        echo "$rpcollname" >> "$md_inst/collections/Main/menu.txt"
    fi
    
    # For future use...parsing the ES gamelist.xml file
    #xmlstarlet sel -t -m "/gameList[*]/game/name" -v . -n ~/.emulationstation/gamelists/retropie/gamelist.xml
}

#
# Remap the default collections that ship with RetroFE to match the
# system naming convention used by RetroPie
#
# TODO: Update CREATING_COLLECTIONS.txt with instructions specific to RetroPie
#
function remap_default_collections_retrofe() {
    echo "Reconfiguring RetroFE default collections for RetroPie compatibility"
    
	# Rename the RetroFE default collections to match 
	# the RetroPie naming convention
	[[ -d "$md_inst/collections/Arcade" ]] && mv "$md_inst/collections/Arcade" "$md_inst/collections/arcade"
	[[ -d "$md_inst/collections/Sega Genesis" ]] && mv "$md_inst/collections/Sega Genesis" "$md_inst/collections/genesis"
	
	# Modify the RetroFE default collections to use new launchers based on
	# system name
	sed -i -e "s|^launcher.*=.*|launcher = arcade|" "$md_inst/collections/arcade/settings.conf"
	sed -i -e "s|^launcher.*=.*|launcher = genesis|" "$md_inst/collections/genesis/settings.conf"

    cp "$md_inst/launchers/megadrive.conf" "$md_inst/launchers/genesis.conf"
	
	# Edit the Main Menu to match the RetroPie naming convention
	sed -i -e "s|Sega Genesis|genesis|" "$md_inst/collections/Main/menu.txt"
	sed -i -e "s|Arcade|arcade|" "$md_inst/collections/Main/menu.txt"
	
	# If the user does not have Sega Genesis already set up in RetroPie, 
	# copy the sample rom file from the Sega Genesis collection into the genesis
	# roms directory so it can be used as a working example.
	# Ignore if other roms exist there, we don't want to impact existing setups. 
    if [ -z "$(ls -A $romdir/genesis)" ]; then
        echo "Moving sample rom to $romdir from RetroFE's Sega Genesis collection."
        mv -fv "$md_inst/collections/genesis/roms"/* "$romdir/genesis/"
        chown -R $user:$user "$romdir/genesis/"
    else
        echo "Existing roms found in $romdir/genesis.  Skipping move of sample rom from RetroFE's Sega Genesis collection."
    fi
    
    # Configure the genesis collection to use metadata for "Sega Genesis"
	echo >> "$md_inst/launchers/$rpcollname.conf" << _EOF_

###############################################################################
# The metadata system uses full system names ("Sega Genesis"), while RetroPie
# uses abbreviated ones ("genesis").  This config maps the collection back
# to the appropriate metatdata source.
###############################################################################
metadata.type = Sega Genesis
_EOF_
}

#
# Package dependency list used by the module installer
#
function depends_retrofe() {
    # Core build dependencies for RetroFE
    local depends=(
			tortoisehg g++ cmake dos2unix zlib1g-dev libsdl2-2.0-0 libsdl2-mixer-2.0-0 	libsdl2-image-2.0-0 libsdl2-ttf-2.0-0 
            libsdl2-dev libsdl2-mixer-dev libsdl2-image-dev libsdl2-ttf-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
            gstreamer1.0-libav zlib1g-dev libglib2.0-0 libglib2.0-dev sqlite3 gstreamer1.0-plugins-good gstreamer1.0-alsa
    )
    
    # Needed for creating icons in the RetroPie collection
    depends+=( imagemagick libmagickcore-6.q16-2-extra )
    
    # RaspberryPi-specific dependencies
    if isPlatform "rpi"; then
    	depends+=( )

    # Other platform (Ubuntu) dependencies
    else
    	depends+=( libgstreamer-plugins-good1.0-dev )
    fi
    
    getDepends "${depends[@]}" 
}

#
# RetroFE source file location used by the module installer 
#
function sources_retrofe() {
	hg clone https://phulshof@bitbucket.org/phulshof/retrofe "$md_build"
}

#
# RetroFE build command used by the module installer.
# Validates that the expected binary file was created after compilation
#
function build_retrofe() {
	cmake RetroFE/Source -BRetroFE/Build -DVERSION_MAJOR=0 -DVERSION_MINOR=0 -DVERSION_BUILD=0

	cmake --build RetroFE/Build
	python Scripts/Package.py --os=linux --build=full

    md_ret_require="$md_build/Artifacts/linux/RetroFE/retrofe"
}

#
# Installs RetroFE binary to /opt/retropie/supplementary/retrofe/
#
function install_retrofe() {
	mkUserDir "$md_inst"
	cp -r "$md_build/Artifacts/linux/RetroFE/"* "$md_inst"
    chown -R $user:$user "$md_inst"
}

#
# Deletes all RetroFE files from the system (wrapper, binary, configs)
#
function remove_retrofe() {
	rm -rfv "/usr/bin/retrofe"
    # Comment out the next line to leave the config directory intact - if don't 
    # want someone to mistakenly lose all that work & art
    rm -rfv "$(_get_configdir_retrofe)"
    rm -rfv "$md_inst"
}

#
# Perform configuration of RetroFE.  Wraps other helper functions in this 
# module to install the binary wrapper, install launchers, and setup the 
# initial collections.
#
# TODO: Confirm all conditions in which this function gets called
#
function configure_retrofe() {
	# Don't configure anything if removing RetroFE
	[[ "$mode" == "remove" ]] && return
	
	# Invoke helper functions
	install_wrapper_retrofe
	install_launchers_retrofe
	configure_controls_retrofe
	install_retropie_collection_retrofe
	remap_default_collections_retrofe
	
	touch "$md_inst/log.txt"
	
	# Update RetroFE's settings.conf to make it compatible with RetroPie
	sed -i -e "s/^fullscreen =.*/fullscreen = yes/" "$md_inst/settings.conf"
	sed -i -e "s|.*baseItemPath.*=.*|baseItemPath = $romdir|" "$md_inst/settings.conf"
	
	# Repair ownership, just in case
	chown -R $user:$user "$md_inst"
	
    # Move all of the supporting files and directories to the RetroPie 
    # config directory structure
    # These commands symlink from the module's install dir to the "config" dir
    mkUserDir "$(_get_configdir_retrofe)"
	moveConfigFile "$md_inst/settings.conf" "$(_get_configdir_retrofe)/settings.conf"
	moveConfigFile "$md_inst/controls.conf" "$(_get_configdir_retrofe)/controls.conf"
	moveConfigFile "$md_inst/meta.db" "$(_get_configdir_retrofe)/meta.db"
	moveConfigFile "$md_inst/log.txt" "$(_get_configdir_retrofe)/log.txt"
	moveConfigDir "$md_inst/collections" "$(_get_configdir_retrofe)/collections"
	moveConfigDir "$md_inst/layouts" "$(_get_configdir_retrofe)/layouts"
	moveConfigDir "$md_inst/launchers" "$(_get_configdir_retrofe)/launchers"
	moveConfigDir "$md_inst/meta" "$(_get_configdir_retrofe)/meta"
	moveConfigDir "$md_inst/collections" "$(_get_configdir_retrofe)/collections"
}








