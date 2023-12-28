#if defined _drand_included
  #endinput
#endif
#define _drand_included


/**
 * Start the difficulty selection roulette
 * 
 * @param   countdownTime   int    | Countdown time
 * @param   ignoreLimit     bool   | Ignore reroll limit specified in per map.
 * 
 * @return bool value | true if roulette successfully executed, otherwise false.
 */
native bool StartRoulette(int countdownTime, bool ignoreLimit);