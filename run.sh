#!/usr/bin/env bash
#  Build and Boot NuttX for Avaota-A1

set -e  #  Exit when any command fails
set -x  #  Echo commands

../nxstyle Documentation/platforms/arm64/a527/index.rst
../nxstyle arch/arm64/Kconfig
../nxstyle arch/arm64/include/a527/chip.h
../nxstyle arch/arm64/include/a527/irq.h
../nxstyle arch/arm64/src/a527/CMakeLists.txt
../nxstyle arch/arm64/src/a527/Kconfig
../nxstyle arch/arm64/src/a527/Make.defs
../nxstyle arch/arm64/src/a527/a527_boot.c
../nxstyle arch/arm64/src/a527/a527_boot.h
../nxstyle arch/arm64/src/a527/a527_initialize.c
../nxstyle arch/arm64/src/a527/a527_lowputc.S
../nxstyle arch/arm64/src/a527/a527_serial.c
../nxstyle arch/arm64/src/a527/a527_textheap.c
../nxstyle arch/arm64/src/a527/a527_timer.c
../nxstyle arch/arm64/src/a527/chip.h

../nxstyle Documentation/platforms/arm64/a527/boards/avaota-a1/avaota-a1.jpg
../nxstyle Documentation/platforms/arm64/a527/boards/avaota-a1/index.rst
../nxstyle boards/Kconfig
../nxstyle boards/arm64/a527/avaota-a1/CMakeLists.txt
../nxstyle boards/arm64/a527/avaota-a1/Kconfig
../nxstyle boards/arm64/a527/avaota-a1/configs/nsh/defconfig
../nxstyle boards/arm64/a527/avaota-a1/include/board.h
../nxstyle boards/arm64/a527/avaota-a1/include/board_memorymap.h
../nxstyle boards/arm64/a527/avaota-a1/scripts/Make.defs
../nxstyle boards/arm64/a527/avaota-a1/scripts/gnu-elf.ld
../nxstyle boards/arm64/a527/avaota-a1/scripts/ld.script
../nxstyle boards/arm64/a527/avaota-a1/src/CMakeLists.txt
../nxstyle boards/arm64/a527/avaota-a1/src/Makefile
../nxstyle boards/arm64/a527/avaota-a1/src/a527_appinit.c
../nxstyle boards/arm64/a527/avaota-a1/src/a527_boardinit.c
../nxstyle boards/arm64/a527/avaota-a1/src/a527_bringup.c
../nxstyle boards/arm64/a527/avaota-a1/src/a527_power.c
../nxstyle boards/arm64/a527/avaota-a1/src/avaota-a1.h

## TODO: Set PATH
# wget https://github.com/xpack-dev-tools/aarch64-none-elf-gcc-xpack/releases/download/v14.2.1-1.1/xpack-aarch64-none-elf-gcc-14.2.1-1.1-darwin-arm64.tar.gz
# tar xf xpack-aarch64-none-elf-gcc-*.tar.gz
export PATH="$HOME/xpack-aarch64-none-elf-gcc-14.2.1-1.1/bin:$PATH"

rm -rf \
  hello.S \
  Image \
  init.S \
  initrd

## Build NuttX
function build_nuttx {

  ## Go to NuttX Folder
  pushd ../nuttx

  ## Build NuttX
  make -j

  ## Return to previous folder
  popd
}

## Build Apps Filesystem
function build_apps {

  ## Go to NuttX Folder
  pushd ../nuttx

  ## Build Apps Filesystem
  make -j export
  pushd ../apps
  ./tools/mkimport.sh -z -x ../nuttx/nuttx-export-*.tar.gz
  make -j import
  popd

  ## Return to previous folder
  popd
}

## Pull updates
git status && hash1=`git rev-parse HEAD`
pushd ../apps
git status && hash2=`git rev-parse HEAD`
popd
echo NuttX Source: https://github.com/apache/nuttx/tree/$hash1 >nuttx.hash
echo NuttX Apps: https://github.com/apache/nuttx-apps/tree/$hash2 >>nuttx.hash

## Show the versions of GCC
aarch64-none-elf-gcc -v

## Configure build
make -j distclean || true
tools/configure.sh avaota-a1:nsh || true

## Build NuttX
build_nuttx

## Build Apps Filesystem
build_apps

## Show the size
aarch64-none-elf-size nuttx

## Copy the config
cp .config nuttx.config

## Generate the Initial RAM Disk
genromfs -f initrd -d ../apps/bin -V "NuttXBootVol"

## Prepare a Padding with 64 KB of zeroes
head -c 65536 /dev/zero >/tmp/nuttx.pad

## Append Padding and Initial RAM Disk to the NuttX Kernel
cat nuttx.bin /tmp/nuttx.pad initrd \
  >Image

## Dump the disassembly to nuttx.S
aarch64-none-elf-objdump \
  --syms --source --reloc --demangle --line-numbers --wide \
  --debugging \
  nuttx \
  >nuttx.S \
  2>&1

## Dump the init disassembly to init.S
aarch64-none-elf-objdump \
  --syms --source --reloc --demangle --line-numbers --wide \
  --debugging \
  ../apps/bin/init \
  >init.S \
  2>&1

## Dump the hello disassembly to hello.S
aarch64-none-elf-objdump \
  --syms --source --reloc --demangle --line-numbers --wide \
  --debugging \
  ../apps/bin/hello \
  >hello.S \
  2>&1

## Copy NuttX Image to MicroSD
## https://github.com/lupyuen/nuttx-avaota-a1/blob/main/copy-image.sh
scp Image thinkcentre:/tmp/Image
ssh thinkcentre ls -l /tmp/Image
ssh thinkcentre sudo /home/user/copy-image.sh

