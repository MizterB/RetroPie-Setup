#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="mame"
rp_module_desc="MAME Standalone - Full Binary (Latest Release)"
rp_module_help="ROM Extension: .zip\n\nCopy your MAME roms to either $romdir/mame or\n$romdir/arcade"
rp_module_licence="GPL2 https://raw.githubusercontent.com/mamedev/mame/master/LICENSE.md"
rp_module_section="exp"
rp_module_flags="!mali !kms"

#function _update_hook_mame() {
#
#}

# Directories created through the build process
function _get_base_directories_mame() {
    local directories=(
        'artwork'
        'bgfx'
        'ctrlr'
        'hash'
        'hlsl'
        'ini'
        'language'
        'keymaps'
        'plugins'
        'samples'
        'web'
    )
    echo ${directories[@]}
}

# Directories referred to in mame.ini that aren't created by the build process
function _get_additional_directories_mame() {
    local directories=(
        'cheat'
        'crosshair'
        'language'
        'cfg'
        'nvram'
        'input'
        'state'
        'snapshot'
        'diff'
        'comment'
        'hi'
    )
    echo ${directories[@]}
}

function _get_params_mame() {
    local params=(TARGET=mame SUBTARGET=mame)
    isPlatform "64bit" && params+=(PTR64=1)
    echo "${params[@]}"
}

function depends_mame() {
    # TODO: Choose libfontconfig-dev or libfontconfig1-dev, depending on OS version
    local depends=(libsdl2-dev libsdl2-ttf-dev libfontconfig1-dev qt5-default)
    getDepends "${depends[@]}"
}

function sources_mame() {
    gitPullOrClone "$md_build" https://github.com/mamedev/mame.git
}

function build_mame() {
    local params=$(_get_params_mame)
    make clean
    make
}

function install_mame() {
    md_ret_files=(
        'README.md'
        'LICENSE.md'
        $(_get_base_directories_mame)
    )
    if isPlatform "64bit"; then
        md_ret_files+=('mame64')
    else
        md_ret_files+=('mame')
    fi
}

function configure_mame() {
    mkRomDir "arcade"
    mkRomDir "arcade/$md_id"
    mkRomDir "$md_id"

    mkUserDir "$home/.mame"

    local mame_binary="mame"
    isPlatform "64bit" && mame_binary="mame64"

    if [[ "$md_mode" == "install" ]]; then
        local mame_basedir
        for mame_basedir in $(_get_base_directories_mame); do
            # Only move the directory if it doesn't already exist
            # so we don't overwrite customizations that were prepopulated
            if [[ ! -d "$md_conf_root/$md_id/$mame_basedir" ]]; then
                moveConfigDir "$md_inst/$mame_basedir" "$md_conf_root/$md_id/$mame_basedir"
            fi
        done

        local mame_addldir
        for mame_addldir in $(_get_additional_directories_mame); do
            mkUserDir "$md_conf_root/$md_id/$mame_addldir"
        done
    fi

    if [[ "$md_mode" == "install" && ! -f "$md_conf_root/$md_id/mame.ini" ]]; then

        su "$user" -c "cd "$home/.mame"; $md_inst/$mame_binary -createconfig"
        moveConfigDir "$home/.mame" "$md_conf_root/$md_id"

        iniConfig " " "" "$md_conf_root/$md_id/mame.ini"
        iniSet "homepath" "$md_conf_root/$md_id"
        iniSet "rompath" "$romdir/$md_id;$romdir/arcade"
        iniSet "hashpath" "$md_conf_root/$md_id/hash"
        iniSet "samplepath" "$md_conf_root/$md_id/samples"
        iniSet "artpath" "$md_conf_root/$md_id/artwork"
        iniSet "ctrlrpath" "$md_conf_root/$md_id/ctrlr"
        iniSet "inipath" "$md_conf_root/$md_id"
        iniSet "fontpath" "$md_conf_root/$md_id"
        iniSet "cheatpath" "$md_conf_root/$md_id/cheat"
        iniSet "crosshairpath" "$md_conf_root/$md_id/crosshair"
        iniSet "pluginspath" "$md_conf_root/$md_id/plugins"
        iniSet "languagepath" "$md_conf_root/$md_id/language"
        iniSet "swpath" "$romdir/$md_id;$romdir/arcade"

        iniSet "cfg_directory" "$md_conf_root/$md_id/cfg"
        iniSet "nvram_directory" "$md_conf_root/$md_id/nvram"
        iniSet "input_directory" "$md_conf_root/$md_id/inp"
        iniSet "state_directory" "$md_conf_root/$md_id/sta"
        iniSet "snapshot_directory" "$md_conf_root/$md_id/snap"
        iniSet "diff_directory" "$md_conf_root/$md_id/diff"
        iniSet "comment_directory" "$md_conf_root/$md_id/comments"

        iniSet "http_root" "$md_conf_root/$md_id/web"
        iniSet "bgfx_path" "$md_conf_root/$md_id/bgfx"

        iniSet "hiscore_directory" "$md_conf_root/$md_id/hi"

        iniSet "skip_gameinfo" "1"
    fi

    addEmulator 1 "$md_id" "arcade" "$md_inst/$mame_binary %BASENAME%"
    addEmulator 1 "$md_id" "$md_id" "$md_inst/$mame_binary %BASENAME%"

    addSystem "arcade"
    addSystem "$md_id"
}