---
uid: installation-qnap
title: QNAP
description: Install on QNAP NAS.
sidebar_position: 3
---

import DockerCompose from '../_container-docker-compose.md';

# Installation on QNAP

:::caution Pre-built NAS Devices

Many pre-built NAS devices are underpowered. We generally do not recommend running Jellyfin on those devices.
See [Hardware Selection](/docs/general/administration/hardware-selection) for more information.

:::

For [QNAP](https://www.qnap.com/), Jellyfin can be installed either automatically via a community-maintained QPKG package or manually using Container Station (Docker / Docker Compose).

## Method 1: Community-Maintained QPKG (Recommended)

A community-maintained QPKG package ([Jellyfin-QPKG](https://github.com/ivanusto/Jellyfin-QPKG)) is available to simplify installation. It automatically configures Container Station to run the official Docker container, mounts your shared folders under `/mnt`, and auto-detects GPU resources for hardware transcoding.

This package has been verified to work on models such as TS-464, TS-855X, TS-673A, and TS-h1277AFX.

### Installation Steps

1. **Enable Installation of Unsigned Packages**:
   - Open QNAP **App Center**.
   - Go to **Settings** > **General**.
   - Check **Allow installation of applications without valid signatures**.

2. **Download and Install**:
   - Download the latest `.qpkg` file from the [Jellyfin-QPKG Releases](https://github.com/ivanusto/Jellyfin-QPKG/releases).
   - In App Center, click the **Install Manually** icon in the top right.
   - Select the downloaded file and complete the wizard.

3. **Initial Configuration**:
   - All QNAP shared folders are automatically mounted to `/mnt` inside the container.
   - Access the Jellyfin web interface at `http://<QNAP-IP>:8096` to run the startup wizard.

---

## Installation via Container Station (Docker Compose)

QNAP's built-in **Container Station** runs standard Docker Compose, so the general container installation instructions apply directly:

<DockerCompose />

### QNAP-Specific Notes

- **Requirements**: Container Station 3 or later (QTS / QuTS hero 5.x+) is required, as it ships Compose v2. The compose file above has no `version:` key, which the older Compose bundled with Container Station 2 does not accept.
- **Where to paste the compose file**: In Container Station, go to **Applications** > **Create**, paste the compose content, and deploy. Alternatively, deploy via SSH with `docker compose up -d` from the project folder.
- **Path conventions**: Replace the placeholder paths with QNAP shared-folder paths. Pre-create the config and cache folders first, for example:
  - `/path/to/config` → `/share/Container/jellyfin/config`
  - `/path/to/cache` → `/share/Container/jellyfin/cache`
  - `/path/to/media` → `/share/Multimedia` (mounting media read-only is recommended)
- **`user: uid:gid`**: The optional `user:` line works as-is with default QNAP shared-folder permissions, since folders created inside a shared folder are world-writable by default. If you use advanced folder permissions (Windows ACL), verify that the chosen uid can write to the config and cache folders. Pre-creating the folders (as above) also avoids Docker auto-creating them as root-owned, which would block a non-root uid.
- **DLNA / auto-discovery**: Jellyfin no longer ships DLNA out of the box. If you install the DLNA plugin, host networking is required — see the [DLNA networking guide](/docs/general/post-install/networking/dlna#general) for the reasoning and configuration.

---

## GPU Hardware Transcoding

To enable hardware transcoding (QSV, VA-API, or NVENC/NVDEC) on QNAP NAS devices:

### Intel QuickSync (QSV) / Intel VA-API
If your QNAP NAS has an Intel CPU with integrated graphics, map the iGPU device to the container:

1. **Device Mapping**: Add the device mapping in your Docker Compose or run command:
   ```yaml
   devices:
     - /dev/dri:/dev/dri
   ```
2. **Permissions**: On some QNAP QTS/QuTS Hero versions, `/dev/dri` permissions are restricted to the `admin` user/group. You may need to run `chmod -R 777 /dev/dri` via SSH to allow the container access.
3. **Jellyfin Settings**: In Jellyfin web UI, navigate to **Dashboard** > **Playback** > **Transcoding**, set **Hardware acceleration** to **Intel QuickSync (QSV)** or **Intel VA-API**.

### NVIDIA NVENC / NVDEC
If your QNAP NAS has a compatible NVIDIA graphics card installed:

1. Install the **NVIDIA GPU Driver** from the QNAP App Center.
2. Go to **Control Panel** > **System** > **Hardware** > **Graphics Card** and assign the GPU resource to **Container Station**.
3. QTS/QuTS hero does not provide the NVIDIA Container Toolkit, so the device nodes and driver libraries must be mapped manually in the compose file. Find the driver installation path with `/sbin/getcfg NVIDIA_GPU_DRV Install_Path -f /etc/config/qpkg.conf` via SSH, then add:

   ```yaml
   devices:
     - /dev/nvidia0:/dev/nvidia0
     - /dev/nvidiactl:/dev/nvidiactl
     - /dev/nvidia-uvm:/dev/nvidia-uvm
   volumes:
     - <NVIDIA_GPU_DRV Install_Path>/usr:/usr/local/nvidia:ro
   environment:
     - LD_LIBRARY_PATH=/usr/local/nvidia/lib64
     - NVIDIA_VISIBLE_DEVICES=all
     - NVIDIA_DRIVER_CAPABILITIES=all
   ```

4. In Jellyfin web UI, set **Hardware acceleration** to **Nvidia NVENC**.
