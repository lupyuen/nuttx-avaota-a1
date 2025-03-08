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

## TODO: Bundle the NuttX Apps into ROMFS

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

[(See the __Build Log__)](https://gist.github.com/lupyuen/c7aebd4616db0167f12166fe2bc7ffa1)

(__copy-image.sh__ is explained below)

# Boot NuttX for Avaota-A1

Here's the latest NuttX Boot Log:
- https://gist.github.com/lupyuen/3c587ac0f32be155c8f9a9e4ca18676c

<span style="font-size:60%">

```text
[    0.000255][I]  _____     _           _____ _ _
[    0.006320][I] |   __|_ _| |_ ___ ___|  |  |_| |_
[    0.012456][I] |__   | | |  _| -_|  _|    -| | _|
[    0.018592][I] |_____|_  |_| |___|_| |__|__|_|_|
[    0.024745][I]       |___|
[    0.030846][I] ***********************************
[    0.036965][I]  SyterKit v0.4.0 Commit: e4c0651
[    0.042832][I]  github.com/YuzukiHD/SyterKit
[    0.048968][I] ***********************************
[    0.055070][I]  Built by: arm-none-eabi-gcc 13.2.1
[    0.061197][I]
[    0.064021][I] Model: AvaotaSBC Avaota A1 board.
[    0.069942][I] Core: Arm Octa-Core Cortex-A55 v65 r2p0
[    0.076434][I] Chip SID = 0300ff1071c048247590d120506d1ed4
[    0.083358][I] Chip type = A527M000000H Chip Version = 2
[    0.091477][I] PMU: Found AXP717 PMU, Addr 0x35
[    0.098287][I] PMU: Found AXP323 PMU
[    0.112983][I] DRAM BOOT DRIVE INFO: V0.6581
[    0.118448][I] Set DRAM Voltage to 1160mv
[    0.123654][I] DRAM_VCC set to 1160 mv
[    0.248092][I] DRAM retraining ten
[    0.266349][I] [AUTO DEBUG]32bit,2 ranks training success!
[    0.296518][I] Soft Training Version: T2.0
[    1.817356][I] [SOFT TRAINING] CLK=1200M Stable memtest pass
[    1.824307][I] DRAM CLK =1200 MHZ
[    1.828761][I] DRAM Type =8 (3:DDR3,4:DDR4,6:LPDDR2,7:LPDDR3,8:LPDDR4)
[    1.840870][I] DRAM SIZE =4096 MBytes, para1 = 310a, para2 = 10001000, tpr13 = 6061
[    1.851216][I] DRAM simple test OK.
[    1.855823][I] Init DRAM Done, DRAM Size = 4096M
[    2.276387][I] SMHC: sdhci0 controller initialized
[    2.303911][I]   Capacity: 59.48GB
[    2.308522][I] SHMC: SD card detected
[    2.317620][I] FATFS: read bl31.bin addr=48000000
[    2.337822][I] FATFS: read in 13ms at 5.92MB/S
[    2.343579][I] FATFS: read scp.bin addr=48100000
[    2.372799][I] FATFS: read in 22ms at 8.00MB/S
[    2.378551][I] FATFS: read extlinux/extlinux.conf addr=40020000
[    2.387505][I] FATFS: read in 1ms at 0.29MB/S
[    2.393162][I] FATFS: read splash.bin addr=40080000
[    2.401207][I] FATFS: read in 1ms at 12.66MB/S
[    3.192009][I] FATFS: read /Image addr=40800000
[    3.299954][I] FATFS: read in 103ms at 8.76MB/S
[    3.305804][I] FATFS: read /dtb/allwinner/sun55i-t527-avaota-a1.dtb addr=40400000
[    3.358608][I] FATFS: read in 20ms at 7.08MB/S
[    3.364360][I] FATFS: read /uInitrd addr=43000000
[    4.071917][I] FATFS: read in 701ms at 9.05MB/S
[    4.077768][I] Initrd load 0x43000000, Size 0x00632414
[    5.346100][W] FDT: bootargs is null, using extlinux.conf append.
[    5.644926][I] EXTLINUX: load extlinux done, now booting...
[    5.651919][I] ATF: Kernel addr: 0x40800000
[    5.657460][I] ATF: Kernel DTB addr: 0x40400000
[    5.847029][I] disable mmu ok...
[    5.851558][I] disable dcache ok...
[    5.856422][I] disable icache ok...
[    5.861287][I] free interrupt ok...
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
init_xlat_tables: name=DEVICE_REGION
init_xlat_tables: mmap: virt 0 phys 0 size 0x40000000
set_pte_table_desc:
set_pte_table_desc: 0x4083c000: [Table] 0x40832000
init_xlat_tables: name=DRAM0_S0
init_xlat_tables: mmap: virt 0x40000000 phys 0x40000000 size 0x8000000
set_pte_table_desc:
set_pte_table_desc: 0x40832008: [Table] 0x40833000
init_xlat_tables: name=nx_code
init_xlat_tables: mmap: virt 0x40800000 phys 0x40800000 size 0x28000
split_pte_block_desc: Splitting existing PTE 0x40833020(L2)
set_pte_table_desc:
set_pte_table_desc: 0x40833020: [Table] 0x40834000
init_xlat_tables: name=nx_rodata
init_xlat_tables: mmap: virt 0x40828000 phys 0x40828000 size 0x8000
init_xlat_tables: name=nx_data
init_xlat_tables: mmap: virt 0x40830000 phys 0x40830000 size 0x13000
init_xlat_tables: name=nx_pgpool
init_xlat_tables: mmap: virt 0x40a00000 phys 0x40a00000 size 0x400000
enable_mmu_el1:
enable_mmu_el1: UP_MB
enable_mmu_el1: Enable the MMU and data cache
enable_mmu_el1: UP_ISB
enable_mmu_el1: MMU enabled with dcache
nx_start: Entryetected PSCI v1.1
up_allocate_kheap: CONFIG_RAM_END=0x48000000, g_idle_topstack=0x40843000
up_allocate_kheap: heap_start=0x0x40843000, heap_size=0x77bd000
gic_validate_dist_version: GICv3 version detect
gic_validate_dist_version: GICD_TYPER = 0x7b0408
gic_validate_dist_version: 256 SPIs implemented
gic_validate_dist_version: 0 Extended SPIs implemented
gic_validate_dist_version: Distributor has no Range Selector support
gic_validate_dist_version: MBIs is present, But No support
gic_validate_redist_version: GICR_TYPER = 0x21
gic_validate_redist_version: 16 PPIs implemented
gic_validate_redist_version: no VLPI support, no direct LPI support
uart_register: Registering /dev/console
uart_register: Registering /dev/ttyS0
work_start_highpri: Starting high-priority kernel worker thread(s)
nxtask_activate: hpwork pid=1,TCB=0x40843e78
work_start_lowpri: Starting low-priority kernel worker thread(s)
nxtask_activate: lpwork pid=2,TCB=0x40846008
nxtask_activate: AppBringUp pid=3,TCB=0x40846190
qemu_bringup:
mount_ramdisk:
nx_start_application: ret=0
nx_start_application: Starting init task: /system/bin/init
nxtask_activate: /system/bin/init pid=4,TCB=0x408469f0
nxtask_exit: AppBringUp pid=3,TCB=0x40846190
board_app_initialize:
nx_start: CPU0: Beginning Idle Loop
set_pte_table_desc:
set_pte_table_desc: 0x4083c000: [Table] 0x40832000
init_xlat_tables: name=DRAM0_S0
init_xlat_tables: mmap: virt 0x40000000 phys 0x40000000 size 0x8000000
set_pte_table_desc:
set_pte_table_desc: 0x40832008: [Table] 0x40833000
init_xlat_tables: name=nx_code
init_xlat_tables: mmap: virt 0x40800000 phys 0x40800000 size 0x28000
split_pte_block_desc: Splitting existing PTE 0x40833020(L2)
set_pte_table_desc:
set_pte_table_desc: 0x40833020: [Table] 0x40834000
init_xlat_tables: name=nx_rodata
init_xlat_tables: mmap: virt 0x40828000 phys 0x40828000 size 0x8000
init_xlat_tables: name=nx_data
init_xlat_tables: mmap: virt 0x40830000 phys 0x40830000 size 0x13000
init_xlat_tables: name=nx_pgpool
init_xlat_tables: mmap: virt 0x40a00000 phys 0x40a00000 size 0x400000
enable_mmu_el1:
enable_mmu_el1: UP_MB
enable_mmu_el1: Enable the MMU and data cache
enable_mmu_el1: UP_ISB
enable_mmu_el1: MMU enabled with dcache
nx_start: Entryetected PSCI v1.1
up_allocate_kheap: CONFIG_RAM_END=0x48000000, g_idle_topstack=0x40843000
up_allocate_kheap: heap_start=0x0x40843000, heap_size=0x77bd000
gic_validate_dist_version: GICv3 version detect
gic_validate_dist_version: GICD_TYPER = 0x7b0408
gic_validate_dist_version: 256 SPIs implemented
gic_validate_dist_version: 0 Extended SPIs implemented
gic_validate_dist_version: Distributor has no Range Selector support
gic_validate_dist_version: MBIs is present, But No support
gic_validate_redist_version: GICR_TYPER = 0x21
gic_validate_redist_version: 16 PPIs implemented
gic_validate_redist_version: no VLPI support, no direct LPI support
uart_register: Registering /dev/console
uart_register: Registering /dev/ttyS0
work_start_highpri: Starting high-priority kernel worker thread(s)
nxtask_activate: hpwork pid=1,TCB=0x40843e78
work_start_lowpri: Starting low-priority kernel worker thread(s)
nxtask_activate: lpwork pid=2,TCB=0x40846008
nxtask_activate: AppBringUp pid=3,TCB=0x40846190
qemu_bringup:
mount_ramdisk:
nx_start_application: ret=0
nx_start_application: Starting init task: /system/bin/init
nxtask_activate: /system/bin/init pid=4,TCB=0x408469f0
nxtask_exit: AppBringUp pid=3,TCB=0x40846190
board_app_initialize:
nx_start: CPU0: Beginning Idle Loop
set_pte_table_desc:
set_pte_table_desc: 0x4083c000: [Table] 0x40832000
init_xlat_tables: name=DRAM0_S0
init_xlat_tables: mmap: virt 0x40000000 phys 0x40000000 size 0x8000000
set_pte_table_desc:
set_pte_table_desc: 0x40832008: [Table] 0x40833000
init_xlat_tables: name=nx_code
init_xlat_tables: mmap: virt 0x40800000 phys 0x40800000 size 0x28000
split_pte_block_desc: Splitting existing PTE 0x40833020(L2)
set_pte_table_desc:
set_pte_table_desc: 0x40833020: [Table] 0x40834000
init_xlat_tables: name=nx_rodata
init_xlat_tables: mmap: virt 0x40828000 phys 0x40828000 size 0x8000
init_xlat_tables: name=nx_data
init_xlat_tables: mmap: virt 0x40830000 phys 0x40830000 size 0x13000
init_xlat_tables: name=nx_pgpool
init_xlat_tables: mmap: virt 0x40a00000 phys 0x40a00000 size 0x400000
enable_mmu_el1:
enable_mmu_el1: UP_MB
enable_mmu_el1: Enable the MMU and data cache
enable_mmu_el1: UP_ISB
enable_mmu_el1: MMU enabled with dcache
nx_start: Entryetected PSCI v1.1
up_allocate_kheap: CONFIG_RAM_END=0x48000000, g_idle_topstack=0x40843000
up_allocate_kheap: heap_start=0x0x40843000, heap_size=0x77bd000
gic_validate_dist_version: GICv3 version detect
gic_validate_dist_version: GICD_TYPER = 0x7b0408
gic_validate_dist_version: 256 SPIs implemented
gic_validate_dist_version: 0 Extended SPIs implemented
gic_validate_dist_version: Distributor has no Range Selector support
gic_validate_dist_version: MBIs is present, But No support
gic_validate_redist_version: GICR_TYPER = 0x21
gic_validate_redist_version: 16 PPIs implemented
gic_validate_redist_version: no VLPI support, no direct LPI support
uart_register: Registering /dev/console
uart_register: Registering /dev/ttyS0
work_start_highpri: Starting high-priority kernel worker thread(s)
nxtask_activate: hpwork pid=1,TCB=0x40843e78
work_start_lowpri: Starting low-priority kernel worker thread(s)
nxtask_activate: lpwork pid=2,TCB=0x40846008
nxtask_activate: AppBringUp pid=3,TCB=0x40846190
qemu_bringup:
mount_ramdisk:
nx_start_application: ret=0
nx_start_application: Starting init task: /system/bin/init
nxtask_activate: /system/bin/init pid=4,TCB=0x408469f0
nxtask_exit: AppBringUp pid=3,TCB=0x40846190
board_app_initialize:
nx_start: CPU0: Beginning Idle Loop
set_pte_table_desc:
set_pte_table_desc: 0x4083c000: [Table] 0x40832000
init_xlat_tables: name=DRAM0_S0
init_xlat_tables: mmap: virt 0x40000000 phys 0x40000000 size 0x8000000
set_pte_table_desc:
set_pte_table_desc: 0x40832008: [Table] 0x40833000
init_xlat_tables: name=nx_code
init_xlat_tables: mmap: virt 0x40800000 phys 0x40800000 size 0x28000
split_pte_block_desc: Splitting existing PTE 0x40833020(L2)
set_pte_table_desc:
set_pte_table_desc: 0x40833020: [Table] 0x40834000
init_xlat_tables: name=nx_rodata
init_xlat_tables: mmap: virt 0x40828000 phys 0x40828000 size 0x8000
init_xlat_tables: name=nx_data
init_xlat_tables: mmap: virt 0x40830000 phys 0x40830000 size 0x13000
init_xlat_tables: name=nx_pgpool
init_xlat_tables: mmap: virt 0x40a00000 phys 0x40a00000 size 0x400000
enable_mmu_el1:
enable_mmu_el1: UP_MB
enable_mmu_el1: Enable the MMU and data cache
enable_mmu_el1: UP_ISB
enable_mmu_el1: MMU enabled with dcache
nx_start: Entryetected PSCI v1.1
up_allocate_kheap: CONFIG_RAM_END=0x48000000, g_idle_topstack=0x40843000
up_allocate_kheap: heap_start=0x0x40843000, heap_size=0x77bd000
gic_validate_dist_version: GICv3 version detect
gic_validate_dist_version: GICD_TYPER = 0x7b0408
gic_validate_dist_version: 256 SPIs implemented
gic_validate_dist_version: 0 Extended SPIs implemented
gic_validate_dist_version: Distributor has no Range Selector support
gic_validate_dist_version: MBIs is present, But No support
gic_validate_redist_version: GICR_TYPER = 0x21
gic_validate_redist_version: 16 PPIs implemented
gic_validate_redist_version: no VLPI support, no direct LPI support
uart_register: Registering /dev/console
uart_register: Registering /dev/ttyS0
work_start_highpri: Starting high-priority kernel worker thread(s)
nxtask_activate: hpwork pid=1,TCB=0x40843e78
work_start_lowpri: Starting low-priority kernel worker thread(s)
nxtask_activate: lpwork pid=2,TCB=0x40846008
nxtask_activate: AppBringUp pid=3,TCB=0x40846190
qemu_bringup:
mount_ramdisk:
nx_start_application: ret=0
nx_start_application: Starting init task: /system/bin/init
nxtask_activate: /system/bin/init pid=4,TCB=0x408469f0
nxtask_exit: AppBringUp pid=3,TCB=0x40846190
board_app_initialize:
nx_start: CPU0: Beginning Idle Loop
set_pte_table_desc:
set_pte_table_desc: 0x4083c000: [Table] 0x40832000
init_xlat_tables: name=DRAM0_S0
init_xlat_tables: mmap: virt 0x40000000 phys 0x40000000 size 0x8000000
set_pte_table_desc:
set_pte_table_desc: 0x40832008: [Table] 0x40833000
init_xlat_tables: name=nx_code
init_xlat_tables: mmap: virt 0x40800000 phys 0x40800000 size 0x28000
split_pte_block_desc: Splitting existing PTE 0x40833020(L2)
set_pte_table_desc:
set_pte_table_desc: 0x40833020: [Table] 0x40834000
init_xlat_tables: name=nx_rodata
init_xlat_tables: mmap: virt 0x40828000 phys 0x40828000 size 0x8000
init_xlat_tables: name=nx_data
init_xlat_tables: mmap: virt 0x40830000 phys 0x40830000 size 0x13000
init_xlat_tables: name=nx_pgpool
init_xlat_tables: mmap: virt 0x40a00000 phys 0x40a00000 size 0x400000
enable_mmu_el1:
enable_mmu_el1: UP_MB
enable_mmu_el1: Enable the MMU and data cache
enable_mmu_el1: UP_ISB
enable_mmu_el1: MMU enabled with dcache
nx_start: Entryetected PSCI v1.1
up_allocate_kheap: CONFIG_RAM_END=0x48000000, g_idle_topstack=0x40843000
up_allocate_kheap: heap_start=0x0x40843000, heap_size=0x77bd000
gic_validate_dist_version: GICv3 version detect
gic_validate_dist_version: GICD_TYPER = 0x7b0408
gic_validate_dist_version: 256 SPIs implemented
gic_validate_dist_version: 0 Extended SPIs implemented
gic_validate_dist_version: Distributor has no Range Selector support
gic_validate_dist_version: MBIs is present, But No support
gic_validate_redist_version: GICR_TYPER = 0x21
gic_validate_redist_version: 16 PPIs implemented
gic_validate_redist_version: no VLPI support, no direct LPI support
uart_register: Registering /dev/console
uart_register: Registering /dev/ttyS0
work_start_highpri: Starting high-priority kernel worker thread(s)
nxtask_activate: hpwork pid=1,TCB=0x40843e78
work_start_lowpri: Starting low-priority kernel worker thread(s)
nxtask_activate: lpwork pid=2,TCB=0x40846008
nxtask_activate: AppBringUp pid=3,TCB=0x40846190
qemu_bringup:
mount_ramdisk:
nx_start_application: ret=0
nx_start_application: Starting init task: /system/bin/init
nxtask_activate: /system/bin/init pid=4,TCB=0x408469f0
nxtask_exit: AppBringUp pid=3,TCB=0x40846190
board_app_initialize:
nx_start: CPU0: Beginning Idle Loop
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

Is /dev/ram0 created?

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

## TODO: Fix the UART Interrupt
