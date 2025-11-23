# メモアプリ (Memo App)

Flutter製のクロスプラットフォーム対応メモアプリケーション。テキスト入力と手書き入力の両方をサポートし、AI機能によるOCRとテキストリライトが可能です。

## 🔗 リポジトリ

**GitHub**: https://github.com/t2k2pp/MemoApp.git

開発の進捗管理とバージョン管理にGitを使用しています。[CONTRIBUTING.md](CONTRIBUTING.md)でGit運用ガイドラインを確認できます。


## 特徴

### 📝 入力方式
- **テキスト入力**: キーボードによる通常のテキスト入力
- **手書き入力**: ペン、タッチ、マウスによる手書きメモ
- **パームリジェクション**: ペン使用時に手のひらの誤入力を防止
- **モード切替**: タッチデバイスで描画モードとパンモードを切り替え可能

### 🤖 AI機能
- **OCR (光学文字認識)**: 手書きメモからテキストを抽出
- **テキストリライト**: AIによるテキストの書き直し
  - 要約、改善、丁寧語への変換など
  - 置き換えまたは挿入の選択が可能
  - ユーザー確認付き

### 🏷️ 整理機能
- **タグ付け**: メモにタグを追加して分類
- **検索**: タイトル、本文、タグ、OCRテキストから検索
- **フィルタリング**: タグで絞り込み表示

### 🌐 対応プラットフォーム
- Android
- iOS
- Web (CanvasKit レンダラー使用)

## セットアップ

### 必要要件
- Flutter SDK (3.8.1以降)
- Dart 3.8.1以降

### インストール

1. **依存関係のインストール**
```bash
flutter pub get
```

2. **実行**

#### Web版 (推奨: CanvasKit使用)
```bash
flutter run -d chrome --web-renderer canvaskit
```

#### Android
```bash
flutter run -d android
```

#### iOS
```bash
flutter run -d ios
```

### ビルド

#### Web版
```bash
flutter build web --web-renderer canvaskit
```

#### Android
```bash
flutter build apk
# または
flutter build appbundle
```

#### iOS
```bash
flutter build ios
```

## AI設定

アプリの設定画面から、以下のいずれかのAIプロバイダーを設定できます:

### 1. Gemini API (オンライン)

**取得方法:**
1. [Google AI Studio](https://makersuite.google.com/app/apikey) にアクセス
2. APIキーを作成
3. アプリの設定画面で「Gemini API」を選択
4. APIキーを入力

**料金:** 無料枠あり（制限あり）

### 2. Ollama (ローカル)

**セットアップ:**
1. [Ollama](https://ollama.ai/)をインストール
2. ビジョンモデルをダウンロード:
```bash
ollama pull llava
```
3. Ollamaを起動
4. アプリの設定で「Ollama」を選択
5. エンドポイント: `http://localhost:11434`
6. モデル名: `llava`

**メリット:** 完全にローカルで動作、プライバシー保護

### 3. LM Studio (ローカル)

**セットアップ:**
1. [LM Studio](https://lmstudio.ai/)をダウンロード&インストール
2. ビジョン対応モデルをロード
3. ローカルサーバーを起動
4. アプリの設定で「LM Studio」を選択
5. エンドポイント: `http://localhost:1234`

**メリット:** GUIで簡単にモデル管理が可能

## 使い方

### メモの作成
1. ホーム画面の「+」ボタンをタップ
2. タイトルと本文を入力、または手書きモードで描画
3. 必要に応じてタグを追加
4. 自動保存されます

### 手書きメモのOCR
1. 手書きモードで描画
2. 画面上部の「テキスト抽出」アイコンをタップ
3. 抽出されたテキストが表示され、検索対象になります

### AIリライト
1. テキストモードでテキストを入力
2. テキストを選択（または全文を対象）
3. 「AIリライト」アイコンをタップ
4. 指示を入力（例: 「要約して」「丁寧な表現に」）
5. 生成されたテキストを確認
6. 「置き換え」または「挿入」を選択

### 検索とフィルタリング
1. ホーム画面の検索バーに入力
2. フィルターアイコンでタグを選択
3. 選択したタグのメモのみ表示

## 技術スタック

- **Flutter**: クロスプラットフォームフレームワーク
- **Provider**: 状態管理
- **SharedPreferences**: ローカル設定保存
- **PathProvider**: ファイルシステムアクセス
- **HTTP**: AI API通信
- **UUID**: 一意なID生成

## プロジェクト構造

```
lib/
├── main.dart                    # アプリケーションエントリーポイント
├── models/                      # データモデル
│   ├── memo.dart
│   ├── stroke.dart
│   └── ai_config.dart
├── providers/                   # 状態管理
│   ├── memo_provider.dart
│   └── settings_provider.dart
├── services/                    # ビジネスロジック
│   ├── storage_service.dart
│   └── ai/
│       ├── ai_service.dart
│       ├── gemini_service.dart
│       ├── ollama_service.dart
│       └── lm_studio_service.dart
├── screens/                     # 画面
│   ├── home_screen.dart
│   ├── editor_screen.dart
│   └── settings_screen.dart
├── widgets/                     # UIコンポーネント
│   ├── handwriting_canvas.dart
│   ├── memo_card.dart
│   └── tag_chip.dart
└── utils/                       # ユーティリティ
    ├── pointer_utils.dart
    └── image_converter.dart
```

## 注意事項

### Web版
- **初回読み込み**: CanvasKitのWASMファイル(約2MB)をダウンロードするため、初回は読み込みに時間がかかります
- **日本語入力**: Flutter Webの日本語IMEは改善されていますが、まれに変換候補が正しく表示されないことがあります

### 手書き入力
- **ペン優先モード**: スタイラスを使用する場合、自動的にタッチ入力は無視されます
- **タッチ描画モード**: ペンがない場合は、描画モードとパンモードを手動で切り替える必要があります
- **筆圧**: 現バージョンでは筆圧感知には対応していません（将来的に追加予定）

### AI機能
- **オフライン動作**: OllamaまたはLM Studioを使用すれば、完全オフラインで動作します
- **プライバシー**: Gemini APIを使用する場合、手書きメモの画像とテキストがGoogleのサーバーに送信されます

## トラブルシューティング

### 手書きが反応しない
- デバイスがタッチまたはペン入力に対応しているか確認
- タッチ描画モードが正しく設定されているか確認

### OCRがエラーになる
- AI設定が正しく行われているか確認
- Ollama/LM Studioが起動しているか確認
- インターネット接続を確認（Gemini APIの場合）

### 設定が保存されない
- アプリに書き込み権限があるか確認
- ストレージ容量を確認

## ライセンス

MIT License

## 作者

Flutter Memo App Development Team
