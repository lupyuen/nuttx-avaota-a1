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
scp nuttx.bin thinkcentre:/tmp/Image
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

# Boot NuttX for Avaota-A1

https://gist.github.com/lupyuen/9e3d1325dc90abc5b695a849a16e9560

<span style="font-size:80%">

```text
[    0.000256][I]  _____     _           _____ _ _
[    0.006320][I] |   __|_ _| |_ ___ ___|  |  |_| |_
[    0.012456][I] |__   | | |  _| -_|  _|    -| | _|
[    0.018592][I] |_____|_  |_| |___|_| |__|__|_|_|
[    0.024737][I]       |___|
[    0.030873][I] ***********************************
[    0.036991][I]  SyterKit v0.4.0 Commit: e4c0651
[    0.042807][I]  github.com/YuzukiHD/SyterKit
[    0.048900][I] ***********************************
[    0.054992][I]  Built by: arm-none-eabi-gcc 13.2.1
[    0.061111][I]
[    0.063926][I] Model: AvaotaSBC Avaota A1 board.
[    0.069838][I] Core: Arm Octa-Core Cortex-A55 v65 r2p0
[    0.076304][I] Chip SID = 0300ff1071c048247590d120506d1ed4
[    0.083202][I] Chip type = A527M000000H Chip Version = 2
[    0.091016][I] PMU: Found AXP717 PMU, Addr 0x35
[    0.097828][I] PMU: Found AXP323 PMU
[    0.112524][I] DRAM BOOT DRIVE INFO: V0.6581
[    0.117998][I] Set DRAM Voltage to 1160mv
[    0.123161][I] DRAM_VCC set to 1160 mv
[    0.247583][I] DRAM retraining ten
[    0.265811][I] [AUTO DEBUG]32bit,2 ranks training success!
[    0.295960][I] Soft Training Version: T2.0
[    1.828055][I] [SOFT TRAINING] CLK=1200M Stable memtest pass
[    1.835018][I] DRAM CLK =1200 MHZ
[    1.839445][I] DRAM Type =8 (3:DDR3,4:DDR4,6:LPDDR2,7:LPDDR3,8:LPDDR4)
[    1.851607][I] DRAM SIZE =4096 MBytes, para1 = 310a, para2 = 10001000, tpr13 = 6061
[    1.861936][I] DRAM simple test OK.
[    1.866499][I] Init DRAM Done, DRAM Size = 4096M
[    2.286925][I] SMHC: sdhci0 controller initialized
[    2.314450][I]   Capacity: 59.48GB
[    2.319063][I] SHMC: SD card detected
[    2.328335][I] FATFS: read bl31.bin addr=48000000
[    2.348547][I] FATFS: read in 12ms at 6.41MB/S
[    2.354300][I] FATFS: read scp.bin addr=48100000
[    2.383544][I] FATFS: read in 21ms at 8.38MB/S
[    2.389299][I] FATFS: read extlinux/extlinux.conf addr=40020000
[    2.398254][I] FATFS: read in 1ms at 0.29MB/S
[    2.403910][I] FATFS: read splash.bin addr=40080000
[    2.411956][I] FATFS: read in 2ms at 6.33MB/S
[    3.202648][I] FATFS: read /Image addr=40800000
[    3.240875][I] FATFS: read in 33ms at 8.06MB/S
[    3.246629][I] FATFS: read /dtb/allwinner/sun55i-t527-avaota-a1.dtb addr=40400000
[    3.299473][I] FATFS: read in 20ms at 7.08MB/S
[    3.305224][I] FATFS: read /uInitrd addr=43000000
[    4.012885][I] FATFS: read in 702ms at 9.04MB/S
[    4.018733][I] Initrd load 0x43000000, Size 0x00632414
[    5.274685][W] FDT: bootargs is null, using extlinux.conf append.
[    5.573521][I] EXTLINUX: load extlinux done, now booting...
[    5.580516][I] ATF: Kernel addr: 0x40800000
[    5.586055][I] ATF: Kernel DTB addr: 0x40400000
[    5.775617][I] disable mmu ok...
[    5.780148][I] disable dcache ok...
[    5.785011][I] disable icache ok...
[    5.789873][I] free interrupt ok...
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
arm64_mmu_init: xlat tables:
arm64_mmu_init: base table(L0): 0x4083c000, 512 entries
arm64_mmu_init: 0: 0x40832000
arm64_mmu_init: 1: 0x40833000
arm64_mmu_init: 2: 0x40834000
arm64_mmu_init: 3: 0x40835000
arm64_mmu_init: 4: 0x40836000
arm64_mmu_init: 5: 0x40837000
arm64_mmu_init: 6: 0x40838000
arm64_mmu_init: 7: 0x40839000
arm64_mmu_init: 8: 0x4083a000
arm64_mmu_init: 9: 0x4083b000
setup_page_tables:
init_xlat_tables: mmap: virt 0x7000000 phys 0x7000000 size 0x20000000
set_pte_table_desc:
set_pte_table_desc: 0x4083c000: [Table] 0x40832000
set_pte_table_desc:
set_pte_table_desc: 0x40832000: [Table] 0x40833000
init_xlat_tables: mmap: virt 0x40000000 phys 0x40000000 size 0x8000000
set_pte_table_desc:
set_pte_table_desc: 0x40832008: [Table] 0x40834000
init_xlat_tables: mmap: virt 0x4010000000 phys 0x4010000000 size 0x10000000
set_pte_table_desc:
set_pte_table_desc: 0x40832800: [Table] 0x40835000
init_xlat_tables: mmap: virt 0x8000000000 phys 0x8000000000 size 0x8000000000
init_xlat_tables: mmap: virt 0x3eff0000 phys 0x3eff0000 size 0x10000
set_pte_table_desc:
set_pte_table_desc: 0x40833fb8: [Table] 0x40836000
init_xlat_tables: mmap: virt 0x40800000 phys 0x40800000 size 0x2a000
split_pte_block_desc: Splitting existing PTE 0x40834020(L2)
set_pte_table_desc:
set_pte_table_desc: 0x40834020: [Table] 0x40837000
init_xlat_tables: mmap: virt 0x4082a000 phys 0x4082a000 size 0x6000
init_xlat_tables: mmap: virt 0x40830000 phys 0x40830000 size 0x13000
init_xlat_tables: mmap: virt 0x40800000 phys 0x40800000 size 0x400000
enable_mmu_el1:
enable_mmu_el1: UP_MB
enable_mmu_el1: Enable the MMU and data cache
```

