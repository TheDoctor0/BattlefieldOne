#if defined _bf1_included
  #endinput
#endif
#define _bf1_included

#define get_bit(%2,%1) (%1 & (1<<(%2&31)))
#define set_bit(%2,%1) (%1 |= (1<<(%2&31)))
#define rem_bit(%2,%1) (%1 &= ~(1 <<(%2&31)))

#define is_user_valid(%1) (1 <= %1 <= MAX_PLAYERS)

/**
 * Returns how many badges are available.
 *
 * @return          Badges count
 */
native bf1_get_maxbadges();

/**
 * Returns how many badges are available.
 *
 * @param badge     Badge index
 * @param level     Badge level
 * @param data      Buffer to copy badge name to
 * @param lenth     Maximum buffer size
 *
 * @noreturn
 */
native bf1_get_badge_name(badge, level, data[], length);

/**
 * Returns level for player badge.
 *
 * @param badge     Badge index
 * @param level     Badge index
 *
 * @return          Badge level
 */
native bf1_get_user_badge(id, badge);

/**
 * Sets level for player badge.
 *
 * @param id        Player index
 * @param badge     Badge index
 * @param level     Badge index
 *
 * @noreturn
 */
native bf1_set_user_badge(id, badge, level);

/**
 * Checks if player is a VIP.
 *
 * @param id        Player index
 *
 * @return          1 if player is a VIP, 0 otherwise
 */
native bf1_get_user_vip(id);