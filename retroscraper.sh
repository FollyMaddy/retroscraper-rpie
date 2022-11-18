#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="retroscraper"
rp_module_desc="Scraper for EmulationStation by kiro"
rp_module_licence="GNU https://github.com/zayamatias/retroscraper-rpie/blob/main/LICENSE"
rp_module_repo="git https://github.com/zayamatias/retroscraper-rpie.git main"
rp_module_section="opt"

function depends_retroscraper() {
    local depends=(python3)
}

function sources_retroscraper() {
    gitPullOrClone
}

function build_retroscraper() {
 su $user "$md_build/setup.sh" $md_build
}

function install_retroscraper() {
    md_ret_files=(
    'apicalls.py'
        'checksums.py'
        'LICENSE'
        'README.md'
        'dependencies.txt'
        'retroscraper.py'
        'scrapfunctions.py'
    'setup.sh'
    )
}

function remove_retroscraper() {
    rp_callModule golang remove
}

function get_ver_retroscraper() {
    [[ -f "$md_inst/scraper" ]] && "$md_inst/scraper" -version 2>/dev/null
}

function latest_ver_retroscraper() {
    download https://api.github.com/repos/zayamatias/retroscraper-rpie/releases/latest - | grep -m 1 tag_name | cut -d\" -f4
}

function list_systems_retroscraper() {
    su $user -c "python3 $md_inst/retroscraper.py --listsystems"
}
function scrape_retroscraper() {
    local system="$1"
#    echo $system

    [[ -z "$system" ]] && return

    iniConfig " = " '"' "$configdir/all/scraper.cfg"
    eval $(_load_config_retroscraper)

    local params="--systems $system"


    if [[ "$nobackup" -eq 1 ]]; then
        params+=(--nobackup)
    fi

    if [[ "relativepaths" -eq 1 ]]; then
        params+=(--relativepaths)
    fi

    if [[ "$keepdata" -eq 1 ]]; then
        params+=(--keepdata)
    fi

    if [[ "$preferbox" -eq 1 ]]; then
        params+=(--preferbox)
    fi

    if [[ "$novideodown" -eq 1 ]]; then
        params+=(--novideodown)
    fi

    if [[ "$country" -eq 1 ]]; then
        params+=(--country)
    fi

    if [[ "$disk" -eq 1 ]]; then
        params+=(--disk)
    fi

    if [[ "$version" -eq 1 ]]; then
        params+=(--version)
    fi

    if [[ "$hack" -eq 1 ]]; then
        params+=(--hack)
    fi

    if [[ "$brackets" -eq 1 ]]; then
        params+=(--brackets)
    fi

    if [[ "$bezels" -eq 1 ]]; then
        params+=(--bezels)
    fi

    if [[ "$sysbezels" -eq 1 ]]; then
        params+=(--sysbezels)
    fi
    
        if [[ "$cleanmedia" -eq 1 ]]; then
        params+=(--cleanmedia)
    fi

    # trap ctrl+c and return if pressed (rather than exiting retropie-setup etc)
    trap 'trap 2; return 1' INT
    #echo "su $user -c python3 -u $md_inst/retroscraper.py ${params[@]}" >/tmp/test.txt
    sudo -u $user python3 -u $md_inst/retroscraper.py ${params[@]}
    trap 2
}

function scrape_all_retroscraper() {
    trap 'trap 2; return 1' INT
    su $user -c "python3 -u $md_inst/retroscraper.py"
    trap 2
}

