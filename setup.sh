#!/bin/bash

script_dir="$(cd "$(dirname "$0")" && pwd)"
echo "$script_dir"

ramdisk="ramdisk.img"
original_ramdisk_path="$ANDROID_SDK_ROOT/system-images/android-29/default/x86_64/original_$ramdisk"
ramdisk_path="$ANDROID_SDK_ROOT/system-images/android-29/default/x86_64/$ramdisk"
emulator_bin="$ANDROID_HOME/tools/emulator"

function check_exit_code() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo "Error: The last command failed with exit code $exit_code."
        exit 1
    fi
}

function reset_ramdisk() {
    cp -v $original_ramdisk_path $ramdisk_path
    exit 0
}

if [ "$1" = "reset" ]; then
    echo "The first argument is 'reset'."
    reset_ramdisk
fi

function backup_ramdisk() {
    if [ ! -f "$original_ramdisk_path" ]; then
        echo "taking backup of $ramdisk_path"
        cp -v $ramdisk_path $original_ramdisk_path
    fi
}

function fetch_original_ramdisk() {
    cp -v $original_ramdisk_path $script_dir/MagiskOnEmulator/$ramdisk
}

function download_magisk() {
    url="https://github.com/topjohnwu/Magisk/releases/download/v24.3/Magisk-v24.3.apk"
    filename="Magisk-v24.3.apk"
    # url="https://github.com/topjohnwu/Magisk/releases/download/v24.1/Magisk-v24.1.apk"
    # filename="Magisk-v24.1.apk"
    # 24.0 has SELinux issues
    # url="https://github.com/topjohnwu/Magisk/releases/download/v24.0/Magisk-v24.0.apk"
    # filename="Magisk-v24.0.apk"
    # 26.3 does not work on
    # url="https://github.com/topjohnwu/Magisk/releases/download/v26.3/Magisk.v26.3.apk"
    # filename="Magisk.v26.3.apk"
    if [ ! -f "$filename" ]; then
        wget $url
    else
        echo "$filename already downloaded"
    fi
    cp -v $filename $script_dir/MagiskOnEmulator/magisk.zip
    cp -v $filename $script_dir/MagiskOnEmulator/magisk.apk
}

function patch_manager() {
    cd $script_dir/MagiskOnEmulator
    chmod +x patch.sh
    ./patch.sh manager
    cd $script_dir
}

function print_bold_green() {
    local message="$1"
    # ANSI escape codes for bold and green text
    local bold_green="\e[1;32m"
    local reset="\e[0m" # Reset formatting

    # Print the message in bold green
    echo -e "${bold_green}${message}${reset}"
}

function wait_busy_loop() {
    while :; do
        read -rp "Type 'yes' to continue: " user_input
        if [ "${user_input,,}" = "yes" ]; then
            break
        else
            echo "You did not type 'yes.' Please try again."
        fi
    done
}

function pull_patched() {
    cd $script_dir/MagiskOnEmulator
    ./patch.sh pull
    cp -v $ramdisk $ramdisk_path
    cd $script_dir
    echo "Shutdown AVD and Wipe data"
}

function install_lsposed() {
    url="https://github.com/LSPosed/LSPosed/releases/download/v1.9.2/LSPosed-v1.9.2-7024-zygisk-release.zip"
    filename="LSPosed-v1.9.2-7024-zygisk-release.zip"
    if [ ! -f "$filename" ]; then
        wget $url
    else
        echo "$filename already downloaded"
    fi
    adb push $filename /sdcard
}

function install_hma() {
    url="https://github.com/Dr-TSNG/Hide-My-Applist/releases/download/V3.2/HMA-V3.2.apk"
    filename="HMA-V3.2.apk"
    if [ ! -f "$filename" ]; then
        wget $url
    else
        echo "$filename already downloaded"
    fi
    adb install $filename
}

backup_ramdisk
# reset_ramdisk
fetch_original_ramdisk
download_magisk
patch_manager
print_bold_green "
Magisk is pushed to AVD - do the stuff
1. Open Magisk Manager
2. Click Install
3. Check Select and Path a file
4. Enable Show internal storage
5. Find boot.img and select it
6. Click Lets go
7. You should see All done! 
Continue!
"
wait_busy_loop
pull_patched
print_bold_green "
1. Turn off AVD
2. Wipe data from AVD
3. Cold boot
4. Follow Magisk setup tips when device boots (maybe reboot again)
"
wait_busy_loop
# now magisk is installed
install_lsposed
print_bold_green "
1. Install zygisk using magisk manager (under modules: install from source)
2. Reboot
"
wait_busy_loop
install_hma
print_bold_green "
Installed hma, enable under LSPosed modules

Upgrade Manager using 'direct install'
"
