#!/usr/bin/env bash
##  Copy NuttX Image to MicroSD with SDWire MicroSD Multiplexer:
##  scp Image thinkcentre:/tmp/Image
##  ssh thinkcentre ls -l /tmp/Image
##  ssh thinkcentre sudo /home/user/copy-image.sh

echo "Now running https://github.com/lupyuen/nuttx-avaota-a1/blob/main/copy-image.sh"
set -e  ## Exit when any command fails
set -x  ## Echo commands
whoami  ## I am root!

## Copy /tmp/Image to MicroSD
sd-mux-ctrl --device-serial=sd-wire_02-09 --ts
sleep 5
mkdir -p /tmp/sda1
mount /dev/sda1 /tmp/sda1
cp /tmp/Image /tmp/sda1/
ls -l /tmp/sda1

## Unmount MicroSD and flip it to the Test Device (Avaota-A1)
umount /tmp/sda1
sd-mux-ctrl --device-serial=sd-wire_02-09 --dut
