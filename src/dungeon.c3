module dg;

import std::collections::list;
import std::collections::map;
import std::io;
import std::math;

enum Direction : (IVec2 dir)
{
    NONE = {0, 0},
    NORTH = {0, -1},
    EAST = {1, 0},
    SOUTH = {0, 1},
    WEST = {-1, 0},
}

const Direction[5] ROTATE_LEFT = { NONE, WEST, NORTH, EAST, SOUTH };
const Direction[5] ROTATE_RIGHT = { NONE, EAST, SOUTH, WEST, NORTH };
const Direction[5] FLIP = { NONE, SOUTH, WEST, NORTH, EAST };

struct MonsterSpawn
{
    MonsterType type;
    IVec2 position;
}

struct ItemSpawn
{
    Item item;
    IVec2 position;
    int count;
}

enum HotspotType
{
    EMPTY,
}

struct ResourceSpawn
{
    HotspotType type;
    IVec2 position;
    IVec2 size;
}

enum DoorType
{
    WALL,
    UNLOCKED,
    LOCKED,
    SECRET,
    SKILL_CHECK,
}

struct Door
{
    DoorType type;
    Direction direction;
}

enum RoomType
{
    EMPTY,
    STARTING,
    BOSS,
    STANDARD,
    SPECIAL,
}

struct Room
{
    IVec2 position;
    IVec2 size;

    RoomType type;
    int distance_from_start;
    Door[4] doors;

    List(<MonsterSpawn>) monsters;
    List(<ItemSpawn>) items;
    List(<ResourceSpawn>) resources;
}

fn void Room.new_init(&self, IVec2 pos, IVec2 sz)
{
    self.position = pos;
    self.size = sz;

    self.monsters.new_init();
    self.items.new_init();
    self.resources.new_init();
    self.distance_from_start = 99;
}

fn void Room.free(&self)
{
    self.monsters.free();
    self.items.free();
    self.resources.free();
}

fn void Room.generate(&self, Zone* zone, random::Pcg32Random* rng)
{
    IVec2 pos = self.position;
    for (int i = 0; i < 4; ++i)
    {
        Door* d = &self.doors[i];
        if (d.type == WALL) continue;
        assert(d.direction.ordinal == i + 1);
        switch (d.direction)
        {
        case NORTH:
            zone.set_terrain(pos.x + 7, pos.y, '+', colors::BROWN, colors::BLACK, false);
            zone.set_terrain(pos.x + 8, pos.y, '+', colors::BROWN, colors::BLACK, false);
        case EAST:
            zone.set_terrain(pos.x + 15, pos.y + 7, '+', colors::BROWN, colors::BLACK, false);
            zone.set_terrain(pos.x + 15, pos.y + 8, '+', colors::BROWN, colors::BLACK, false);
        case SOUTH:
            zone.set_terrain(pos.x + 7, pos.y + 15, '+', colors::BROWN, colors::BLACK, false);
            zone.set_terrain(pos.x + 8, pos.y + 15, '+', colors::BROWN, colors::BLACK, false);
        case WEST:
            zone.set_terrain(pos.x, pos.y + 7, '+', colors::BROWN, colors::BLACK, false);
            zone.set_terrain(pos.x, pos.y + 8, '+', colors::BROWN, colors::BLACK, false);
        default:
            unreachable();
        }
    }
    zone.set_terrain(pos.x, pos.y + 16, 'D', colors::WHITE, colors::BLACK, false);
    zone.set_terrain(pos.x + 1, pos.y + 16, ':', colors::WHITE, colors::BLACK, false);
    zone.set_terrain(pos.x + 2, pos.y + 16, (char) (self.distance_from_start / 10) + '0', colors::WHITE, colors::BLACK, false);
    zone.set_terrain(pos.x + 3, pos.y + 16, (char) (self.distance_from_start % 10) + '0', colors::WHITE, colors::BLACK, false);

    if (self.type == EMPTY)
    {
        self.type = random::next_in_range(rng, 0, 5) == 0 ? SPECIAL : STANDARD;
    }

    switch (self.type)
    {
    case STARTING:
        zone.set_terrain(pos.x + 15, pos.y + 16, 'S', colors::WHITE, colors::BLACK, false);
    case BOSS:
        zone.set_terrain(pos.x + 15, pos.y + 16, 'B', colors::WHITE, colors::BLACK, false);
    case STANDARD:
        zone.set_terrain(pos.x + 15, pos.y + 16, 'R', colors::WHITE, colors::BLACK, false);
    case SPECIAL:
        zone.set_terrain(pos.x + 15, pos.y + 16, 'P', colors::WHITE, colors::BLACK, false);
    default:
        zone.set_terrain(pos.x + 15, pos.y + 16, '?', colors::WHITE, colors::BLACK, false);
    }
}

fn Room*! find_room(IVec2 pos)
{
    IVec2 room_pos = { pos.x / 17, pos.y / 17 };
    return current_floor.rooms.get(room_pos);
}

fn Direction get_door_direction(IVec2 pos)
{
    IVec2 lpos = { pos.x % 17, pos.y % 17 };
    Direction dir;
    if (lpos.x > 2 && lpos.x < 14)
    {
        if (lpos.y == 0) {dir = NORTH;}
        else if (lpos.y == 15) {dir = SOUTH;}
        else {unreachable();}
    }
    else if (lpos.x == 0) {dir = WEST;}
    else if (lpos.x == 15) {dir = EAST;}
    else {io::printfn("Invalid door pos %d %d", ...lpos); unreachable();}
    return dir;
}

struct DungeonFloor
{
    int depth;
    HashMap(<IVec2, Room*>) rooms;
}

fn void DungeonFloor.new_init(&self, int d)
{
    self.depth = d;
    self.rooms.new_init();
}

fn void DungeonFloor.free(&self)
{
    self.rooms.@each(; IVec2 p, Room* r)
    {
        r.free();
        mem::free(r);
    };
    self.rooms.free();
}