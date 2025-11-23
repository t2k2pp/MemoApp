# Git運用ガイドライン

## リモートリポジトリ

**URL**: https://github.com/t2k2pp/MemoApp.git  
**ブランチ**: main

## 基本的なワークフロー

### 1. 変更の確認
```bash
git status
```

### 2. 変更をステージング
```bash
# 全ての変更をステージング
git add .

# 特定のファイルのみステージング
git add lib/screens/home_screen.dart
```

### 3. コミット
```bash
git commit -m "コミットメッセージ"
```

### 4. リモートへプッシュ
```bash
git push origin main
```

## コミットの区切り（推奨タイミング）

以下のタイミングでコミットを行うことを推奨します：

### 機能の実装完了時
- ✅ 新しい画面の追加完了
- ✅ 新しい機能の実装完了
- ✅ バグ修正完了

**例:**
```bash
git add .
git commit -m "機能追加: メモのカラーピッカー機能を実装"
git push origin main
```

### UI/UXの改善完了時
- ✅ デザインの変更完了
- ✅ レイアウト調整完了
- ✅ アニメーション追加完了

**例:**
```bash
git commit -m "UI改善: メモカードのシャドウとアニメーションを追加"
```

### リファクタリング完了時
- ✅ コードの整理完了
- ✅ パフォーマンス改善完了
- ✅ コードの最適化完了

**例:**
```bash
git commit -m "リファクタリング: MemoProviderの状態管理を最適化"
```

### ドキュメント更新時
- ✅ README更新
- ✅ コメント追加
- ✅ API仕様変更

**例:**
```bash
git commit -m "ドキュメント: AI設定手順をREADMEに追加"
```

## コミットメッセージの書き方

### プレフィックスを使用
- `機能追加:` - 新機能の追加
- `修正:` - バグ修正
- `UI改善:` - デザイン・UI変更
- `リファクタリング:` - コードの整理・最適化
- `ドキュメント:` - ドキュメント更新
- `テスト:` - テスト追加・修正
- `設定:` - 設定ファイル変更

### 具体的な説明
❌ 悪い例: `git commit -m "更新"`  
✅ 良い例: `git commit -m "機能追加: 手書きメモの筆圧感知機能を実装"`

### 複数行のコミットメッセージ
```bash
git commit -m "機能追加: エクスポート機能を実装

- PDF形式でのエクスポートに対応
- 画像形式(PNG)でのエクスポートに対応
- エクスポート設定画面を追加"
```

## ブランチ戦略（今後の拡張時）

現在は`main`ブランチのみですが、チーム開発や大きな機能追加時は以下を推奨：

### Feature ブランチ
```bash
# 新機能開発用のブランチを作成
git checkout -b feature/voice-note

# 開発完了後、mainにマージ
git checkout main
git merge feature/voice-note
git push origin main
```

### Fix ブランチ
```bash
# バグ修正用のブランチ
git checkout -b fix/ocr-crash-on-empty-canvas
```

## 便利なGitコマンド

### 最近のコミット履歴を確認
```bash
git log --oneline --graph --decorate -10
```

### 変更差分を確認
```bash
# ステージング前の変更
git diff

# ステージング後の変更
git diff --staged
```

### コミットの取り消し（ローカルのみ）
```bash
# 最新のコミットを取り消し（変更は保持）
git reset --soft HEAD~1

# 最新のコミットを完全に取り消し（変更も破棄）
git reset --hard HEAD~1
```

### リモートの最新を取得
```bash
git pull origin main
```

## .gitignoreの確認

以下のファイル・ディレクトリは自動的に除外されます：
- `build/` - ビルド成果物
- `.dart_tool/` - Dartツール
- `.idea/`, `*.iml` - IDE設定
- `*.log` - ログファイル
- `.flutter-plugins*` - Flutter プラグイン設定

## トラブルシューティング

### プッシュが拒否された場合
```bash
# リモートの変更を取得してマージ
git pull origin main --rebase
git push origin main
```

### 間違ったファイルをコミットした場合
```bash
# ファイルをステージングから除外
git reset HEAD <ファイル名>

# または最新コミットを修正
git commit --amend
```

### コンフリクトが発生した場合
1. コンフリクトしているファイルを手動で編集
2. `git add <ファイル名>`
3. `git commit`

## 定期的なバックアップ

最低でも以下のタイミングでプッシュすることを推奨：
- ✅ 1日の作業終了時
- ✅ 重要な機能の実装完了時
- ✅ 動作確認が取れた時点

## 現在のリポジトリ状態

**初回コミット**: 5600898  
**コミット内容**: Flutter メモアプリの基本実装完了
- テキスト入力と手書き入力機能
- パームリジェクション対応
- AI統合 (Gemini/Ollama/LM Studio)
- OCRとテキストリライト機能
- タグ管理と検索機能
- クロスプラットフォーム対応 (Android/iOS/Web)

**ファイル数**: 204ファイル  
**サイズ**: 約292KB
