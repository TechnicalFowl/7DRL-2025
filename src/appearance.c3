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
const Appearance FLOOR_ROUGH_STONE = { '.', colors::DARK_GREY, 11 * 16 + 5 };
const Appearance FLOOR_CLEAN_STONE = { '.', colors::DARKER_GREY, 11 * 16 + 6 };

const Appearance WALL_NORTH = { '#', {220, 220, 220, 255}, 0 * 16 + 3 };
const Appearance WALL_SOUTH = { '#', {220, 220, 220, 255}, 2 * 16 + 3 };
const Appearance WALL_EAST = { '#', {220, 220, 220, 255}, 1 * 16 + 4 };
const Appearance WALL_WEST = { '#', {220, 220, 220, 255}, 1 * 16 + 2 };
const Appearance WALL_NE = { '#', {220, 220, 220, 255}, 0 * 16 + 4 };
const Appearance WALL_NW = { '#', {220, 220, 220, 255}, 0 * 16 + 2 };
const Appearance WALL_SE = { '#', {220, 220, 220, 255}, 2 * 16 + 4 };
const Appearance WALL_SW = { '#', {220, 220, 220, 255}, 2 * 16 + 2 };
const Appearance PILLAR = { '#', {220, 220, 220, 255}, 1 * 16 + 3 };

const Appearance DOOR_LOCKED_NORTH_L = { '+', colors::GREY, 0 * 16 + 5 };
const Appearance DOOR_LOCKED_NORTH_R = { '+', colors::GREY, 0 * 16 + 6 };
const Appearance DOOR_LOCKED_EAST_U = { '+', colors::GREY, 0 * 16 + 10 };
const Appearance DOOR_LOCKED_EAST_L = { '+', colors::GREY, 1 * 16 + 10 };
const Appearance DOOR_LOCKED_SOUTH_L = { '+', colors::GREY, 1 * 16 + 7 };
const Appearance DOOR_LOCKED_SOUTH_R = { '+', colors::GREY, 1 * 16 + 8 };
const Appearance DOOR_LOCKED_WEST_U = { '+', colors::GREY, 0 * 16 + 11 };
const Appearance DOOR_LOCKED_WEST_L = { '+', colors::GREY, 1 * 16 + 11 };

const Appearance DOOR_NORTH_L = { '+', colors::BROWN, 12 * 16 + 0 };
const Appearance DOOR_NORTH_R = { '+', colors::BROWN, 12 * 16 + 1 };
const Appearance DOOR_EAST_U = { '+', colors::BROWN, 12 * 16 + 2 };
const Appearance DOOR_EAST_L = { '+', colors::BROWN, 13 * 16 + 2 };
const Appearance DOOR_SOUTH_L = { '+', colors::BROWN, 13 * 16 + 0 };
const Appearance DOOR_SOUTH_R = { '+', colors::BROWN, 13 * 16 + 1 };
const Appearance DOOR_WEST_U = { '+', colors::BROWN, 12 * 16 + 3 };
const Appearance DOOR_WEST_L = { '+', colors::BROWN, 13 * 16 + 3 };

const Appearance DOOR_BOSS_NORTH_L = { '+', colors::DARK_RED, 12 * 16 + 4 };
const Appearance DOOR_BOSS_NORTH_R = { '+', colors::DARK_RED, 12 * 16 + 5 };
const Appearance DOOR_BOSS_EAST_U = { '+', colors::DARK_RED, 12 * 16 + 6 };
const Appearance DOOR_BOSS_EAST_L = { '+', colors::DARK_RED, 13 * 16 + 6 };
const Appearance DOOR_BOSS_SOUTH_L = { '+', colors::DARK_RED, 13 * 16 + 4 };
const Appearance DOOR_BOSS_SOUTH_R = { '+', colors::DARK_RED, 13 * 16 + 5 };
const Appearance DOOR_BOSS_WEST_U = { '+', colors::DARK_RED, 12 * 16 + 7 };
const Appearance DOOR_BOSS_WEST_L = { '+', colors::DARK_RED, 13 * 16 + 7 };

