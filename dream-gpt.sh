#!/bin/bash

MODEL=$(cat /proc/stb/info/model)
FP_VERSION=$(cat /proc/stb/fp/fp_version)

echo "Detected model: $MODEL"
echo "Frontpanel version: $FP_VERSION"

if [[ $MODEL != "one" && $MODEL != "two" ]]; then
    echo "Not supported model. Exiting."
    exit 1
fi

U_BOOT_PATH="/usr/share/u-boot-bin/dream${MODEL}/u-boot.bin"
UBOOT_SHA256=$(sha256sum "$U_BOOT_PATH" | awk '{print $1}')

echo "U-Boot SHA256 checksum: $UBOOT_SHA256"

if [[ ! -e /dev/bootloader ]]; then
    ln -sfn /dev/mmcblk0boot0 /dev/bootloader
fi

MAX_READ_SIZES="1652736 1655296 2051072 2054656 2053632"
UPDATE_REQUIRED=true

for MAX_READ_SIZE in $MAX_READ_SIZES; do
    DUMP_SHA256=$(dd "if=/dev/bootloader" "bs=$((${MAX_READ_SIZE} + 512))" count=1 2>/dev/null | dd skip=1 2>/dev/null | sha256sum | awk '{print $1}')
    echo "Dumped SHA256 checksum (max read size $MAX_READ_SIZE): $DUMP_SHA256"

    if [[ "$UBOOT_SHA256" == "$DUMP_SHA256" ]]; then
        UPDATE_REQUIRED=false
        echo -e "\e[32mU-Boot version is up-to-date for max read size $MAX_READ_SIZE."
        echo -e "\e[0m"
        break
    else
        echo -e "\e[31mU-Boot version needs an update for max read size $MAX_READ_SIZE."
        echo -e "\e[0m"
    fi
done

MAX_READ_SIZEone="1655296"
MAX_READ_SIZEtwo="2053632"
bs_variable="MAX_READ_SIZE${MODEL}"

if [[ "$UPDATE_REQUIRED" == true ]]; then
    read -p "Update U-Boot now? (y/n): " choice
    echo -e "\e[0m"
    if [[ $choice == "y" ]]; then
        flash-fsbl
        NEW_DUMP_SHA256=$(dd "if=/dev/bootloader" "bs=$((${!bs_variable} + 512))" count=1 2>/dev/null | dd skip=1 2>/dev/null | sha256sum | awk '{print $1}')
        if [[ "$UBOOT_SHA256" == "$NEW_DUMP_SHA256" ]]; then
            echo -e "\e[32mU-Boot updated successfully."
            echo -e "\e[0m"
        else
            echo -e "\e[31mUpdate U-Boot error. Exiting."
            echo -e "\e[0m"
            exit 1
        fi
    else
        echo "Exiting."
        echo -e "\e[0m"
        exit 1
    fi
fi

if [[ ($MODEL == "one" && $FP_VERSION == "1.15") || ($MODEL == "two" && $FP_VERSION == "1.14") ]]; then
    echo -e "\e[32mFrontpanel version is up-to-date."
    echo -e "\e[0m"
else
    echo -e "\e[31mFrontpanel has an old version and needs an update."
    read -p "Update now? (y/n): " choice
    echo -e "\e[0m"
    if [[ $choice == "y" ]]; then
        if [[ ! -e /dev/bootloader ]]; then
            ln -sfn /dev/mmcblk0boot0 /dev/bootloader
        fi
        flash-nrf52 --program --force --verify --start
        NEW_FP_VERSION=$(cat /proc/stb/fp/fp_version)
        echo "New frontpanel version: $NEW_FP_VERSION"
        if [[ ($MODEL == "one" && $NEW_FP_VERSION == "1.15") || ($MODEL == "two" && $NEW_FP_VERSION == "1.14") ]]; then
            echo -e "\e[32mFrontpanel updated successfully."
            echo -e "\e[0m"
        else
            echo -e "\e[31mUpdate frontpanel error. Exiting."
            echo -e "\e[0m"
            exit 1
        fi
    else
        echo "Exiting."
        echo -e "\e[0m"
        exit 1
    fi
fi


URI="https://source.mynonpublic.com/dreambox/dreambox-rescue-image-dreambox-20231126.bootimg"
curl -q $URI -o /tmp/dreambox-rescue-image.bin
if  [ -e /dev/recovery ]; then
    RECOVERY=`strings /dev/recovery | grep rootfs.cpio | cut -d . -f 1`
    if [ $RECOVERY == "dreambox-rescue-image-dreambox-20231126" ]; then
        echo -e "\e[32mRescue image is up-to-date Version 1.11Z."
        echo -e "\e[0m"
    else
        read -p "Rescue image needs an update to Version 1.11Z. Update now? (y/n): " choice
        echo -e "\e[0m"
        if [[ $choice == "y" ]]; then
            flash-rescue /tmp/dreambox-rescue-image.bin
            RECOVERY=`strings /dev/recovery | grep rootfs.cpio | cut -d . -f 1`
            if [ $RECOVERY == "dreambox-rescue-image-dreambox-20231126" ]; then
                echo -e "\e[32mRescue image updated successfully."
                echo -e "\e[0m"
            else
                echo -e "\e[31mUpdate Rescue image error. Exiting."
                echo -e "\e[0m"
                exit 1
            fi
        else
            echo "Exiting."
            echo -e "\e[0m"
            exit 1
        fi
    fi
fi
