# Codex 備份與還原

本 repository 用來把一台 Windows 電腦上的 Codex 工作環境備份，並還原到另一台 Windows 電腦。它只保存可公開版本化的設定與腳本；真正的登入狀態、token、connector 授權、`.env` 與對話 SQLite DB 不會被 commit 到 GitHub。

English version: [README.md](README.md)

## 可還原內容

- Windows/Codex 開發所需套件。
- WSL 2 與 Ubuntu，供 Docker Desktop / Linux containers 使用。
- Git、Node.js 22、npm、PowerShell 7、GitHub CLI、Python 3.12、Docker Desktop。
- Codex `config.toml` 中的 model、sandbox 與 plugin 啟用設定。
- Codex global `AGENTS.md`。
- 使用者安裝的 Playwright CLI skill。
- 可選的本機私有 Codex 狀態備份與還原。

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

Marketplace/runtime 的本機路徑不會寫死在 repo 中；Codex 會在目標電腦上自行重新建立。

## 在來源電腦建立私有備份

先關閉 Codex，然後執行：

```bat
scripts\backup-local-codex.bat
```

備份會輸出到：

```text
C:\envbk\codex-home-private
```

備份成功後，腳本會自動用 Windows Explorer 開啟 `C:\envbk\codex-home-private`，方便你確認或複製備份資料夾。

備份內容可能包含：

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

`C:\envbk` 是敏感資料，可能包含登入 token、connector 授權、prompt 歷史、對話 DB 與專案 metadata。請放在 BitLocker、加密壓縮檔或可信任的離線媒體中。

## 在新電腦還原

還原前提：

- Windows 10/11，BIOS/UEFI 已啟用 virtualization。
- 已安裝 Codex app，且至少啟動過一次。
- 可連網，以便 `winget`、WSL、Docker、Codex plugin/runtime 下載。
- 使用 Administrator terminal 執行。
- 若要還原真實登入與對話紀錄，請先把來源電腦的 `C:\envbk` 複製到新電腦同一路徑。

建議還原順序：

1. 在來源電腦關閉 Codex，執行 `scripts\backup-local-codex.bat`。
2. 將 `C:\envbk` 複製到新電腦。
3. 在新電腦下載本 repo 的 `scripts\sync-codex.bat`。
4. 用 Administrator terminal 進入下載位置。
5. 執行：

```bat
sync-codex.bat /refresh-plugins
```

若要用命令列下載：

```bat
curl.exe -L -o sync-codex.bat https://raw.githubusercontent.com/jjfree/codexbackup/main/scripts/sync-codex.bat
sync-codex.bat /refresh-plugins
```

`sync-codex.bat` 會先確保 Git 可用，clone 或 pull 本 repo 到 `%USERPROFILE%\Documents\Codex\codexbackup`，再轉交 repo 中最新版的 sync script。之後會逐步執行安裝、還原設定、修正路徑、還原私有狀態，最後觸發 Codex plugin cache 重建。

如果 WSL 或 VirtualMachinePlatform 要求重開機，請重開後再次執行同一個命令。

## 路徑適配

還原後，`sync-codex.bat` 會執行 `scripts\adapt-codex-config.ps1`，將來源電腦的 `C:\Users\<source-user>\...` 路徑改成目標電腦的 `%USERPROFILE%`，並將本機 `codexbackup` checkout 加入 trusted projects。

如果某些專案在新電腦不是放在相同相對路徑，還原後請手動調整對應的 Codex project trust entry。

## Plugin 還原

使用 `/refresh-plugins` 時，腳本會把現有 `%USERPROFILE%\.codex\plugins\cache` 移到備份資料夾，然後啟動 Codex。Codex 會依 `config.toml` 的 `[plugins.*] enabled = true` 重新安裝或啟用外掛。

GitHub、Google Drive、Figma、Linear 等 connector 可能仍需要在新電腦重新授權。

## 安全邊界

請不要 commit：

- `%USERPROFILE%\.codex\auth.json`
- `%USERPROFILE%\.codex\cap_sid`
- `%USERPROFILE%\.codex\.sandbox-secrets`
- 專案 `.env`
- API key、cookie、token、connector credentials
- 未加密的私有對話或 state 備份

本 repo 用來分享「如何備份與還原」，不是用來保存實際私有備份內容。