const Appearance DOOR_OPEN_NORTH_L = { '/', colors::BROWN, 1 * 16 + 5 };
const Appearance DOOR_OPEN_NORTH_R = { '\\', colors::BROWN, 1 * 16 + 6 };
const Appearance DOOR_OPEN_EAST_U = { '\\', colors::BROWN, 0 * 16 + 9 };
const Appearance DOOR_OPEN_EAST_L = { '/', colors::BROWN, 1 * 16 + 9 };
const Appearance DOOR_OPEN_SOUTH_L = { '\\', colors::BROWN, 0 * 16 + 7 };
const Appearance DOOR_OPEN_SOUTH_R = { '/', colors::BROWN, 0 * 16 + 8 };
const Appearance DOOR_OPEN_WEST_U = { '/', colors::BROWN, 0 * 16 + 12 };
const Appearance DOOR_OPEN_WEST_L = { '\\', colors::BROWN, 1 * 16 + 12 };

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
const Appearance ORE_ROCK1 = { 4, { 195, 40, 195, 255}, 2 * 16 + 9 };
const Appearance ORE_ROCK2 = { 4, { 15, 191, 175, 255}, 2 * 16 + 11 };
const Appearance ORE_ROCK3 = { 4, { 243, 192, 37, 255}, 5 * 16 + 11 };

const Appearance TRADER = { 'T', colors::DARK_GREEN, 4 * 16 + 4 };

const Appearance PLAYER_NAKED = { '@', {255, 255, 255, 255}, 4 * 16 + 2 };
const Appearance NAKED_IDLE1 = { '@', {255, 255, 255, 255}, 11 * 16 + 2 };
const Appearance NAKED_IDLE2 = { '@', {255, 255, 255, 255}, 11 * 16 + 1 };
const Appearance NAKED_POINT = { '@', {255, 255, 255, 255}, 11 * 16 + 0 };

const Appearance WARRIOR_IDLE1 = { '@', {255, 255, 255, 255}, 6 * 16 + 2 };
const Appearance WARRIOR_IDLE2 = { '@', {255, 255, 255, 255}, 6 * 16 + 1 };
const Appearance WARRIOR_POINT = { '@', {255, 255, 255, 255}, 6 * 16 + 0 };

const Appearance MAGE_IDLE1 = { '@', {255, 255, 255, 255}, 5 * 16 + 2 };
const Appearance MAGE_IDLE2 = { '@', {255, 255, 255, 255}, 5 * 16 + 1 };
const Appearance MAGE_POINT = { '@', {255, 255, 255, 255}, 5 * 16 + 0 };

const Appearance RANGER_IDLE1 = { '@', {255, 255, 255, 255}, 7 * 16 + 2 };
const Appearance RANGER_IDLE2 = { '@', {255, 255, 255, 255}, 7 * 16 + 1 };
const Appearance RANGER_POINT = { '@', {255, 255, 255, 255}, 7 * 16 + 0 };

const Appearance GOBLIN_IDLE1 = { 'g', {116, 122, 82, 255}, 9 * 16 + 5 };
const Appearance GOBLIN_IDLE2 = { 'g', {116, 122, 82, 255}, 9 * 16 + 4 };
const Appearance GOBLIN_POINT = { 'g', {116, 122, 82, 255}, 9 * 16 + 3 };

const Appearance GOBLIN_ARCHER_IDLE1 = { 'c', {116, 178, 37, 255}, 10 * 16 + 5 };
const Appearance GOBLIN_ARCHER_IDLE2 = { 'c', {116, 178, 37, 255}, 10 * 16 + 4 };
const Appearance GOBLIN_ARCHER_POINT = { 'c', {116, 178, 37, 255}, 10 * 16 + 3 };

const Appearance GOBLIN_MAGE_IDLE1 = { 'h', {62, 122, 124, 255}, 8 * 16 + 5 };
const Appearance GOBLIN_MAGE_IDLE2 = { 'h', {62, 122, 124, 255}, 8 * 16 + 4 };
const Appearance GOBLIN_MAGE_POINT = { 'h', {62, 122, 124, 255}, 8 * 16 + 3 };

const Appearance BANDIT_IDLE1 = { 'b', {122, 53, 38, 255}, 6 * 16 + 5 };
const Appearance BANDIT_IDLE2 = { 'b', {122, 53, 38, 255}, 6 * 16 + 4 };
const Appearance BANDIT_POINT = { 'b', {122, 53, 38, 255}, 6 * 16 + 3 };

