# EquityTracker

EquityTracker 是一款以 Flutter 開發的本機優先（Offline-first）記帳與資產追蹤應用程式，支援 Android 與 iOS 平台。資料預設儲存於本機 SQLite，並提供通知自動解析、AI 語音與文字記帳及 Notion 雲端同步功能。

---

## 核心功能

- **收支與資產管理**：日常收支記錄、分類管理、週期性帳目、資產統計圖表與本機資料快照備份。
- **通知自動記帳 (Android)**：背景監聽銀行與行動支付的系統推播通知，依規則自動解析交易金額與交易對象並自動記錄。
- **AI 智能記帳**：支援文字與語音輸入，串接大型語言模型自動辨識消費內容、店家與分類；支援 Google AI Studio、GeminiFlow、Vertex AI 與本地 Ollama。
- **發票與外部資料匯入**：支援經由 URL Scheme (`equitytracker://receipt/import?data=...`) 或系統文字分享匯入記帳資料。
- **Notion 雲端同步**：可將帳目雙向同步至自訂的 Notion Database。
- **應用程式自動更新**：內建 GitHub Releases 版本檢查，可於 App 內直接下載並安裝最新版本 APK。

---

## 環境需求

- Flutter SDK >= 3.10.4
- Android SDK (minSdkVersion 21) 或 iOS 開發環境

---

## 開發與執行

```bash
# 取得依賴套件
flutter pub get

# 啟動應用程式
flutter run
```

---

## 打包發布

### Android APK 打包 (推薦)

建議使用 `--split-per-abi` 依 CPU 架構拆分安裝檔，大幅縮減單一 APK 體積，並加上 `--no-tree-shake-icons` 確保動態圖示正常顯示：

```bash
flutter build apk --split-per-abi --no-tree-shake-icons
```

打包成品路徑：`build/app/outputs/flutter-apk/`  
一般現代 Android 手機分發 `app-arm64-v8a-release.apk` 即可。

### iOS 打包

```bash
flutter build ipa
```

---

## 必要權限與外部服務設定

1. **Android 通知存取權限**：使用「通知自動記帳」功能前，需於系統「設定 -> 應用程式 -> 特殊應用程式存取權 -> 通知存取權」中啟用 EquityTracker。
2. **麥克風權限**：使用「AI 語音記帳」功能需授予錄音權限。
3. **AI 服務設定**：進入 App 內「設定 -> AI 設定」，填入相應的 API Key（如 Google AI Studio）或配置本地 Ollama 連線位址。
4. **Notion 同步設定**：進入 App 內「設定 -> Notion 設定」，填入 Notion Integration Token 與 Database ID。

---

## GitHub Release 發布流程

App 內建的自動更新機制依賴 GitHub Releases：

1. **修改版號**：更新 `pubspec.yaml` 中的 `version`（例如：`1.0.1+2`）。
2. **打包 APK**：執行 `flutter build apk --split-per-abi --no-tree-shake-icons`。
3. **建立 Release**：至 GitHub 專案頁面建立 Release，Tag 格式需大於前一版本（例如：`v1.0.1`）。
4. **上傳安裝檔**：將打包生成的 APK 上傳至該 Release 的附件中。
5. **發布**：發布 Release 後，App 啟動或使用者手動點擊檢查更新時即會提示下載。
