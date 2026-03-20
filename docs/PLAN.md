# Noise Recorder 開発計画

## 概要

騒音を計測・記録し、証拠として PDF レポートを出力できる iOS アプリ。

## 完了済み

### v0.1 — 初期実装

- [x] リアルタイム騒音メーター（ゲージ UI）
- [x] 閾値超過の自動検知・ログ記録（SwiftData）
- [x] ログ一覧画面（日付・dB 表示）
- [x] 統計ダッシュボード（時間帯別・日別チャート）
- [x] PDF レポート出力（期間指定・共有）
- [x] 設定画面（閾値スライダー）
- [x] ダークテーマ UI

### v0.2 — dB 表示の改善

- [x] dBFS → 近似 SPL 変換（オフセット +120）
- [x] 初期値の Optional 化（計測前は "--" 表示）
- [x] 共通コンポーネント・フォーマッター抽出
- [x] ランニング統計（min / avg / max）の最適化
- [x] 未使用 UI 要素の削除

### v0.3 — ノイズフロア補正（未コミット）

- [x] 起動時のマイクキャリブレーション（3秒、30サンプル）
- [x] ノイズフロアを基準とした dB 補正（静寂時 ≒ 30 dB）
- [x] キャリブレーションデータの UserDefaults 永続化
- [x] キャリブレーション中の ProgressView UI
- [x] Settings 画面にキャリブレーション情報・再実行ボタン追加
- [ ] 実機テスト

## 未着手

### v0.4 — 品質向上（候補）

- [ ] マイク権限のハンドリング改善（拒否時の案内 UI）
- [ ] バックグラウンド計測対応
- [ ] 通知機能（閾値超過時のローカル通知）
- [ ] ログの検索・フィルタ機能
- [ ] データのエクスポート（CSV）

### v1.0 — 公開準備（候補）

- [ ] Apple Developer Program 加入
- [ ] アプリアイコン作成（1024x1024）
- [ ] App Store 用スクリーンショット撮影
- [ ] プライバシーポリシーページ作成
- [ ] App Store 審査・リリース

## 技術スタック

| 項目 | 技術 |
|------|------|
| 言語 | Swift 6 |
| UI | SwiftUI |
| データ | SwiftData |
| 音声入力 | AVAudioRecorder |
| チャート | Swift Charts |
| レポート | PDFKit |
| 最小 OS | iOS 17.0 |

## アーキテクチャ

```
NoiseRecorder/
├── App/                  # アプリエントリポイント
├── Models/               # データモデル、設定
│   ├── NoiseEvent.swift  # SwiftData モデル
│   └── AppSettings.swift # UserDefaults ラッパー + 共通 UI
├── Services/             # ビジネスロジック
│   ├── AudioMeteringService.swift  # 音声計測・キャリブレーション
│   └── PDFReportGenerator.swift    # PDF レポート生成
├── Views/                # 画面
│   ├── ContentView.swift     # TabView ルート
│   ├── HomeView.swift        # メーター画面
│   ├── LogListView.swift     # ログ一覧
│   ├── DashboardView.swift   # 統計チャート
│   ├── ReportView.swift      # レポート出力
│   └── SettingsView.swift    # 設定
└── Components/           # 再利用コンポーネント
    └── DecibelMeterView.swift  # ゲージ UI
```
