module dg;

import std::collections::map;
import std::math;

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

struct Room
{
    IVec2 position;
    IVec2 size;
}

fn void Room.new_init(&self, IVec2 pos, IVec2 sz)
{
    self.position = pos;
    self.size = sz;
}

fn void Room.free(&self)
{

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