</span>

# Work In Progress

## Allwinner A537 Docs:
- https://linux-sunxi.org/A523
- https://linux-sunxi.org/File:A527_Datasheet_V0.93.pdf
- https://linux-sunxi.org/File:A523_User_Manual_V1.1_merged_cleaned.pdf

## UART0 Port is here:

```text
Page 1839
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

## Bootloader Log says that Start Address is 0x40800000. We change it...

Change start address to 0x40800000
- https://github.com/lupyuen2/wip-nuttx/commit/c38e1f7c014e1af648a33847fc795930ba995bca

Fix Image Load Offset. Print 123
- https://github.com/lupyuen2/wip-nuttx/commit/be2f1c55aa24eda9cd8652aa0bf38251335e9d01

Prints 123 yay!
- https://gist.github.com/lupyuen/14188c44049a14e3581523c593fdf2d8

Enable 16650 UART
- https://github.com/lupyuen2/wip-nuttx/commit/0cde58d84c16f255cb12e5a647ebeee3b6a8dd5f

## UART Buffer overflows. Let's wait for UART Ready...

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

## OK let's make this quicker. We do Passwordless Sudo for flipping our SDWire Mux...

https://help.ubuntu.com/community/Sudoers

```bash
sudo visudo
<<
user ALL=(ALL) NOPASSWD: /home/user/copy-image.sh
>>
```

Edit /home/user/copy-image.sh <br> (Remember to chmod +x /home/user/copy-image.sh)

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

Build Script
- https://gist.github.com/lupyuen/a4ac110fb8610a976c0ce2621cbb8587

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

CONFIG_ARCH_PGPOOL_PBASE should match pgram
- https://github.com/lupyuen2/wip-nuttx/commit/eb33ac06f88dda557bc8ac97bec7d6cbad4ccb86

Still stuck at: `enable_mmu_el1: Enable the MMU and data cache`
- https://gist.github.com/lupyuen/544a5d8f3fab2ab7c9d06d2e1583f362

## Hmmm the Peripheral Address Space is missing. UART0 will crash!

Memory Map: Page 42

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

## Let's do some MMU Logging and fix the Peripheral Address Space...

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

## Whoa Heap Size is wrong! Let's find out why...

Assert CONFIG_RAM_END > g_idle_topstack
- https://github.com/lupyuen2/wip-nuttx/commit/480bbc64af4ca64c104964c24f430c6de48326b5

Assertion fails
- https://gist.github.com/lupyuen/5f97773dcafc345a3510851629095c92

```text
up_allocate_kheap: CONFIG_RAM_END=0x40800000, g_idle_topstack=0x40843000
dump_assert_info: Assertion failed
```

## Oops CONFIG_RAM_END is too small. Let's enlarge...

CONFIG_RAM_SIZE should match CONFIG_RAMBANK1_SIZE
- https://github.com/lupyuen2/wip-nuttx/commit/c8fbc5b86c2bf1dd7b8243b301b0790115c9c4ca

GIC Failed
- https://gist.github.com/lupyuen/3a7d1e791ac14905532db2d768ae230f

```text
gic_validate_dist_version: No GIC version detect
arm64_gic_initialize: no distributor detected, giving up ret=-19
```

## Ah we forgot the GIC Address!

Page 263
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

## TODO: Load the NuttX Apps into RAM
