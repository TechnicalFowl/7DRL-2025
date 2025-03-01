module dg;

import std::collections::list;
import std::collections::map;
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
            zone.set_terrain(pos.x + 7, pos.y, '+', colors::BROWN, colors::BLACK, true);
            zone.set_terrain(pos.x + 8, pos.y, '+', colors::BROWN, colors::BLACK, true);
        case EAST:
            zone.set_terrain(pos.x + 15, pos.y + 7, '+', colors::BROWN, colors::BLACK, true);
            zone.set_terrain(pos.x + 15, pos.y + 8, '+', colors::BROWN, colors::BLACK, true);
            zone.set_terrain(pos.x + 16, pos.y + 7, ' ', colors::BROWN, colors::BLACK, true);
            zone.set_terrain(pos.x + 16, pos.y + 8, ' ', colors::BROWN, colors::BLACK, true);
        case SOUTH:
            zone.set_terrain(pos.x + 7, pos.y + 15, '+', colors::BROWN, colors::BLACK, true);
            zone.set_terrain(pos.x + 8, pos.y + 15, '+', colors::BROWN, colors::BLACK, true);
            zone.set_terrain(pos.x + 7, pos.y + 16, ' ', colors::BROWN, colors::BLACK, true);
            zone.set_terrain(pos.x + 8, pos.y + 16, ' ', colors::BROWN, colors::BLACK, true);
        case WEST:
            zone.set_terrain(pos.x, pos.y + 7, '+', colors::BROWN, colors::BLACK, true);
            zone.set_terrain(pos.x, pos.y + 8, '+', colors::BROWN, colors::BLACK, true);
        default:
            unreachable();
        }
    }
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