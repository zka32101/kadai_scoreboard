# 課題スコアボード — Development Guide

**Vision:** 市民が複雑な社会課題を数字で理解できる社会  
**Mission:** 政策効果を透明に可視化し、根拠ある市民参加を支援

---

## 技術スタック

- **Frontend:** Flutter 3.x + Dart + Riverpod
- **Backend:** Firebase (Firestore・Auth・Cloud Functions)
- **課金:** RevenueCat
- **グラフ:** fl_chart
- **計測:** Firebase Analytics・Crashlytics

---

## MVP スコープ（v1.1）

### 実装順序（優先度順）
1. ✅ プロジェクト初期化
2. Firebase認証・Firestore設定
3. **データモデル定義** (User, Challenge, UserImpact)
4. **マイ人生インパクト計算エンジン** ← 最優先 (Aha Moment)
5. ダッシュボード画面
6. グラフ表示 (fl_chart)
7. タイムマシンスライダー
8. シェア機能 (Twitter/LINE/スクショ)
9. RevenueCat ペイウォール
10. テスト (Unit / Widget / Integration)

### 画面フロー（MVP版・5画面）
1. スプラッシュ画面
2. 年齢・職業入力（初回のみ）
3. ダッシュボード（3課題タイル表示）
4. 課題詳細
5. マイ結果・シェア

### データモデル（3課題固定）
- **人口減少**
- **年金**
- **介護**

監修: 国立社会保障・人口問題研究所・厚労省・医療経済学者

---

## 実装ガイドライン

### 簡単な部分（Haiku で進行）
- Firebase初期設定・認証フロー
- UI/スクリーン構築（基本レイアウト）
- データモデル定義・Riverpod Provider
- シェア機能（URL生成・共有）
- ペイウォール実装

### 複雑な部分（Sonnet で実装）
- **マイ人生インパクト計算エンジン** ← 精度が信頼性を左右
- グラフシミュレーション（fl_chart動的変化）
- タイムマシンスライダー（滑らか＋精度）
- Cloud Functions（複雑な計算ロジック）
- テスト（Unit・Widget・Integration）

### 信頼性設計
- データ監修者・機関を画面に明記
- Firestore に タイムスタンプ記録（版管理）
- オフラインキャッシュ必須（最後のグラフ表示）

---

## KPI・計測

### Day7 リテンション 25% 以上
### Day30 リテンション 12% 以上
### MAU 20万人（初年度）

### イベント（3個に絞る）
1. `age_input_complete` — Activation (Aha Moment)
2. `graph_shared` — Referral
3. `purchased_premium` — Revenue (¥120/月)

---

## v2.0 へ延期（スコープ外）
- クエスト・ストリーク・ランキング
- 財源パズル
- AI議員答弁チェッカー
- ハプティクス・ダークモード・複雑なアニメーション

---

## 参考資料
- **設計書:** G:\マイドライブ\design\日本の未来マップ\課題スコアボード_実装設計書_v1_1_MVP.md
- **リファレンス:** Wordle (シンプル), Duolingo (ストリーク)

---

## ルール

### RTK (Token 削減)
すべてのコマンド前に `rtk` を付ける（git, cargo, npm, flutter など）

```bash
rtk flutter pub get
rtk flutter analyze
rtk flutter test
rtk git commit -m "message"
```

### Sonnet 起動
複雑な部分は明示的に Sonnet で実装。簡単な部分は Haiku で進行。

