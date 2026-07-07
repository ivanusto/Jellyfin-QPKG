# Jellyfin QPKG for QNAP (QNAP 專用的 Jellyfin QPKG 整合套件)

[English Version (英文版)](README.md)

## 這是什麼

這是一個為簡化在 QNAP NAS 設備上安裝 Jellyfin 而設計的 QPKG 套件。它整合了 QNAP 的 Container Station 並使用官方的 Jellyfin Docker 映像檔 ([jellyfin/jellyfin](https://hub.docker.com/r/jellyfin/jellyfin)) 與 **latest** 標籤。Jellyfin 是一個開源的媒體伺服器解決方案，可幫助您在不同設備之間流暢地管理和串流您的媒體內容。本 QPKG 是使用 QNAP 官方的 **QDK Kit** 工具建置的，確保與 QNAP 系統相容的同時能發揮 Docker 容器的威力。

### 關於此修正分支 (Fork)
本專案是分叉 (Fork) 自 [kajain99/Jellyfin-QPKG](https://github.com/kajain99/Jellyfin-QPKG)。由於原作者已停止維護與更新 release 檔案，且其原始安裝腳本在較新的 QNAP 系統（例如 QuTS Hero 6.0 或 QTS 6.0/5.x）中因寫死 Container Station 偵測路徑、以及 shell 軟連結解析的 Bug，會導致「偵測不到 Container 系統」而無法安裝或啟動。

本分叉版本進行了以下優化：
* **完美相容 QuTS Hero 6.0 以及 QTS 6.0 / 5.x 系統**。
* **動態偵測 Container Station 安裝路徑**（從 `/etc/config/qpkg.conf` 自動讀取，不受安裝硬碟磁碟區不同影響）。
* **更具彈性的 Docker 與 Compose 執行檔偵測**（同時支援新版 `docker compose` 指令與舊版獨立 `docker-compose` 執行檔，並支援環境變數 PATH 尋找）。
* **預設將 Jellyfin 的 Docker Image 更新為 `latest`** 標籤（原作者版本停留在舊版的 `10.8.10`）。
* **自動 Intel GPU (/dev/dri) 直通 (Passthrough)**：若系統偵測到 QNAP 主機具備 Intel 內建顯示卡，本套件會自動將 `/dev/dri` 直通對應至容器內，讓您能直接使用硬體加速解碼（QSV / VA-API）。
* **自動 NVIDIA GPU 直通 (Passthrough)**：若系統偵測到安裝了 NVIDIA 顯示卡且 `NVIDIA_GPU_DRV` 驅動套件為啟用狀態，本套件會自動將 `/dev/nvidia*` 裝置節點與驅動程式函式庫掛載至容器內，讓您能使用 NVIDIA NVENC/NVDEC 硬體加速。

---
## 安裝需求

要使用此 QPKG，您需要：

- 一台已安裝並設定好 **Container Station** (Container 主機) 的 QNAP NAS。
- App Center 已設定為「允許安裝未簽署的應用程式」。此 QPKG 未進行數位簽署，但您可以放心透過 GitHub 審查原始碼以確保無安全疑慮。

---

## 如何安裝

### 步驟 1：啟用安裝未簽署套件功能

1. 開啟 QNAP **App Center**。
2. 進入 **設定** (右上角齒輪圖示) > **一般**。
3. 勾選 **允許安裝沒有有效簽章的應用程式**。

### 步驟 2：手動安裝 QPKG

1. 請至本專案的 [Releases 頁面](https://github.com/ivanusto/Jellyfin-QPKG/releases) 下載最新的 `.qpkg` 檔案。
2. 在 App Center 中，點選右上角的 **手動安裝** 按鈕。
3. 選擇下載好的 QPKG 檔案並依照螢幕提示完成安裝。
   ![allow unsigned applications](https://www.thestorageguy.net/content/images/2025/01/image.png)

### 步驟 3：首次執行與設定

- 當應用程式首次啟動時，它會自動將您 QNAP 上所有可用的共享資料夾掛載到容器內的 **`/mnt`** 目錄中。
- 首次連線時，您會看到 Jellyfin 的設定畫面：
  - 請使用瀏覽器開啟：  
    `http://<您的-qnap-ip>:8096/web/#/wizardstart.html`  
    （請將 `<您的-qnap-ip>` 替換為您 NAS 的實際 IP，例如 `192.168.1.100`。）
  - 依照畫面引導完成初始安裝（建立管理員帳號密碼）。
    ![if you see this screen you need to run the first time setup wizard ](https://www.thestorageguy.net/content/images/2025/01/image-1.png)
![first time setup screen ](https://www.thestorageguy.net/content/images/2025/01/image-2.png)

---

## 新增媒體庫

當 Jellyfin 設定完成後，您可以輕鬆地將媒體資料夾新增到媒體庫：

1. 登入 Jellyfin 網頁管理介面。
2. 前往 **新增媒體庫** (Add Library)。
3. 在選擇資料夾時，從 **`/mnt`** 底下找到對應的 QNAP 共享資料夾即可。

---

## GPU 硬體加速轉碼設定 (Intel / NVIDIA)

### Intel 內顯 (QSV / VA-API)

如果您的 QNAP NAS 使用 Intel CPU 且具備內建顯示晶片 (例如 TS-464)，本套件在安裝時會自動偵測並將顯卡裝置路徑 `/dev/dri` 掛載至 Jellyfin 容器中。要啟用硬體加速轉碼：

1. 登入 Jellyfin 網頁管理介面。
2. 前往 **控制台 (Dashboard)** > **播放 (Playback)** > **轉碼 (Transcoding)**。
3. 將 **硬體加速 (Hardware acceleration)** 設定為 **Intel QuickSync (QSV)** 或 **Intel VA-API**。

> [!NOTE]
> 在某些 QNAP 韌體版本中，系統預設會將 `/dev/dri` 裝置權限限制給 `admin` 群組。若您在轉碼播放時遇到錯誤，可能需要透過 SSH 連線至 NAS 並執行 `chmod -R 777 /dev/dri` 指令，以放開權限給容器內的一般使用者存取。

### NVIDIA 獨顯 (NVENC / NVDEC)

如果您的 QNAP NAS 安裝了 NVIDIA 獨立顯示卡：

1. 請先確保已在 QNAP App Center 中安裝並啟用 **NVIDIA GPU Driver** 驅動套件。
2. 前往 QNAP **控制台** > **系統** > **硬體** > **顯示卡**，將顯示卡資源分配給 **Container Station (Container 主機)** 並套用。
3. 本套件在安裝/啟動時會自動偵測，並將 NVIDIA 裝置節點 (`/dev/nvidia*`) 以及主機上的顯示卡驅動程式目錄掛載至容器內。
4. 登入 Jellyfin 網頁管理介面，前往 **控制台 (Dashboard)** > **播放 (Playback)** > **轉碼 (Transcoding)**。
5. 將 **硬體加速 (Hardware acceleration)** 設定為 **Nvidia NVENC**。

---

## 貢獻與開發人員

- 修正與更新維護：[ivanusto](https://github.com/ivanusto)。
- 原始版本開發：[kajain99](https://github.com/kajain99)（使用 QNAP QDK 建置）。
- 核心引擎：官方的 Jellyfin Docker 映像檔 ([jellyfin/jellyfin](https://hub.docker.com/r/jellyfin/jellyfin))。

---

祝您在 QNAP 上愉快地使用 Jellyfin 影音伺服器！
