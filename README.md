# Jellyfin QPKG for QNAP

[繁體中文說明 (Traditional Chinese)](README.zh-TW.md)

> [!IMPORTANT]
> This is an **unofficial, community-maintained** package. It is not affiliated with or endorsed by the Jellyfin project or QNAP. It automates the deployment of the **official, unmodified** Jellyfin Docker image via Container Station. If you prefer full manual control, you can achieve the same setup yourself with Container Station and Docker Compose — see the [Jellyfin QNAP installation guide](https://jellyfin.org/docs/general/installation/).

## What It Is

This is a QPKG package designed to simplify the installation of Jellyfin on QNAP NAS devices. It uses QNAP's Container Station and the official Jellyfin Docker image ([jellyfin/jellyfin](https://hub.docker.com/r/jellyfin/jellyfin)) with the **latest** tag. Jellyfin is an open-source media server solution that helps you manage and stream your media content seamlessly across devices. This QPKG is built using QNAP's **QDK Kit**, ensuring compatibility with QNAP systems while leveraging the power of Jellyfin's Docker image.

### About this Fork

This repository is a fork of [kajain99/Jellyfin-QPKG](https://github.com/kajain99/Jellyfin-QPKG). Since the original repository is no longer updated and its installation script fails on newer QNAP firmware (such as QuTS Hero 6.0 and QTS 6.0) due to hardcoded Container Station paths and shell symlink resolution bugs, this fork optimizes the routines to provide:

- **Full compatibility with QuTS Hero 6.0 and QTS 6.0 / 5.x**.
- **Volume-agnostic Container Station path detection** (reads path dynamically from `/etc/config/qpkg.conf`).
- **Robust Docker and Compose command lookup** (supporting both modern CLI `docker compose` and standalone `docker-compose`).
- **Jellyfin Docker image configured to `latest`** instead of the legacy `10.8.10`.
- **Automatic Intel GPU (/dev/dri) Passthrough**: If an Intel integrated GPU is detected on the QNAP host, the QPKG automatically passes `/dev/dri` to the container to enable hardware transcoding (QSV / VA-API) out-of-the-box.
- **Automatic NVIDIA GPU Passthrough**: If an NVIDIA GPU is installed and the `NVIDIA_GPU_DRV` driver package is active on the QNAP host, the QPKG automatically maps the `/dev/nvidia*` device nodes (including `/dev/nvidia-uvm`) and the driver library path inside the container, enabling NVIDIA NVENC/NVDEC hardware transcoding.
- **Verified Models**: Tested and verified to work seamlessly on QNAP **TS-464**, **TS-855X**, **TS-673A**, and **TS-h1277AFX**.

---

## What It Needs

To use this QPKG, you will need:

- A QNAP NAS with **Container Station** installed and configured.
- App Center temporarily configured to allow unsigned applications (see the security note below).

### Security Note: Unsigned Package

This QPKG is **not digitally signed**, because individual developers cannot register a signing key with the QNAP App Center. Installing unsigned packages carries inherent risk, so please take the following precautions:

1. **Only download the `.qpkg` file from this repository's [Releases](https://github.com/ivanusto/Jellyfin-QPKG/releases) page.** Do not install copies obtained elsewhere.
2. **Verify the checksum.** Every release is built automatically by GitHub Actions from the source in this repository, and ships with a `SHA256SUMS` file. After downloading, verify with:

   ```shell
   sha256sum -c SHA256SUMS
   ```

3. **Review the source.** The package consists of readable shell scripts (`package_routines`, `shared/`) — you can audit exactly what it does before installing.
4. **Re-disable unsigned installation after installing.** The App Center setting applies globally to all packages, so it is recommended to turn it back off once installation is complete.

---

## How to Install

### Step 1: Enable Unsigned Package Installation

1. Open your QNAP **App Center**.
2. Navigate to **Settings** > **General**.
3. Check the option **Allow installation of applications without valid signatures**.

### Step 2: Install the QPKG

1. Download the Jellyfin QPKG and `SHA256SUMS` from [this repository's Releases section](https://github.com/ivanusto/Jellyfin-QPKG/releases) and verify the checksum.
2. In the App Center, click **Install Manually**.
3. Select the downloaded QPKG file and follow the on-screen instructions.
4. After installation completes, consider unchecking **Allow installation of applications without valid signatures** again.

![allow unsigned applications](https://www.thestorageguy.net/content/images/2025/01/image.png)

### Step 3: Initial Run

- When you run the application for the first time, all available QNAP shares will be mounted to **`/mnt`**.
- On the first run, you may see the **Select Server** screen. If so:
  - Open a web browser and go to:
    `http://<your-qnap-ip>:8096/web/#/wizardstart.html`
    (Replace `<your-qnap-ip>` with your QNAP's IP address, e.g., `192.168.1.100`.)
  - Follow the on-screen steps to complete the initial setup, including setting your username and password.

![if you see this screen you need to run the first time setup wizard](https://www.thestorageguy.net/content/images/2025/01/image-1.png)
![first time setup screen](https://www.thestorageguy.net/content/images/2025/01/image-2.png)

---

## Adding Media Libraries

Once Jellyfin is set up, you can easily add your media libraries:

1. Go to the Jellyfin web interface.
2. Navigate to **Add Library**.
3. Select the appropriate folders under **`/mnt`**, where all your QNAP shares are mounted.

---

## GPU Hardware Transcoding (Intel / NVIDIA)

### Intel iGPU (QSV / VA-API)

If your QNAP NAS has an Intel CPU with integrated graphics (e.g. TS-464), this QPKG automatically detects it and passes `/dev/dri` to the container. To use hardware acceleration:

1. Log in to the Jellyfin web interface.
2. Go to **Dashboard** > **Playback** > **Transcoding**.
3. Set **Hardware acceleration** to **Intel QuickSync (QSV)** or **Intel VA-API**.

> [!NOTE]
> On some QNAP firmware versions, `/dev/dri` device permissions are restricted to the `admin` group. If hardware transcoding fails (e.g. playback errors when transcoding), you may need to run `chmod -R 666 /dev/dri` via SSH so the container user can access the render node. Be aware of the trade-offs: this grants all local processes access to the GPU device nodes, and because QTS regenerates `/dev` on reboot, the change is **not persistent** — you will need to re-apply it after a reboot (e.g. via an autorun script).

### NVIDIA dGPU (NVENC / NVDEC)

If your QNAP NAS has an NVIDIA graphics card installed:

1. Ensure the **NVIDIA GPU Driver** QPKG is installed and active via the QNAP App Center.
2. In the QNAP Control Panel, go to **System** > **Hardware** > **Graphics Card**, and assign the GPU resource to **Container Station**. Without this step, QTS keeps the GPU bound to the host and containers cannot use it.
3. The QPKG will automatically detect the GPU and map the driver libraries and device nodes (`/dev/nvidia0`, `/dev/nvidiactl`, `/dev/nvidia-uvm`, `/dev/nvidia-uvm-tools`) inside the container. QTS does not support the standard NVIDIA Container Toolkit, which is why this manual mapping is handled by the package.
4. In the Jellyfin web interface, go to **Dashboard** > **Playback** > **Transcoding**.
5. Set **Hardware acceleration** to **Nvidia NVENC**.

---

## Building from Source

Releases are built automatically by [GitHub Actions](.github/workflows/release.yml) using QNAP's [QDK](https://github.com/qnap-dev/QDK). To build locally:

```shell
git clone https://github.com/qnap-dev/QDK.git && cd QDK && sudo ./InstallToUbuntu.sh install
cd /path/to/Jellyfin-QPKG
qbuild   # output in ./build/
```

---

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE). See [NOTICE.md](NOTICE.md) for details on the provenance of code inherited from the original upstream project and trademark attributions.

## Credits

- Forked and updated by [ivanusto](https://github.com/ivanusto).
- Original version built by [kajain99](https://github.com/kajain99) using QNAP's QDK Kit.
- Powered by the official Jellyfin Docker image: [jellyfin/jellyfin](https://hub.docker.com/r/jellyfin/jellyfin).

---

Enjoy your Jellyfin media server on QNAP!
