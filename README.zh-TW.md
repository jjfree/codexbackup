# Codex 備份與還原

本 repository 用來從來源電腦的備份還原一套 Windows Codex 工作環境。它適用於另一台已安裝或準備安裝 Codex 與 Docker Desktop 的 Windows 電腦。

English version: [README.md](README.md)

本 repo 只保存可安全版本化的設定與腳本。它不會 commit Codex 登入 token、connector credentials、私有 `.env` 檔案，或本機對話 SQLite DB。

## 會還原哪些內容

- Codex 開發工作所需的 Windows 前置套件。
- WSL 2 與 Ubuntu，供 Docker Desktop / Linux container workflows 使用。
- Git、Node.js 22、npm、PowerShell 7、GitHub CLI、Python 3.12、Docker Desktop。
- 啟用外掛的 Codex `config.toml`。
- Codex global `AGENTS.md`。
- 使用者安裝的 Playwright CLI skill。
- 匯出到 `C:\envbk` 的本機私有 Codex 備份。
- 可選的本機 Codex history/state 私有同步。

## 已啟用的 Codex 外掛

還原後的 `config.toml` 會啟用：

- Documents
- Spreadsheets
- Presentations
- GitHub
- Superpowers
- Figma
- Linear
- Google Drive
- Browser

Marketplace/runtime source paths 會刻意省略，因為那些路徑是每台機器各自不同的本機路徑。Codex 應該會在目標電腦上重新建立它們。

## 新電腦快速開始

還原前提：

- Windows 10/11，BIOS/UEFI 已啟用 virtualization。
- 已安裝 Codex app，且至少啟動過一次。
- 已安裝 Docker Desktop，或允許 installer 安裝/驗證它。
- 可連網，以便 `winget`、WSL、Docker、Codex plugin/runtime 下載。
- 使用 Administrator terminal 執行 WSL 與 Windows feature 安裝。
- Node.js 必須解析為 `v22.x`；installer 會嘗試安裝 `22.14.0`，若 PATH 上是其他 major version，腳本會停止。
- 若需要還原真實登入/session，請把舊電腦的 `C:\envbk` 複製到新電腦同樣的 `C:\envbk`。

建議還原順序：

1. 在舊電腦關閉 Codex，執行 `scripts\backup-local-codex.bat`。
2. 將 `C:\envbk` 複製到新電腦，路徑仍為 `C:\envbk`。
3. 在新電腦只下載本 repository 的 `scripts\sync-codex.bat`。
4. 用 Administrator terminal 進入下載該檔案的資料夾。
5. 執行 `sync-codex.bat /refresh-plugins`。
6. 若 WSL/VirtualMachinePlatform 步驟要求重開機，重開後再執行同一個命令。
7. 開啟 Codex；如果還原後的 auth 被拒絕，或 connector sessions 需要重新同意，請重新登入/授權。

若要從 terminal 下載：

```bat
curl.exe -L -o sync-codex.bat https://raw.githubusercontent.com/jjfree/codexbackup/main/scripts/sync-codex.bat
sync-codex.bat /refresh-plugins
```

`sync-codex.bat` 會先 bootstrap Git，將本 repository clone 或 pull 到 `%USERPROFILE%\Documents\Codex\codexbackup`，再執行 repository 裡最新版的 `scripts\sync-codex.bat`。之後會執行 `scripts\install-prereqs.bat`，每個套件都會先安裝並驗證成功後才進入下一個步驟。任何步驟失敗時，腳本會顯示錯誤並停止。

還原 versioned Codex config 與任何 private local state 後，sync script 會把來源電腦的 project paths 從 `C:\Users\<source-user>` 改寫成目前 Windows `%USERPROFILE%`，將 checkout 出來的 `codexbackup` repository 加入 trusted project，並建立缺少的 trusted project directories，避免還原後的對話開啟時遇到 missing-working-directory error。如果某個專案在目標電腦不是放在相同相對路徑，請在還原後手動更新該 project entry。

因為 private restore 會覆寫 Codex auth/session/SQLite files，當你要還原 `C:\envbk` 時，請先關閉 Codex。如果你在新電腦用 Codex 協助安排還原，請讓它準備好命令後，關閉 Codex，再從 Administrator terminal 執行最後的 restore。

使用 `/refresh-plugins` 時，腳本會將現有 plugin cache 移到備份資料夾，然後啟動 Codex，讓 Codex 根據 `config.toml` 重新安裝/啟用 `[plugins.*]` 宣告的外掛。

Codex plugin installation 是由 Codex app 自己完成。這個腳本負責還原 `config.toml`、可選地移開舊 plugin cache，並啟動 Codex，讓 Codex 依設定重建外掛。