const Appearance BANDIT_RANGER_IDLE1 = { 'a', {122, 143, 38, 255}, 7 * 16 + 5 };
const Appearance BANDIT_RANGER_IDLE2 = { 'a', {122, 143, 38, 255}, 7 * 16 + 4 };
const Appearance BANDIT_RANGER_POINT = { 'a', {122, 143, 38, 255}, 7 * 16 + 3 };

const Appearance BANDIT_MAGE_IDLE1 = { 'm', {46, 61, 147, 255}, 6 * 16 + 5 };
const Appearance BANDIT_MAGE_IDLE2 = { 'm', {46, 61, 147, 255}, 6 * 16 + 4 };
const Appearance BANDIT_MAGE_POINT = { 'm', {46, 61, 147, 255}, 6 * 16 + 3 };

const Appearance DARK_MAGE_IDLE1 = { 'M', {89, 41, 122, 255}, 8 * 16 + 2 };
const Appearance DARK_MAGE_IDLE2 = { 'M', {89, 41, 122, 255}, 8 * 16 + 1 };
const Appearance DARK_MAGE_POINT = { 'M', {89, 41, 122, 255}, 8 * 16 + 0 };

const Appearance DARK_KNIGHT_IDLE1 = { 'k', {89, 41, 122, 255}, 9 * 16 + 2 };
const Appearance DARK_KNIGHT_IDLE2 = { 'k', {89, 41, 122, 255}, 9 * 16 + 1 };
const Appearance DARK_KNIGHT_POINT = { 'k', {89, 41, 122, 255}, 9 * 16 + 0 };

const Appearance ASSASSIN_IDLE1 = { 'A', {89, 41, 122, 255}, 10 * 16 + 2 };
const Appearance ASSASSIN_IDLE2 = { 'A', {89, 41, 122, 255}, 10 * 16 + 1 };
const Appearance ASSASSIN_POINT = { 'A', {89, 41, 122, 255}, 10 * 16 + 0 };

const Appearance ITEM_SWORD0 = { '/', colors::SILVER, 2 * 16 + 8 };
const Appearance ITEM_SWORD1 = { '/', colors::PINK, 2 * 16 + 10 };
const Appearance ITEM_SWORD2 = { '/', colors::CYAN, 2 * 16 + 12 };
const Appearance ITEM_SWORD3 = { '/', colors::GOLD, 5 * 16 + 12 };

const Appearance ITEM_STAFF0 = { '|', colors::SILVER, 3 * 16 + 8 };
const Appearance ITEM_STAFF1 = { '|', colors::PINK, 3 * 16 + 10 };
const Appearance ITEM_STAFF2 = { '|', colors::CYAN, 3 * 16 + 12 };
const Appearance ITEM_STAFF3 = { '|', colors::GOLD, 6 * 16 + 12 };

const Appearance ITEM_BOW0 = { '}', colors::SILVER, 4 * 16 + 8 };
const Appearance ITEM_BOW1 = { '}', colors::PINK, 4 * 16 + 10 };
const Appearance ITEM_BOW2 = { '}', colors::CYAN, 4 * 16 + 12 };
const Appearance ITEM_BOW3 = { '}', colors::GOLD, 7 * 16 + 12 };

const Appearance ITEM_INGOT1 = { '-', colors::PINK, 3 * 16 + 9 };
const Appearance ITEM_INGOT2 = { '-', colors::CYAN, 3 * 16 + 11 };
const Appearance ITEM_INGOT3 = { '-', colors::GOLD, 6 * 16 + 11 };

const Appearance ITEM_ORE1 = { ':', colors::PINK, 4 * 16 + 9 };
const Appearance ITEM_ORE2 = { ':', colors::CYAN, 4 * 16 + 11 };
const Appearance ITEM_ORE3 = { ':', colors::GOLD, 7 * 16 + 11 };

const Appearance ITEM_AXE = { '1', colors::SILVER, 5 * 16 + 7 };
const Appearance ITEM_PICKAXE = { '7', colors::SILVER, 6 * 16 + 7 };
const Appearance ITEM_KNIFE = { '\'', colors::SILVER, 5 * 16 + 8 };
const Appearance ITEM_NEEDLE = {'`', colors::SILVER, 6 * 16 + 8 };
const Appearance ITEM_GATESTONE = { 14 * 16 + 8, colors::PURPLE, 7 * 16 + 7 };
const Appearance ITEM_FOOD = { '%', colors::GREEN, 8 * 16 + 7 };
const Appearance ITEM_COINS = { '$', colors::GOLD, 9 * 16 + 8 };
const Appearance ITEM_KEY = { '?', colors::GOLD, 10 * 16 + 8 };
const Appearance ITEM_LOGS = { '=', colors::BROWN, 7 * 16 + 8 };