function scrape_chosen_retroscraper() {
    local options=()
    local system
    local i=1
    while read system; do
        system=${system/$romdir\//}
        options+=($i "$system" OFF)
        ((i++))
    done < <(list_systems_retroscraper)

    if [[ ${#options[@]} -eq 0 ]] ; then
        printMsgs "dialog" "No populated rom folders were found in $romdir."
        return
    fi

    local cmd=(dialog --backtitle "$__backtitle" --checklist "Select ROM Folders" 22 76 16)
    local choice=($("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty))

    [[ ${#choice[@]} -eq 0 ]] && return

    local choices
    for choice in "${choice[@]}"; do
        choices+="${options[choice*3-2]},"
    done
    scrape_retroscraper "$choices" "$@"
}

function _load_config_retroscraper() {
    echo "$(loadModuleConfig \
        'use_thumbs=1' \
        'screenshots=0' \
        'max_width=400' \
        'max_height=400' \
        'console_src=1' \
        'mame_src=2' \
        'rom_name=0' \
        'append_only=0' \
        'use_rom_folder=0' \
        'download_videos=0' \
        'download_marquees=0' \
    )"
}

function gui_retroscraper() {
    if pgrep "emulationstatio" >/dev/null; then
        printMsgs "dialog" "This scraper must not be run while Emulation Station is running or the scraped data will be overwritten. \n\nPlease quit from Emulation Station, and run RetroPie-Setup from the terminal"
        return
    fi

    iniConfig " = " '"' "$configdir/all/scraper.cfg"
    eval $(_load_config_retroscraper)
    chown $user:$user "$configdir/all/scraper.cfg"

    local default
    while true; do
        local ver=$(get_ver_retroscraper)
        [[ -z "$ver" ]] && ver="v(Git)"
        local cmd=(dialog --backtitle "$__backtitle" --default-item "$default" --menu "RetroScraper $ver by kiro" 22 76 16)
        local options=(
            1 "Scrape all systems"
            2 "Scrape chosen systems"
        )

        if [[ "$nobackup" -eq 1 ]]; then
            options+=(3 "Do not backup gamelists")
        else
            options+=(3 "Backup gamelists")
        fi

        if [[ "$relativepaths" -eq 0 ]]; then
            options+=(4 "Use absolute paths in gamelists")
        else
            options+=(4 "Use relative paths in gamelists")
        fi

        if [[ "$keepdata" -eq 0 ]]; then
            options+=(5 "Discard last played/favorite data")
        else
            options+=(5 "Keep last played/favorite data")
        fi

        if [[ "$preferbox" -eq 0 ]]; then
            options+=(6 "Prefer screenshot as images")
        else
            options+=(6 "Prefer boxes as images")
        fi

        if [[ "$novideodown" -eq 0 ]]; then
            options+=(7 "Download videos")
        else
            options+=(7 "Do not download videos")
        fi

        if [[ "$country" -eq 0 ]]; then
            options+=(8 "Do not add country decorator from filename")
        else
            options+=(8 "Add country decorator from filename")
        fi

        if [[ "$disk" -eq 0 ]]; then
            options+=(9  "Do not add disk decorator from filename")
        else
            options+=(9 "Add disk decorator from filename")
        fi

        if [[ "$version" -eq 0 ]]; then
            options+=(A "Do not add version decorator from filename")
        else
            options+=(A "Add version decorator from filename")
        fi

        if [[ "$hack" -eq 0 ]]; then
            options+=(B  "Do not add hack decorator from filename")
        else
            options+=(B "Add hack decorator from filename")
        fi

        if [[ "$brackets" -eq 0 ]]; then
            options+=(C  "Do not add info between brackets [] decorator from filename")
        else
            options+=(C  "Add info between brackets [] decorator from filename")
        fi
        if [[ "$bezels" -eq 0 ]]; then
            options+=(D  "Do not download Bezels for games")
        else
            options+=(D  "Download Bezels for games")
        fi
        if [[ "$sysbezels" -eq 0 ]]; then
            options+=(E  "Do not download system bezel if no game bezel found")
        else
            options+=(E  "Download system bezel if no game bezel found")
        fi
        if [[ "$cleanmedia" -eq 0 ]]; then
            options+=(F  "Do not delete existing media")
        else
            options+=(F  "Delete existing media")
        fi

        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ -n "$choice" ]]; then
            default="$choice"
            case "$choice" in
                1)
                    if scrape_all_retroscraper; then
                        printMsgs "dialog" "ROMS have been scraped."
                    else
                        printMsgs "dialog" "Scraping was aborted"
                    fi
                    ;;
                2)
                    if scrape_chosen_retroscraper; then
                        printMsgs "dialog" "ROMS have been scraped."
                    else
                        printMsgs "dialog" "Scraping was aborted"
                    fi
                    ;;
                3)
                    nobackup="$((nobackup ^ 1))"
                    iniSet "nobackup" "$nobackup"
                    ;;
                4)
                    relativepaths="$((relativepaths ^ 1))"
                    iniSet "relativepaths" "$relativepaths"
                    ;;
                5)
                    keepdata="$((keepdata ^1))"
                    iniSet "keepdata" "$keepdata"
                    ;;
                6)
                    preferbox="$((preferbox ^ 1))"
                    iniSet "preferbox" "$preferbox"
                    ;;
                7)
                    novideodown="$((novideodown ^ 1))"
                    iniSet "novideodown" "$novideodown"
                    ;;
                8)
                    country="$((country ^ 1))"
                    iniSet "country" "$country"
                    ;;
                9)
                    disk="$((disk ^ 1))"
                    iniSet "disk" "$disk"
                    ;;
                A)
                    version="$((version ^ 1))"
                    iniSet "version" "$version"
                    ;;
                B)
                    hack="$((hack ^ 1))"
                    iniSet "hack" "$hack"
                    ;;
                C)
                    brackets="$((brackets ^ 1))"
                    iniSet "brackets" "$brackets"
                    ;;
                D)
                    bezels="$((bezels ^ 1))"
                    iniSet "bezels" "$bezels"
                    ;;
                E)
                    sysbezels="$((sysbezels ^ 1))"
                    iniSet "sysbezels" "$sysbezels"
                    ;;
                F)
                    cleanmedia="$((cleanmedia ^ 1))"
                    iniSet "cleanmedia" "$cleanmedia"
                    ;;

            esac
        else
            break
        fi
    done
}
