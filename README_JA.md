# Difficulty randomizer

[[English]](README.md) [日本語]

## 注意

このプラグインは作者が自分のサーバーを面白おかしくするために作ったプラグインです。

そのため通常のサーバーには99%適しません。 ご利用は自己責任でお願い致します。何があっても責任は取りません。

## 機能

* 難易度をマップ変更時にランダムで変更する
* 1回のリロールチャンス (変更可能)

## コマンド

* `sm_reroll`       or  `!reroll`       - 難易度抽選をやり直します。
* `sm_dr_volume`    or  `!dr_volume`    - ルーレットの音量を変更します。
* `sm_dr_toggle`    or  `!dr_toggle`    - ルーレットの音声を切り替えます。
* `sm_dr_menu`      or  `!dr_menu`      - 音声関連の設定メニューを開きます。

## ConVar

* `sm_drand_version`                    - プラグインのバージョンを表示します。
* `sm_drand_enabled`                    - プラグインの有効無効を切り替えます。
* `sm_drand_reroll`                     - 1mapで何回リロールできるかを設定します。
* `sm_drand_win_weight_easy`            - 難易度Easyの出現する重さを設定します。
* `sm_drand_win_weight_normal`          - 難易度Normalの出現する重さを設定します。
* `sm_drand_win_weight_advanced`        - 難易度Advancedの出現する重さを設定します。
* `sm_drand_win_weight_expert`          - 難易度Expertの出現する重さを設定します。
* `sm_drand_roulette_countdown_time`    - 最初のプレイヤーが接続、もしくはリロールコマンドが実行された際にルーレットが開始されるまでに何秒間カウントダウンするかを設定します。
* `sm_drand_roulette_sound_tick`        - ルーレットの抽選音を設定します。 拡張子を含んだ相対パスが必要です。
* `sm_drand_roulette_sound_chosen`      - ルーレットの抽選が確定した音を設定します。 拡張子を含んだ相対パスが必要です
* `sm_drand_roulette_sound_countdown`   - ルーレットのカウントダウン音を設定します。 拡張子を含んだ相対パスが必要です