如果前置套件已經處理好，可以使用 `/no-install`：

```bat
scripts\sync-codex.bat /no-install /refresh-plugins
```

## 備份舊電腦的私有 Codex 資料

在舊電腦，先關閉 Codex，再執行：

```bat
scripts\backup-local-codex.bat
```

如果 Windows 阻擋建立 `C:\envbk`，請改用 Administrator terminal 重新執行。

備份腳本會把 `auth.json`、`.codex-global-state.json`、`session_index.jsonl`、`logs_2.sqlite`、`state_5.sqlite` 視為必要檔案。若任何必要檔案缺失，腳本會停止，避免產生看似成功但其實不完整的備份。

私有 Codex 資料會匯出到：

```text
C:\envbk\codex-home-private
```

備份成功後，腳本會自動用 Windows Explorer 開啟 `C:\envbk\codex-home-private`，方便你檢查或複製備份資料夾。

備份包含真實本機狀態，例如：

- `auth.json`
- `cap_sid`
- `installation_id`
- `.codex-global-state.json`
- `session_index.jsonl`
- `models_cache.json`
- `logs_2.sqlite*`
- `state_5.sqlite*`
- `sessions`
- `archived_sessions`
- `memories`
- `rules`
- `skills`
- `.sandbox-secrets`
- `cache`

請把 `C:\envbk` 視為敏感資料。它可能包含登入 token、connector auth state、prompt history、本機對話 DB 與 project metadata。請存放在 BitLocker、加密壓縮檔或可信任的離線媒體中。

## 備份路徑說明

這個 repo 有兩種不同的備份路徑，這是刻意設計：

- `C:\envbk\codex-home-private` 是 `scripts\backup-local-codex.bat` 建立的可攜式私有匯出。若要在目標電腦還原 auth、sessions、SQLite state、memories、rules、skills，請複製這個資料夾。
- `%USERPROFILE%\.codex\pathfix-backups` 是目標電腦還原期間由 `scripts\adapt-codex-config.ps1` 建立。它會在腳本把 source-machine paths 改寫成目標 Windows profile 前，保存 config/state 檔案的安全副本。

不要用 `pathfix-backups` 取代 `C:\envbk\codex-home-private`：它們用途不同。前者是目標電腦本機 rollback 點，後者是跨電腦搬移用的私有備份包。

## 可選的私有 Codex History Sync

如果新電腦上存在 `C:\envbk\codex-home-private`，`scripts\sync-codex.bat` 會自動還原它。你也可以指定其他備份路徑：

```bat
set SOURCE_CODEX_HOME=E:\codex-home-private
scripts\sync-codex.bat /no-install /refresh-plugins
```

這可以同步：

- `auth.json`
- `cap_sid`
- `installation_id`
- `sessions`
- `archived_sessions`
- `memories`
- `rules`
- `skills`
- `.sandbox-secrets`
- `cache`
- `session_index.jsonl`
- `models_cache.json`
- `.codex-global-state.json`
- `logs_2.sqlite*`
- `state_5.sqlite*`

這個 private restore 會刻意包含 Codex auth/session files，只要它們存在於私有備份中。它仍會避免同步 project `.env` files 與 plugin cache。

## 安全邊界

請不要 commit：

- `%USERPROFILE%\.codex\auth.json`
- `%USERPROFILE%\.codex\cap_sid`
- `%USERPROFILE%\.codex\.sandbox-secrets`
- project `.env` files
- API keys、cookies、tokens、connector credentials
- 未加密的 private conversation/state backups

如果你沒有還原 `C:\envbk`，請在目標電腦重新登入 Codex、GitHub、Google Drive、Figma、Linear 等 connector。即使有還原 `C:\envbk`，某些 connector sessions 在新電腦上仍可能需要重新同意授權。

## WSL 2 注意事項

這份安裝流程包含 WSL 2，因為 Windows 上的 Docker Desktop 通常使用 WSL 2 backend 來執行 Linux containers。installer 會啟用：

- `Microsoft-Windows-Subsystem-Linux`
- `VirtualMachinePlatform`
- WSL default version 2
- Ubuntu WSL distribution

如果 Windows 回報某個 feature 啟用後需要重開機，腳本會停止並要求你重開機後再繼續。這是預期行為。

## Project Notes

`New project 3` / `unitrade-api` 需要 Python `>=3.11,<3.13`。因此 installer 即使偵測到其他 Python version，也會安裝 Python 3.12。

專案原始碼仍建議透過 Git remotes 或獨立的 project backups 還原。這個 repository 還原的是 Codex workstation environment，不是每一個 project working tree。
