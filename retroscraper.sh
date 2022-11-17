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

#    local gamelist
#    local img_dir
#    local img_path
#    if [[ "$use_rom_folder" -eq 1 ]]; then
#        gamelist="$romdir/$system/gamelist.xml"
#        img_dir="$romdir/$system/images"
#        img_path="./images"
#    else
#        gamelist="$home/.emulationstation/gamelists/$system/gamelist.xml"
#        img_dir="$home/.emulationstation/downloaded_images/$system"
#        img_path="~/.emulationstation/downloaded_images/$system"
#    fi

    local params="--systems $system"

    #params+=(-image_dir "$img_dir")
    #params+=(-image_path "$img_path")
    ##params+=(-video_dir "$img_dir")
    #params+=(-video_path "$img_path")
    #params+=(-marquee_dir "$img_dir")
    #params+=(-marquee_path "$img_path")
    #params+=(-output_file "$gamelist")
    #params+=(-rom_dir "$romdir/$system")
    #params+=(-workers "4")
    #params+=(-skip_check)

   # [[ "$system" =~ ^mame-|arcade|fba|neogeo ]] && params+=(-mame)

#    if [[ "$use_thumbs" -eq 1 ]]; then
#        params+=(-thumb_only)
#    fi
#    if [[ "$screenshots" -eq 1 ]]; then
#        if [[ "$system" =~ ^mame-|arcade|fba|neogeo ]]; then
#            params+=(-mame_img "s,m,t")
#        else
#            params+=(-console_img "s,b,3b,l,f")
#        fi
#    fi
#    if [[ "$download_videos" -eq 1 ]]; then
#        params+=(-download_videos)
#    fi
#    if [[ "$download_marquees" -eq 1 ]]; then
#        params+=(-download_marquees)
#    fi
#    if [[ -n "$max_width" ]]; then
#        params+=(-max_width "$max_width")
#    fi
#    if [[ -n "$max_height" ]]; then
#        params+=(-max_height "$max_height")
#    fi
#    if [[ "$console_src" -eq 0 ]]; then
#        params+=(-console_src="ovgdb")
#    elif [[ "$console_src" -eq 1 ]]; then
#        params+=(-console_src="gdb")
#    else
#        params+=(-console_src="ss")
#    fi
#    if [[ "$mame_src" -eq 0 ]]; then
#        params+=(-mame_src="mamedb")
#    elif [[ "$mame_src" -eq 1 ]]; then
#        params+=(-mame_src="ss")
#    else
 #       params+=(-mame_src="adb")
 #   fi
 #   if [[ "$rom_name" -eq 1 ]]; then
 #       params+=(-use_nointro_name=false)
 #   elif [[ "$rom_name" -eq 2 ]]; then
 #       params+=(-use_filename=true)
 #   fi
 #   if [[ "$append_only" -eq 1 ]]; then
 #       params+=(-append)
 #   fi

    # trap ctrl+c and return if pressed (rather than exiting retropie-setup etc)
    trap 'trap 2; return 1' INT
    #echo "su $user -c python3 -u $md_inst/retroscraper.py ${params[@]}" >/tmp/test.txt
    su $user -c "python3 -u $md_inst/retroscraper.py ${params[@]}"
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

        if [[ "$use_thumbs" -eq 1 ]]; then
            options+=(3 "Thumbnails only (Enabled)")
        else
            options+=(3 "Thumbnails only (Disabled)")
        fi

        if [[ "$screenshots" -eq 1 ]]; then
            options+=(4 "Prefer screenshots (Enabled)")
        else
            options+=(4 "Prefer screenshots (Disabled)")
        fi

        if [[ "$mame_src" -eq 0 ]]; then
            options+=(5 "Arcade Source (MameDB)")
        elif [[ "$mame_src" -eq 1 ]]; then
            options+=(5 "Arcade Source (ScreenScraper)")
        else
            options+=(5 "Arcade Source (ArcadeItalia)")
        fi

        if [[ "$console_src" -eq 0 ]]; then
            options+=(6 "Console Source (OpenVGDB)")
        elif [[ "$console_src" -eq 1 ]]; then
            options+=(6 "Console Source (thegamesdb)")
        else
            options+=(6 "Console Source (ScreenScraper)")
        fi

        if [[ "$rom_name" -eq 0 ]]; then
            options+=(7 "ROM Names (No-Intro)")
        elif [[ "$rom_name" -eq 1 ]]; then
            options+=(7 "ROM Names (theGamesDB)")
        else
            options+=(7 "ROM Names (Filename)")
        fi

        if [[ "$append_only" -eq 1 ]]; then
            options+=(8 "Gamelist (Append)")
        else
            options+=(8 "Gamelist (Overwrite)")
        fi

        if [[ "$use_rom_folder" -eq 1 ]]; then
            options+=(9 "Use rom folder for gamelist & images (Enabled)")
        else
            options+=(9 "Use rom folder for gamelist & images (Disabled)")
        fi

        if [[ "$download_videos" -eq 1 ]]; then
            options+=(V "Download Videos (Enabled)")
        else
            options+=(V "Download Videos (Disabled)")
        fi

        if [[ "$download_marquees" -eq 1 ]]; then
            options+=(M "Download Marquees (Enabled)")
        else
            options+=(M "Download Marquees (Disabled)")
        fi

        options+=(W "Max image width ($max_width)")
        options+=(H "Max image height ($max_height)")
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
                    use_thumbs="$((use_thumbs ^ 1))"
                    iniSet "use_thumbs" "$use_thumbs"
                    ;;
                4)
                    screenshots="$((screenshots ^ 1))"
                    iniSet "screenshots" "$screenshots"
                    ;;
                5)
                    mame_src="$((( mame_src + 1) % 3))"
                    iniSet "mame_src" "$mame_src"
                    ;;
                6)
                    console_src="$((( console_src + 1) % 3))"
                    iniSet "console_src" "$console_src"
                    ;;
                7)
                    rom_name="$((( rom_name + 1 ) % 3))"
                    iniSet "rom_name" "$rom_name"
                    ;;
                8)
                    append_only="$((append_only ^ 1))"
                    iniSet "append_only" "$append_only"
                    ;;
                9)
                    use_rom_folder="$((use_rom_folder ^ 1))"
                    iniSet "use_rom_folder" "$use_rom_folder"
                    ;;
                V)
                    download_videos="$((download_videos ^ 1))"
                    iniSet "download_videos" "$download_videos"
                    ;;
                M)
                    download_marquees="$((download_marquees ^ 1))"
                    iniSet "download_marquees" "$download_marquees"
                    ;;
                H)
                    cmd=(dialog --backtitle "$__backtitle" --inputbox "Please enter the max image height in pixels" 10 60 "$max_height")
                    max_height=$("${cmd[@]}" 2>&1 >/dev/tty)
                    iniSet "max_height" "$max_height"
                    ;;
                W)
                    cmd=(dialog --backtitle "$__backtitle" --inputbox "Please enter the max image width in pixels" 10 60 "$max_width")
                    max_width=$("${cmd[@]}" 2>&1 >/dev/tty)
                    iniSet "max_width" "$max_width"
                    ;;
            esac
        else
            break
        fi
    done
}
