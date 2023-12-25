# Difficulty randomizer

[English] [[日本語]](README_JA.md)

## Caution

This plugin is created by the author to make my server more chaos.

99% not suitable for normal servers. Please use at your own risk. I will not responsive for anything caused by this plugin.

## Feature

* Randomize difficulty per map change
* Chance to reroll the roulette 1 time (configurable)

## Command

* `sm_reroll`       or  `!reroll`       - Reroll the difficulty.
* `sm_dr_volume`    or  `!dr_volume`    - Set roulette sound volume.
* `sm_dr_toggle`    or  `!dr_toggle`    - Toggle roulette sound.
* `sm_dr_menu`      or  `!dr_menu`      - Opens a sound settings menu.

## ConVar

* `sm_drand_version`                    - Plugin version
* `sm_drand_enabled`                    - Toggle plugin
* `sm_drand_reroll`                     - Number of how many times can reroll the roulette per map
* `sm_drand_win_weight_easy`            - Chance rate for difficulty Easy
* `sm_drand_win_weight_normal`          - Chance rate for difficulty Normal
* `sm_drand_win_weight_advanced`        - Chance rate for difficulty Advanced
* `sm_drand_win_weight_expert`          - Chance rate for difficulty Expert
* `sm_drand_roulette_countdown_time`    - How many seconds to countdown for starting roulette after first player joined the game
* `sm_drand_roulette_sound_tick`        - Specify the ticking sound of roulette. Requires sound path include extension.
* `sm_drand_roulette_sound_chosen`      - Specify the chosen sound of roulette. Requires sound path include extension.
* `sm_drand_roulette_sound_countdown`   - Specify the countdown sound of roulette. Requires sound path include extension.
