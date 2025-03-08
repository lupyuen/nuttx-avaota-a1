![Apache NuttX RTOS for Avaota-A1 SBC (Allwinner A527 SoC)](https://lupyuen.org/images/testbot2-flow3.jpg)

# Apache NuttX RTOS for Avaota-A1 SBC (Allwinner A527 SoC)

_How about booting and testing NuttX on Avaota-A1 SBC?_

Exactly! Here's why Avaota-A1 SBC should run NuttX...

- __Avaota-A1__ has the latest Octa-Core Arm64 SoC: __Allwinner A527__

  _(Bonus: There's a tiny RISC-V Core inside)_

- [__NuttX Kernel Build__](https://lupyuen.github.io/articles/rust5#nuttx-flat-mode-vs-kernel-mode) sounds ideal for Allwinner A527 SoC

  _(Instead of the restrictive Flat Build)_

- __Avaota-A1__ could be the first Arm64 Port of NuttX Kernel Build

  [_(NXP i.MX93 might be another)_](https://github.com/apache/nuttx/pull/15556)

- __SDWire MicroSD Multiplexer__: Avaota SBC was previously the __Test Server__, now it becomes the __Test Device__

  _(Porting NuttX gets a lot quicker)_

- __Open-Source RTOS__ _(NuttX)_ tested on __Open-Source Hardware__ _(Avaota-A1)_ ... Perfectly sensible!

We'll take the NuttX Kernel Build for [__QEMU Arm64__](https://github.com/apache/nuttx/blob/master/boards/arm64/qemu/qemu-armv8a/configs/knsh/defconfig), boot it on Avaota-A1 SBC. We're making terrific progress with __NuttX on Avaota SBC__...

> ![NuttX on Avaota-A1](https://lupyuen.org/images/testbot3-port.png)

_Isn't it faster to port NuttX with U-Boot TFTP?_

Yeah for RISC-V Ports we boot [__NuttX over TFTP__](https://lupyuen.github.io/articles/starpro64#boot-nuttx-over-tftp). But Avaota U-Boot [__doesn't support TFTP__](https://gist.github.com/lupyuen/366f1ffefc8231670ffd58a3b88ae8e5), so it's back to MicroSD sigh. (Pic below)

Well thankfully we have a __MicroSD Multiplexer__ that will make MicroSD Swapping a lot easier! (Not forgetting our [__Smart Power Plug__](https://lupyuen.github.io/articles/testbot#power-up-our-oz64-sbc))

![Avaota A1: Default U-Boot in eMMC. No network :-(](https://lupyuen.org/images/testbot3-uboot.jpg)

# Prepare the MicroSD

Download the [__Latest AvaotaOS Release__](https://github.com/AvaotaSBC/AvaotaOS/releases) _(Ubuntu Noble GNOME)_ and uncompress it...

```bash
wget https://github.com/AvaotaSBC/AvaotaOS/releases/download/0.3.0.4/AvaotaOS-0.3.0.4-noble-gnome-arm64-avaota-a1.img.xz
xz -d AvaotaOS-0.3.0.4-noble-gnome-arm64-avaota-a1.img.xz
```

Write the __`.img`__ file to a MicroSD with [__Balena Etcher__](https://etcher.balena.io/).

We'll overwrite the `Image` file by `nuttx.bin`...

![Avaota-A1 SBC with SDWire MicroSD Multiplexer and Smart Power Plug](https://lupyuen.org/images/avaota-title.jpg)

# Build NuttX for Avaota-A1

Our Avaota-A1 SBC is connected to SDWire MicroSD Multiplexer and Smart Power Plug (pic above). So our Build Script will do __everything__ for us:

- Copy NuttX to MicroSD

- Swap MicroSD from our Test PC to SBC

- Power up SBC and boot NuttX!

See the Build Script:
- https://gist.github.com/lupyuen/a4ac110fb8610a976c0ce2621cbb8587

```bash
## Build NuttX and Apps (NuttX Kernel Build)
git clone https://github.com/lupyuen2/wip-nuttx nuttx --branch avaota
git clone https://github.com/lupyuen2/wip-nuttx-apps apps --branch avaota
cd nuttx
tools/configure.sh qemu-armv8a:knsh
make -j
make -j export
pushd ../apps
./tools/mkimport.sh -z -x ../nuttx/nuttx-export-*.tar.gz
make -j import
popd

## Generate the Initial RAM Disk
genromfs -f initrd -d ../apps/bin -V "NuttXBootVol"

## Prepare a Padding with 64 KB of zeroes
head -c 65536 /dev/zero >/tmp/nuttx.pad

## Append Padding and Initial RAM Disk to the NuttX Kernel
cat nuttx.bin /tmp/nuttx.pad initrd \
  >Image

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
    -d '{"entity_id": "automation.starpro64_power_off"}' \
    http://localhost:8123/api/services/automation/trigger
set -x  ##  Enable echo

## Copy NuttX Image to MicroSD
## No password needed for sudo, see below
scp Image thinkcentre:/tmp/Image
ssh thinkcentre ls -l /tmp/Image
ssh thinkcentre sudo /home/user/copy-image.sh

set +x  ##  Disable echo
echo "----- Power On the SBC"
curl \
    -X POST \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -d '{"entity_id": "automation.starpro64_power_on"}' \
    http://localhost:8123/api/services/automation/trigger
set -x  ##  Enable echo

## Wait for SBC to finish booting
sleep 30

set +x  ##  Disable echo
echo "----- Power Off the SBC"
curl \
    -X POST \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -d '{"entity_id": "automation.starpro64_power_off"}' \
    http://localhost:8123/api/services/automation/trigger
set -x  ##  Enable echo
```

[(See the __Build Log__)](https://gist.github.com/lupyuen/6c0607daa0a8f37bda37cc80e76259ee)

(__copy-image.sh__ is explained below)

# Boot NuttX for Avaota-A1

NuttX boots to NSH Shell. And passes OSTest yay!

Here's the latest NuttX Boot Log:
- https://gist.github.com/lupyuen/c2248e7537ca98333d47e33b232217b6

<span style="font-size:60%">

```text
[    0.000255][I]  _____     _           _____ _ _
[    0.006320][I] |   __|_ _| |_ ___ ___|  |  |_| |_
[    0.012456][I] |__   | | |  _| -_|  _|    -| | _|
[    0.018566][I] |_____|_  |_| |___|_| |__|__|_|_|
[    0.024719][I]       |___|
[    0.030820][I] ***********************************
[    0.036948][I]  SyterKit v0.4.0 Commit: e4c0651
[    0.042781][I]  github.com/YuzukiHD/SyterKit
[    0.048882][I] ***********************************
[    0.054992][I]  Built by: arm-none-eabi-gcc 13.2.1
[    0.061119][I]
[    0.063943][I] Model: AvaotaSBC Avaota A1 board.
[    0.069856][I] Core: Arm Octa-Core Cortex-A55 v65 r2p0
[    0.076356][I] Chip SID = 0300ff1071c048247590d120506d1ed4
[    0.083280][I] Chip type = A527M000000H Chip Version = 2
[    0.091391][I] PMU: Found AXP717 PMU, Addr 0x35
[    0.098200][I] PMU: Found AXP323 PMU
[    0.112870][I] DRAM BOOT DRIVE INFO: V0.6581
[    0.118326][I] Set DRAM Voltage to 1160mv
[    0.123524][I] DRAM_VCC set to 1160 mv
[    0.247920][I] DRAM retraining ten
[    0.266135][I] [AUTO DEBUG]32bit,2 ranks training success!
[    0.296290][I] Soft Training Version: T2.0
[    1.819657][I] [SOFT TRAINING] CLK=1200M Stable memtest pass
[    1.826565][I] DRAM CLK =1200 MHZ
[    1.830992][I] DRAM Type =8 (3:DDR3,4:DDR4,6:LPDDR2,7:LPDDR3,8:LPDDR4)
[    1.843100][I] DRAM SIZE =4096 MBytes, para1 = 310a, para2 = 10001000, tpr13 = 6061
[    1.853431][I] DRAM simple test OK.
[    1.858011][I] Init DRAM Done, DRAM Size = 4096M
[    2.278300][I] SMHC: sdhci0 controller initialized
[    2.305826][I]   Capacity: 59.48GB
[    2.310439][I] SHMC: SD card detected
[    2.319537][I] FATFS: read bl31.bin addr=48000000
[    2.339744][I] FATFS: read in 13ms at 5.92MB/S
[    2.345498][I] FATFS: read scp.bin addr=48100000
[    2.374729][I] FATFS: read in 22ms at 8.00MB/S
[    2.380481][I] FATFS: read extlinux/extlinux.conf addr=40020000
[    2.389436][I] FATFS: read in 1ms at 0.29MB/S
[    2.395095][I] FATFS: read splash.bin addr=40080000
[    2.403142][I] FATFS: read in 1ms at 12.66MB/S
[    3.193943][I] FATFS: read /Image addr=40800000
[    3.341455][I] FATFS: read in 143ms at 8.86MB/S
[    3.347308][I] FATFS: read /dtb/allwinner/sun55i-t527-avaota-a1.dtb addr=40400000
[    3.400140][I] FATFS: read in 19ms at 7.46MB/S
[    3.405891][I] FATFS: read /uInitrd addr=43000000
[    4.113508][I] FATFS: read in 702ms at 9.04MB/S
[    4.119356][I] Initrd load 0x43000000, Size 0x00632414
[    5.376346][W] FDT: bootargs is null, using extlinux.conf append.
[    5.688989][I] EXTLINUX: load extlinux done, now booting...
[    5.695984][I] ATF: Kernel addr: 0x40800000
[    5.701523][I] ATF: Kernel DTB addr: 0x40400000
[    5.891085][I] disable mmu ok...
[    5.895615][I] disable dcache ok...
[    5.900478][I] disable icache ok...
[    5.905342][I] free interrupt ok...
NOTICE:  BL31: v2.5(debug):9241004a9
NOTICE:  BL31: Built : 13:37:46, Nov 16 2023
NOTICE:  BL31: No DTB found.
NOTICE:  [SCP] :wait arisc ready....
NOTICE:  [SCP] :arisc version: []
NOTICE:  [SCP] :arisc startup ready
NOTICE:  [SCP] :arisc startup notify message feedback
NOTICE:  [SCP] :sunxi-arisc driver is starting
ERROR:   Error initializing runtime service opteed_fast
123- Ready to Boot Primary CPU
- Boot from EL2
- Boot from EL1
- Boot to C runtime for OS Initialize
ABarm64_mmu_init:
setup_page_tables:
enable_mmu_el1:
enable_mmu_el1: UP_MB
enable_mmu_el1: Enable the MMU and data cache
up_allocate_kheap: CONFIG_RAM_END=0x48000000, g_idle_topstack=0x40847000
qemu_bringup:
mount_ramdisk:
nx_start_application: ret=0
board_app_initialize:

NuttShell (NSH) NuttX-12.4.0
nsh> uname -a
NuttX 12.4.0 6c5c1a5f9f-dirty Mar  8 2025 21:57:02 arm64 qemu-armv8a
nsh> free
      total       used       free    maxused    maxfree  nused  nfree name
  125538304      33848  125504456      52992  125484976     58      5 Kmem
    4194304     245760    3948544               3948544               Page
nsh> ps
  PID GROUP PRI POLICY   TYPE    NPX STATE    EVENT     SIGMASK            STACK    USED FILLED COMMAND
    0     0   0 FIFO     Kthread   - Ready              0000000000000000 0008176 0000928  11.3%  Idle_Task
    1     0 192 RR       Kthread   - Waiting  Semaphore 0000000000000000 0008112 0000992  12.2%  hpwork 0x40834568 0x408345b8
    2     0 100 RR       Kthread   - Waiting  Semaphore 0000000000000000 0008112 0000992  12.2%  lpwork 0x408344e8 0x40834538
    4     4 100 RR       Task      - Running            0000000000000000 0008128 0002192  26.9%  /system/bin/init
nsh> ls -l /dev
/dev:
 crw-rw-rw-           0 console
 crw-rw-rw-           0 null
 brw-rw-rw-    16777216 ram0
 crw-rw-rw-           0 ttyS0
 crw-rw-rw-           0 zero
nsh> hello
Hello, World!!
nsh> getprime
Set thread priority to 10
Set thread policy to SCHED_RR
Start thread #0
thread #0 started, looking for primes < 10000, doing 10 run(s)
thread #0 finished, found 1230 primes, last one was 9973
Done
getprime took 162 msec
nsh> hello
Hello, World!!
nsh> getprime
Set thread priority to 10
Set thread policy to SCHED_RR
Start thread #0
thread #0 started, looking for primes < 10000, doing 10 run(s)
thread #0 finished, found 1230 primes, last one was 9973
Done
getprime took 162 msec
nsh> ostest
...
Final memory usage:
VARIABLE  BEFORE   AFTER
======== ======== ========
arena        a000    26000
ordblks         2        4
mxordblk     6ff8    1aff8
uordblks     27e8     6700
fordblks     7818    1f900
user_main: Exiting
ostest_main: Exiting with status 0
nsh>
```

</span>

How did we get here? Let's walk through the steps...

# Allwinner A527 Docs

We used these docs (A527 is a variant of A523)

- https://linux-sunxi.org/A523
- https://linux-sunxi.org/File:A527_Datasheet_V0.93.pdf
- https://linux-sunxi.org/File:A523_User_Manual_V1.1_merged_cleaned.pdf

# Work In Progress

We take NuttX for Arm64 QEMU knsh and tweak it iteratively for Avaota-A1 SBC, based on Allwinner A537 SoC...

## Let's make our Build-Test Cycle quicker. We do Passwordless Sudo for flipping our SDWire Mux

SDWire Mux needs plenty of Sudo Passwords to flip the mux, mount the filesystem, copy to MicroSD.

Let's make it Sudo Password-Less with visudo: https://help.ubuntu.com/community/Sudoers

```bash
sudo visudo
<<
user ALL=(ALL) NOPASSWD: /home/user/copy-image.sh
>>
```

Edit /home/user/copy-image.sh...

```bash
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

## Unmount MicroSD and flip it to the Test Device (Avaota-A1 SBC)
umount /tmp/sda1
sd-mux-ctrl --device-serial=sd-wire_02-09 --dut
```

(Remember to `chmod +x /home/user/copy-image.sh`)

Now we can run copy-image.sh without a password yay!

```bash
## Sudo will NOT prompt for password yay!
sudo /home/user/copy-image.sh

## Also works over SSH: Copy NuttX Image to MicroSD
## No password needed for sudo yay!
scp nuttx.bin thinkcentre:/tmp/Image
ssh thinkcentre ls -l /tmp/Image
ssh thinkcentre sudo /home/user/copy-image.sh
```

[(See the __Build Script__)](https://gist.github.com/lupyuen/a4ac110fb8610a976c0ce2621cbb8587)

## UART0 Port is here

From [A523 User Manual](https://linux-sunxi.org/File:A523_User_Manual_V1.1_merged_cleaned.pdf), Page 1839

```text
Module Name Base Address
UART0 0x02500000

Register Name Offset Description
UART_RBR 0x0000 UART Receive Buffer Register
UART_THR 0x0000 UART Transmit Holding Register
UART_DLL 0x0000 UART Divisor Latch Low Register
UART_DLH 0x0004 UART Divisor Latch High Register
UART_IER 0x0004 UART Interrupt Enable Register
UART_IIR 0x0008 UART Interrupt Identity Register
UART_FCR 0x0008 UART FIFO Control Register
UART_LCR 0x000C UART Line Control 
```

## Bootloader Log says that Start Address is 0x40800000. We change it

Change start address to 0x40800000
- https://github.com/lupyuen2/wip-nuttx/commit/c38e1f7c014e1af648a33847fc795930ba995bca

Fix Image Load Offset. Print 123
- https://github.com/lupyuen2/wip-nuttx/commit/be2f1c55aa24eda9cd8652aa0bf38251335e9d01

Prints 123 yay!
- https://gist.github.com/lupyuen/14188c44049a14e3581523c593fdf2d8

Enable 16650 UART
- https://github.com/lupyuen2/wip-nuttx/commit/0cde58d84c16f255cb12e5a647ebeee3b6a8dd5f

## UART Buffer overflows. Let's wait for UART Ready

Wait for 16550 UART to be ready to transmit
- https://github.com/lupyuen2/wip-nuttx/commit/544323e7c0e66c4df0d1312d4837147d420bc19d

Add boot logging
- https://github.com/lupyuen2/wip-nuttx/commit/029056c7e0da092e4d3a211b5f5b22b7014ba333

Prints more yay!
- https://gist.github.com/lupyuen/563ed00d3f6e9f7fb9b27268d4eae26b

```text
- Ready to Boot Primary CPU
- Boot from EL2
- Boot from EL1
- Boot to C runtime for OS Initialize
AB
```

## Troubleboot the MMU. Why won't it start?

Enable Logging for Scheduler and MMU
- https://github.com/lupyuen2/wip-nuttx/commit/6f98f8a7cd214baa07288f581e58725aa76e4e58

Disable CONFIG_MMU_DUMP_PTE
- https://github.com/lupyuen2/wip-nuttx/commit/27faa28d0e70b3cf488bccc8d4b95e08b60fde9e

init_xlat_tables: mmap: virt 1082130432x phys 1082130432x size 4194304x
- https://gist.github.com/lupyuen/40b12ab106e890fb0706fabdbead09d9

Fix MMU Logging
- https://github.com/lupyuen2/wip-nuttx/commit/a4d1b7c9f37e331607f80f2ad4556904ecb69b9d

Now stuck at: `enable_mmu_el1: Enable the MMU and data cache`
- https://gist.github.com/lupyuen/9e3d1325dc90abc5b695a849a16e9560

## CONFIG_ARCH_PGPOOL_PBASE is different from pgram in Linker Script. Let's fix it

CONFIG_ARCH_PGPOOL_PBASE should match pgram
- https://github.com/lupyuen2/wip-nuttx/commit/eb33ac06f88dda557bc8ac97bec7d6cbad4ccb86

Still stuck at: `enable_mmu_el1: Enable the MMU and data cache`
- https://gist.github.com/lupyuen/544a5d8f3fab2ab7c9d06d2e1583f362

## Hmmm the Peripheral Address Space is missing. UART0 will crash!

From [A523 User Manual](https://linux-sunxi.org/File:A523_User_Manual_V1.1_merged_cleaned.pdf), Memory Map: Page 42

```text
BROM & SRAM
S_BROM 0x0000 0000---0x0000 AFFF 44 K

PCIE
PCIE_SLV 0x2000 0000---0x2FFF FFFF 256 MB

DRAM Space
DRAM SPACE 0x4000 0000---0x13FFF FFFF
4 GB
RISC-V core accesses theDRAM address:
0x4004 0000---0x7FFFFFFF
```

## Let's fix the Peripheral Address Space: 0x0 to 0x40000000, 1 GB

Remove UART1
- https://github.com/lupyuen2/wip-nuttx/commit/8fc8ed6ba84cfea86184f61d9c4d7c8e21329987

Add MMU Logging
- https://github.com/lupyuen2/wip-nuttx/commit/9488ecb5d8eb199bdbe16adabef483cf9cf04843

Remove PCI from MMU Regions
- https://github.com/lupyuen2/wip-nuttx/commit/ca273d05e015089a33072997738bf588b899f8e7

Set CONFIG_DEVICEIO_BASEADDR to 0x00000000, size 1 GB (0x40000000)
- https://github.com/lupyuen2/wip-nuttx/commit/005900ef7e1a1480b8df975d0dcd190fbfc60a45

`up_allocate_kheap: heap_start=0x0x40843000, heap_size=0xfffffffffffbd000`
- https://gist.github.com/lupyuen/ad4cec0dee8a21f3f404144be180fa14

## Whoa Heap Size is wrong! Let's find out why

Assert CONFIG_RAM_END > g_idle_topstack
- https://github.com/lupyuen2/wip-nuttx/commit/480bbc64af4ca64c104964c24f430c6de48326b5

Assertion fails
- https://gist.github.com/lupyuen/5f97773dcafc345a3510851629095c92

```text
up_allocate_kheap: CONFIG_RAM_END=0x40800000, g_idle_topstack=0x40843000
dump_assert_info: Assertion failed
```

## Oops CONFIG_RAM_END is too small. Let's enlarge

CONFIG_RAM_SIZE should match CONFIG_RAMBANK1_SIZE
- https://github.com/lupyuen2/wip-nuttx/commit/c8fbc5b86c2bf1dd7b8243b301b0790115c9c4ca

GIC Failed
- https://gist.github.com/lupyuen/3a7d1e791ac14905532db2d768ae230f

```text
gic_validate_dist_version: No GIC version detect
arm64_gic_initialize: no distributor detected, giving up ret=-19
```

## Ah we forgot the GIC Address!

From [A523 User Manual](https://linux-sunxi.org/File:A523_User_Manual_V1.1_merged_cleaned.pdf), Page 263

```text
Module Name Base Address Comments
GIC
GIC600_MON_4 0x03400000 General interrupt controller(23*64KB)

Register Name Offset Description
GICD_CTLR 0x00000 Distributor Control Register
GICR_CTLR_C0 0x60000 Redistributor Control Register
GICR_CTLR_C1 0x80000 Redistributor Control Register
GICR_CTLR_C2 0xA0000 Redistributor Control Register
GICR_CTLR_C3 0xC0000 Redistributor Control Register
GICR_CTLR_C4 0xE0000 Redistributor Control Register
GICR_CTLR_C5 0x100000 Redistributor Control Register
GICR_CTLR_C6 0x120000 Redistributor Control Register
GICR_CTLR_C7 0x140000 Redistributor Control Register
GICDA_CTLR 0x160000 Distributor Control Register
```

Set Address of GICD, GICR
- https://github.com/lupyuen2/wip-nuttx/commit/f3a26dbba69a0714bc91d0c345b8fba5e0835b76

Disable MM Logging
- https://github.com/lupyuen2/wip-nuttx/commit/10c7173b142f4a0480d742688c72499b76f66f83

/system/bin/init is missing yay!
- https://gist.github.com/lupyuen/3c587ac0f32be155c8f9a9e4ca18676c

## Load the NuttX Apps Filesystem into RAM

Remove HostFS for Semihosting
- https://github.com/lupyuen2/wip-nuttx/commit/40c4ab530dad2b7db0f354a2fa4b5e0f5263fb4e

OK the Initial Filesystem is no longer available:
- https://gist.github.com/lupyuen/e74c29049f20c76a2c4fe6f863d55507

Add the Initial RAM Disk
- https://github.com/lupyuen2/wip-nuttx/commit/cf5fe66b97f4526fb8dfc993415ac04ce96f4c13

Enable Logging for RAM Disk
- https://github.com/lupyuen2/wip-nuttx/commit/60007f1b97b6af4445c793904c30d65ebbebb337

`default_fatal_handler: (IFSC/DFSC) for Data/Instruction aborts: alignment fault`
- https://gist.github.com/lupyuen/f10af7903461f44689203d0e02fb9949

Our RAM Disk Copier is accessing misligned addresses. Let's fix the alignment...

Align RAM Disk Address to 8 bytes. Search from Idle Stack Top instead of EDATA.
- https://github.com/lupyuen2/wip-nuttx/commit/07d9c387a7cb06ccec53e20eecd0c4bb9bad7109

Log the Mount Error
- https://github.com/lupyuen2/wip-nuttx/commit/38538f99333868f85b67e2cb22958fe496e285d6

Mounting of ROMFS fails
- https://gist.github.com/lupyuen/d12e44f653d5c5597ecae6845e49e738

```text
nx_start_application: ret=-15
dump_assert_info: Assertion failed : at file: init/nx_bringup.c:361
```

Which is...

```c
#define ENOTBLK             15
#define ENOTBLK_STR         "Block device required"
```

/dev/ram0 is not a Block Device?

```c
$ grep INIT .config
# CONFIG_BOARDCTL_FINALINIT is not set
# CONFIG_INIT_NONE is not set
CONFIG_INIT_FILE=y
CONFIG_INIT_ARGS=""
CONFIG_INIT_STACKSIZE=8192
CONFIG_INIT_PRIORITY=100
CONFIG_INIT_FILEPATH="/system/bin/init"
CONFIG_INIT_MOUNT=y
CONFIG_INIT_MOUNT_SOURCE="/dev/ram0"
CONFIG_INIT_MOUNT_TARGET="/system/bin"
CONFIG_INIT_MOUNT_FSTYPE="romfs"
CONFIG_INIT_MOUNT_FLAGS=0x1
CONFIG_INIT_MOUNT_DATA=""
```

We check the logs...

Enable Filesystem Logging
- https://github.com/lupyuen2/wip-nuttx/commit/cc4dffd60fd223a7c1f6b513dc99e1fa98a48496

`Failed to find /dev/ram0`
- https://gist.github.com/lupyuen/805c2be2a3333a90c96926a26ec2d8cc

```text
find_blockdriver: pathname="/dev/ram0"
find_blockdriver: ERROR: Failed to find /dev/ram0
nx_mount: ERROR: Failed to find block driver /dev/ram0
nx_start_application: ret=-15
```

Is /dev/ram0 created? Ah we forgot to Mount the RAM Disk!

## Mount the RAM Disk

Mount the RAM Disk
- https://github.com/lupyuen2/wip-nuttx/commit/65ae74507e95189e96816161b0c1a820722ca8a2

/system/bin/init starts successfully yay!
- https://gist.github.com/lupyuen/ccb645efa72f6793743c033fade0b3ac

```text
qemu_bringup:
mount_ramdisk:
nx_start_application: ret=0
nx_start_application: Starting init task: /system/bin/init
nxtask_activate: /system/bin/init pid=4,TCB=0x408469f0
nxtask_exit: AppBringUp pid=3,TCB=0x40846190
board_app_initialize:
nx_start: CPU0: Beginning Idle Loop
```

NSH Prompt won't appear until we fix the UART Interrupt...

## TODO: Fix the UART Interrupt

From [A523 User Manual](https://linux-sunxi.org/File:A523_User_Manual_V1.1_merged_cleaned.pdf), Page 256

```text
Interrupt Number Interrupt Source Interrupt Vector Description
34 UART0 0x0088
```

So we set the UART0 Interrupt...

Set UART0 Interrupt to 34
- https://github.com/lupyuen2/wip-nuttx/commit/cd6da8f5378eb493528e57c61f887b6585ab8eaf

Disable Logging for MM and Scheduler
- https://github.com/lupyuen2/wip-nuttx/commit/6c5c1a5f9fb1c939d8e75a5e9544b1a5261165ee

Disable MMU Debugging
- https://github.com/lupyuen2/wip-nuttx/commit/e5c1b0449d3764d63d447eb96eb7186a27f77c88

NSH Prompt appears! And passes OSTest yay!
- https://gist.github.com/lupyuen/c2248e7537ca98333d47e33b232217b6

