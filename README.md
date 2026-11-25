# ラッパー育成ゲーム（iOS / SwiftUI）

歩数でポイントをためて、赤ちゃんをラッパーに育てるゲームです。

- 🚶 歩数 100歩 = 1pt（ヘルスケア連携）
- 📝 練習で能力アップ → 👶 → 🧒 → 🧑 → 🧑‍🎤 と成長
- 🎤 韻踏みチャレンジ：30秒以内にお題と母音が完全に一致する言葉を入力
- 🧱 ホーム画面ウィジェット：キャラと今日の歩数を表示

## ファイル構成

| フォルダ | 入れるターゲット |
|---|---|
| `RapperRaise/` | アプリ本体 |
| `RapperWidget/` | ウィジェット |
| `Shared/WidgetSnapshot.swift` | **アプリとウィジェットの両方** |

## Xcodeでの作り方

### 1. プロジェクトを作る
1. Xcode → **File → New → Project… → iOS → App**
2. Product Name: `RapperRaise` / Interface: **SwiftUI** / Language: **Swift** / Storage: **None**
3. 最初からある `ContentView.swift` と `RapperRaiseApp.swift` の中身を、`RapperRaise/` の同名ファイルの中身で置き換える
4. `GameState.swift` `Rhyme.swift` `RhymeGameView.swift` `WordValidator.swift` を追加する
   （File → New → File… → Swift File で作って中身を貼る）

### 2. ウィジェットを追加する
1. **File → New → Target… → Widget Extension**
2. Product Name: `RapperWidget`
3. 「Include Live Activity」「Include Control」「Include Configuration App Intent」は **すべてチェックを外す**
4. 「Activate scheme?」→ **Activate**
5. 作られた `RapperWidget.swift` と `RapperWidgetBundle.swift` の中身を、`RapperWidget/` の同名ファイルで置き換える
   （他に `AppIntent.swift` などが作られていたら削除してOK）

### 3. 共有ファイルを追加する
1. `Shared/WidgetSnapshot.swift` を追加する
2. ファイルを選んで右側の **File Inspector → Target Membership** で
   `RapperRaise` と `RapperWidgetExtension` の **両方にチェック**

### 4. Capability（権限）を設定する
左のプロジェクト → TARGETS ごとに **Signing & Capabilities** → **+ Capability**

| ターゲット | 追加するもの |
|---|---|
| RapperRaise | **HealthKit**、**App Groups** |
| RapperWidgetExtension | **HealthKit**、**App Groups** |

- App Groups は両方に **同じID** を登録する（例: `group.com.あなたの名前.rapperraise`）
- そのIDを `WidgetSnapshot.swift` の `groupID` にも書く

### 5. ヘルスケアの説明文を書く
TARGETS → **RapperRaise** → **Info** タブ → `+` で追加

- Key: `Privacy - Health Share Usage Description`
- Value: `歩数を育成ポイントに使います`

### 6. 実行
1. 上のスキームを **RapperRaise** にして ▶︎ 実行
2. キャラを作る → ヘルスケアの許可を出す
3. シミュレーターでは歩数が取れないので「（テスト用）+10pt」で試す
4. ホーム画面を長押し → ＋ →「ラッパー育成」でウィジェットを追加
