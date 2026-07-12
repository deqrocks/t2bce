# Apple T2 BCE modules

This repository contains the Apple T2 BCE driver stack.
It is intended as a testable replacement for `apple-bce` on t2linux distros 
before the drivers are prepared for upstream submission.

T2linux users should test it by blacklisting `apple-bce`, installing these modules, and
rebooting.

## Changes compared to apple-bce

User noticeable changes are

- Lower power draw on media playback and when the Mac is turned off
- Increased suspend/resume stability
- Automatic switching between headphones/internal speakers
- Less audio stutter issues
- Silent logs

T2bce is an MFD driver that is divided into separate kernel modules:

- `t2bce_core` - PCI device, mailbox, transport API and PM coordination
- `t2bce_dma` - BCE DMA queue engine
- `t2bce_vhci` - virtual USB 2.0 host controller for bridgeOS devices
- `t2bce_audio` - ALSA driver for Apple T2 audio endpoints

This layout is closer to the hardware model than apple-bce: the PCI/BCE core, DMA queues,
virtual USB host controller, and audio driver are separate pieces of one stack.
It also makes logs and module dependencies easier to inspect when testing.

- VHCI submits scatter-gather USB URBs as BCE segment lists instead of forcing
  all transfers through one contiguous DMA buffer. This is especially relevant
  for higher-bandwidth bridgeOS USB devices such as the internal camera.
- PM path handling is coordinated through the BCE core.
- Audio is a separate ALSA driver module with an ALSA UCM profile for
  desktop routing. The kernel layout exposes the physical T2 audio endpoints as
  separate PCMs, and the UCM profile maps them to normal desktop ports.
- Transport and queue APIs, so audio and VHCI no longer need to reach into BCE
  queue internals directly.

## Debugging

t2bce_audio uses `pr_debug` instead of `pr_info` for keeping the journal clean.
You can dynamically activate verbose logging by running

``` 
echo 'module t2bce_audio +p' | sudo tee /proc/dynamic_debug/control
```
This will activate debug logs for `t2bce_audio`. You can also replace it with `t2bce_dma` or `t2bce_vhci`...

## Requirements

Install the kernel headers/build files for the running kernel. On Fedora for example:

```sh
sudo dnf install kernel-devel kernel-headers make gcc
```

## Build and install

```sh
make && sudo make install
```

`make install` installs the modules below `/lib/modules/$(uname -r)/extra/t2bce`,
installs the ALSA UCM profile below `/usr/share/alsa/ucm2`, and runs `depmod`.

## Kernel tree export

The driver sources can be exported with in-tree Kconfig and Kbuild files for
distribution kernel patch is:

```sh
./export-kernel-tree.sh /path/to/linux/drivers/staging/t2bce
```

The export contains only kernel sources. DKMS files, standalone build targets,
documentation, and the ALSA UCM profile are intentionally excluded.

To generate the two patches used by the t2linux kernel patch set from a Linux
git tree, run:

```sh
./generate-kernel-patches.sh /path/to/linux /path/to/output
```

The generator works in a temporary clone and does not modify the supplied
Linux tree. It refuses to overwrite existing T2BCE patches.

## Blacklist apple-bce

Blacklist `apple-bce` on initcall using GRUB:

```sh
initcall_blacklist=apple_bce
```
Don't forget to update GRUB.
Reboot after installation so the old `apple-bce` module cannot bind first.
After reboot, check with `journalctl -b --grep=apple_bce`. It should show

```
Module apple_bce is blacklisted
```

## Quick checks

```sh
lsmod | grep -E 't2bce|apple_bce|apple-bce'
modinfo t2bce_core
modinfo t2bce_dma
modinfo t2bce_vhci
modinfo t2bce_audio
aplay -l
```

## Uninstall

```sh
sudo make uninstall
sudo rm -f /etc/modprobe.d/blacklist-apple-bce.conf
```

Reboot after uninstalling if any T2 BCE module was loaded.
