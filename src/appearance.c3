module dg;

import raylib5::rl;

struct Appearance
{
    char glyph;
    rl::Color color;
    int sprite_index;
}

const Appearance EMPTY_LOOK = {' ', colors::BLANK, -1 };

const Appearance FLOOR_STONE = { 15 * 16 + 9, colors::DARKER_GREY, 0 * 16 + 0 };
const Appearance FLOOR_DIRT = { ',', {90, 79, 46, 255}, 1 * 16 + 0 };
const Appearance FLOOR_SLABS = { 15 * 16 + 9, colors::DARK_GREY, 2 * 16 + 0 };
const Appearance FLOOR_GRASS = { ',', {37, 66, 40, 255}, 3 * 16 + 0 };

const Appearance WALL_NORTH = { '#', {220, 220, 220, 255}, 0 * 16 + 3 };
const Appearance WALL_SOUTH = { '#', {220, 220, 220, 255}, 2 * 16 + 3 };
const Appearance WALL_EAST = { '#', {220, 220, 220, 255}, 1 * 16 + 4 };
const Appearance WALL_WEST = { '#', {220, 220, 220, 255}, 1 * 16 + 2 };
const Appearance WALL_NE = { '#', {220, 220, 220, 255}, 0 * 16 + 4 };
const Appearance WALL_NW = { '#', {220, 220, 220, 255}, 0 * 16 + 2 };
const Appearance WALL_SE = { '#', {220, 220, 220, 255}, 2 * 16 + 4 };
const Appearance WALL_SW = { '#', {220, 220, 220, 255}, 2 * 16 + 2 };
const Appearance PILLAR = { '#', {220, 220, 220, 255}, 1 * 16 + 3 };

const Appearance DOOR_NORTH_L = { '+', colors::BROWN, 0 * 16 + 5 };
const Appearance DOOR_NORTH_R = { '+', colors::BROWN, 0 * 16 + 6 };
const Appearance DOOR_EAST_U = { '+', colors::BROWN, 0 * 16 + 10 };
const Appearance DOOR_EAST_L = { '+', colors::BROWN, 1 * 16 + 10 };
const Appearance DOOR_SOUTH_L = { '+', colors::BROWN, 1 * 16 + 7 };
const Appearance DOOR_SOUTH_R = { '+', colors::BROWN, 1 * 16 + 8 };
const Appearance DOOR_WEST_U = { '+', colors::BROWN, 0 * 16 + 11 };
const Appearance DOOR_WEST_L = { '+', colors::BROWN, 1 * 16 + 11 };

const Appearance EXIT_WALL_L = { '#', {220, 220, 220, 255}, 3 * 16 + 5 };
const Appearance EXIT_WALL_R = { '#', {220, 220, 220, 255}, 3 * 16 + 6 };
const Appearance EXIT_HOLE_L = { '>', {220, 220, 220, 255}, 4 * 16 + 5 };
const Appearance EXIT_HOLE_R = { '>', {220, 220, 220, 255}, 4 * 16 + 6 };

const Appearance SMALL_ROCKS = { 15 * 16 + 8, colors::DARK_GREY, 0 * 16 + 1 };
const Appearance ROCKS = { 9, colors::DARK_GREY, 1 * 16 + 1 };
const Appearance TREE = { 5, colors::GREEN, 2 * 16 + 1 };
const Appearance STUMP = { 7, colors::DARK_BROWN, 3 * 16 + 1 };
const Appearance CRATE = { 254, colors::BROWN, 3 * 16 + 2 };
const Appearance OPEN_CRATE = { 255, colors::BROWN, 3 * 16 + 3 };
const Appearance SMALL_BOXES = { 255, colors::DARK_BROWN, 3 * 16 + 4 };
const Appearance ANVIL = { 7 * 16 + 15, colors::GREY, 2 * 16 + 5 };
const Appearance FURNACE = { 10, colors::DARK_RED, 2 * 16 + 6 };
const Appearance CAMPFIRE = { 15, colors::RED, 2 * 16 + 7 };
const Appearance FIRE_PIT = { 14 * 16 + 13, colors::GREY, 3 * 16 + 7 };
const Appearance TORCH = { ':', colors::GREY, 4 * 16 + 7 };
const Appearance GRAVE = { 14 * 16 + 10, colors::LIGHT_GREY, 6 * 16 + 15 };
const Appearance GRAVE2 = { 14 * 16 + 15, colors::LIGHT_GREY, 7 * 16 + 15 };
const Appearance ORE1 = { 4, { 195, 40, 195, 255}, 2 * 16 + 9 };
const Appearance ORE2 = { 4, { 15, 191, 175, 255}, 2 * 16 + 11 };
const Appearance ORE3 = { 4, { 243, 192, 37, 255}, 5 * 16 + 11 };

const Appearance TRADER = { 'T', colors::DARK_GREEN, 4 * 16 + 4 };

const Appearance PLAYER_NAKED = { '@', {255, 255, 255, 255}, 4 * 16 + 2 };
const Appearance WARRIOR_IDLE1 = { '@', {255, 255, 255, 255}, 6 * 16 + 2 };
const Appearance WARRIOR_IDLE2 = { '@', {255, 255, 255, 255}, 6 * 16 + 1 };
const Appearance WARRIOR_POINT = { '@', {255, 255, 255, 255}, 6 * 16 + 0 };

const Appearance GOBLIN_IDLE1 = { 'g', {0, 255, 0, 255}, 9 * 16 + 5 };
const Appearance GOBLIN_IDLE2 = { 'g', {0, 255, 0, 255}, 9 * 16 + 4 };
const Appearance GOBLIN_POINT = { 'g', {0, 255, 0, 255}, 9 * 16 + 3 };