## Boot and Test NuttX Automatically
function auto_test {
  ## Boot and Test NuttX
  ## https://github.com/lupyuen/nuttx-build-farm/blob/main/avaota.exp
  export AVAOTA_SERVER=thinkcentre
  pushd $HOME/nuttx-build-farm
  expect ./avaota.exp
  popd
}

## Boot and Test NuttX Manually
function manual_test {
  ## Get the Home Assistant Token, copied from http://localhost:8123/profile/security
  ## token=xxxx
  set +x  ##  Disable echo
  . $HOME/home-assistant-token.sh
  set -x  ##  Enable echo

  set +x  ##  Disable echo
  echo "----- Power Off the SBC"
  curl \
      -X POST \
      -H "Authorization: Bearer $token" \
      -H "Content-Type: application/json" \
      -d '{"entity_id": "automation.avaota_power_off"}' \
      http://localhost:8123/api/services/automation/trigger
  set -x  ##  Enable echo

  set +x  ##  Disable echo
  echo "----- Power On the SBC"
  curl \
      -X POST \
      -H "Authorization: Bearer $token" \
      -H "Content-Type: application/json" \
      -d '{"entity_id": "automation.avaota_power_on"}' \
      http://localhost:8123/api/services/automation/trigger
  set -x  ##  Enable echo

  echo Press Enter to Power Off
  read

  set +x  ##  Disable echo
  echo "----- Power Off the SBC"
  curl \
      -X POST \
      -H "Authorization: Bearer $token" \
      -H "Content-Type: application/json" \
      -d '{"entity_id": "automation.avaota_power_off"}' \
      http://localhost:8123/api/services/automation/trigger
  set -x  ##  Enable echo
}

## Boot and Test NuttX (Auto or Manual)
auto_test
# manual_test

## Clean up
rm -rf \
  hello.S \
  Image \
  init.S \
  initrd

## We're done!
exit

## On Test PC
sudo --login
function copy_image_to_microsd {
  sd-mux-ctrl --device-serial=sd-wire_02-09 --ts
  sleep 5
  mount /dev/sda1 /tmp/sda1
  cp /home/user/Image /tmp/sda1/
  ls -l /tmp/sda1
  umount /tmp/sda1
  sd-mux-ctrl --device-serial=sd-wire_02-09 --dut
}
copy_image_to_microsd

## Boot NuttX on QEMU
# qemu-system-aarch64 \
#   -semihosting \
#   -cpu cortex-a53 \
#   -nographic \
#   -machine virt,virtualization=on,gic-version=3 \
#   -net none \
#   -chardev stdio,id=con,mux=on \
#   -serial chardev:con \
#   -mon chardev=con,mode=readline \
#   -kernel ./nuttx

## Update NuttX Config
export PATH="$HOME/xpack-aarch64-none-elf-gcc-14.2.1-1.1/bin:$PATH"
make menuconfig \
  && make savedefconfig \
  && grep -v CONFIG_HOST defconfig \
  >boards/arm64/a527/avaota-a1/configs/nsh/defconfig

## Copy log
scp thinkcentre:/tmp/screen-exchange /tmp/screen-exchange

## Get PR Diff
pr=https://github.com/lupyuen2/wip-pinephone-nuttx/pull/99
curl -L $pr.diff \
  | grep "diff --git" \
  | sort \
  | cut -d" " -f3 \
  | cut -c3-

## Build Documentation
cd nuttx
cd Documentation
### Previously: pip3 install pipenv
brew install pipenv
pipenv install
pipenv shell
clear ; rm -r _build ; make -j html
clear ; rm -r _build ; make -j html 2>&1 | grep rst
open _build/html/index.html 

## Copy the Board Files from src to dest
## Copy the Arch Doc again because we restored the "Supported Boards" 
function copy_files() {
  src=/tmp/avaota2
  dest=.
  for file in \
    Documentation/platforms/arm64/a527/index.rst \
    Documentation/platforms/arm64/a527/boards/avaota-a1/avaota-a1.jpg \
    Documentation/platforms/arm64/a527/boards/avaota-a1/index.rst \
    boards/Kconfig \
    boards/arm64/a527/avaota-a1/CMakeLists.txt \
    boards/arm64/a527/avaota-a1/Kconfig \
    boards/arm64/a527/avaota-a1/configs/nsh/defconfig \
    boards/arm64/a527/avaota-a1/include/board.h \
    boards/arm64/a527/avaota-a1/include/board_memorymap.h \
    boards/arm64/a527/avaota-a1/scripts/Make.defs \
    boards/arm64/a527/avaota-a1/scripts/gnu-elf.ld \
    boards/arm64/a527/avaota-a1/scripts/ld.script \
    boards/arm64/a527/avaota-a1/src/CMakeLists.txt \
    boards/arm64/a527/avaota-a1/src/Makefile \
    boards/arm64/a527/avaota-a1/src/a527_appinit.c \
    boards/arm64/a527/avaota-a1/src/a527_boardinit.c \
    boards/arm64/a527/avaota-a1/src/a527_bringup.c \
    boards/arm64/a527/avaota-a1/src/a527_power.c \
    boards/arm64/a527/avaota-a1/src/avaota-a1.h \

  do
    src_file=$src/$file
    dest_file=$dest/$file
    dest_dir=$(dirname -- "$dest_file")
    set -x
    mkdir -p $dest_dir
    cp $src_file $dest_file
    set +x
  done
}