const Appearance ITEM_AIR_RUNE = { 10 * 16 + 15, colors::SILVER, 5 * 16 + 6 };
const Appearance ITEM_WATER_RUNE = { 14 * 16 + 11, colors::BLUE, 6 * 16 + 6 };
const Appearance ITEM_EARTH_RUNE = { 15 * 16 + 7, colors::BROWN, 7 * 16 + 6 };
const Appearance ITEM_FIRE_RUNE = { 14 * 16 + 7, colors::RED, 8 * 16 + 6 };
const Appearance ITEM_BLOOD_RUNE = { 14 * 16 + 1, colors::DARK_RED, 13 * 16 + 8 };
const Appearance ITEM_NATURE_RUNE = { 14 * 16 + 10, colors::DARK_GREEN, 13 * 16 + 9 };
const Appearance ITEM_CHAOS_RUNE = { 1, colors::YELLOW, 12 * 16 + 9 };
const Appearance ITEM_BLANK_RUNE = { '0', colors::WHITE, 12 * 16 + 8 };

const Appearance ITEM_AMULET1 = { '9', colors::GREEN, 5 * 16 + 9 };
const Appearance ITEM_AMULET2 = { '9', colors::RED, 5 * 16 + 10 };
const Appearance ITEM_AMULET3 = { '9', colors::PURPLE, 8 * 16 + 9 };

const Appearance ITEM_RING1 = { '6', colors::GREEN, 6 * 16 + 9 };
const Appearance ITEM_RING2 = { '6', colors::RED, 6 * 16 + 10 };
const Appearance ITEM_RING3 = { '6', colors::PURPLE, 9 * 16 + 9 };

const Appearance ITEM_POTION1 = { '&', colors::RED, 7 * 16 + 9 };
const Appearance ITEM_POTION2 = { '&', colors::GREEN, 7 * 16 + 10 };
const Appearance ITEM_POTION3 = { '&', colors::CYAN, 10 * 16 + 9 };

const Appearance ITEM_HELM1 = { 15 * 16 + 12, colors::PINK, 8 * 16 + 10 };
const Appearance ITEM_HELM2 = { 15 * 16 + 12, colors::CYAN, 8 * 16 + 11 };
const Appearance ITEM_HELM3 = { 15 * 16 + 12, colors::GOLD, 8 * 16 + 12 };

const Appearance ITEM_HOOD1 = { 15 * 16 + 13, colors::PINK, 9 * 16 + 10 };
const Appearance ITEM_HOOD2 = { 15 * 16 + 13, colors::CYAN, 9 * 16 + 11 };
const Appearance ITEM_HOOD3 = { 15 * 16 + 13, colors::GOLD, 9 * 16 + 12 };

const Appearance ITEM_WIZARD_HAT1 = { '^', colors::PINK, 10 * 16 + 10 };
const Appearance ITEM_WIZARD_HAT2 = { '^', colors::CYAN, 10 * 16 + 11 };
const Appearance ITEM_WIZARD_HAT3 = { '^', colors::GOLD, 10 * 16 + 12 };

const Appearance ITEM_BODY1 = { 16 + 14, colors::PINK, 13 };
const Appearance ITEM_BODY2 = { 16 + 14, colors::CYAN, 14 };
const Appearance ITEM_BODY3 = { 16 + 14, colors::GOLD, 15 };

const Appearance ITEM_SHIELD1 = { 15 * 16 + 9, colors::PINK, 1 * 16 + 13 };
const Appearance ITEM_SHIELD2 = { 15 * 16 + 9, colors::CYAN, 1 * 16 + 14 };
const Appearance ITEM_SHIELD3 = { 15 * 16 + 9, colors::GOLD, 1 * 16 + 15 };

const Appearance ITEM_LEGS1 = { 16 + 15, colors::PINK, 2 * 16 + 13 };
const Appearance ITEM_LEGS2 = { 16 + 15, colors::CYAN, 2 * 16 + 14 };
const Appearance ITEM_LEGS3 = { 16 + 15, colors::GOLD, 2 * 16 + 15 };