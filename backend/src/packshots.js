// Photos shot on a plain light background. Clients show them uncropped, so the
// API tags their URLs with `?packshot=1` (the static server ignores the query).
export const PACKSHOT_STEMS = new Set([
  'product_shirt_star_print', 'product_sneaker_black_air',
  'product_smartphone_blue', 'product_game_console_bundle',
  'product_shoes_leather_brogue', 'product_muesli_chocolate',
  'product_sneaker_basketball_red', 'product_sandals_beige',
  'product_lipstick_red', 'product_heels_white', 'product_watch_steel_grey',
]);

export const stemOf = (path) => path.split('/').pop().replace(/\.[^.]+$/, '');
export const isPackshot = (path) => PACKSHOT_STEMS.has(stemOf(path));
