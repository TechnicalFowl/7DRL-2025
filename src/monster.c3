module dg;

import std::collections::map;
import std::io;
import std::math;
import raylib5::rl;

enum MonsterType : int
{
    GOBLIN,
}
const int MONSTER_COUNT = (int) MonsterType.elements;

struct MonsterInfo
{
    MonsterType type;
    String name;
    char glyph;
    rl::Color color;
}

struct MonsterCache
{
    MonsterInfo[MONSTER_COUNT] mobs;
    HashMap(<String, MonsterType>) mob_names;
}
MonsterCache g_mobs;

fn void MonsterCache.new_init(&self)
{
    self.mob_names.new_init();
    self.mobs[MonsterType.GOBLIN] = { GOBLIN, "Goblin", 'g', colors::GREEN};
    
    for (int i = 0; i < MONSTER_COUNT; ++i)
    {
        MonsterInfo* info = &self.mobs[i];
        assert(info.type.ordinal == i, "MonsterCache: Monster in %d slot is not correct (expected %s)", i, MonsterType.names[i]);
        self.mob_names.set(info.name, info.type);
    }
}

struct Monster (Entity)
{
    inline EntityCommon entity;

    Navigator nav;

    MonsterType type;
}

// @Todo: There should be an easy way to avoid this boilerplate?...
fn Zone* Monster.get_zone(&self) @dynamic => self.entity.get_zone();
fn String Monster.get_name(&self) @dynamic => self.entity.get_name();
fn IVec2 Monster.get_position(&self) @dynamic => self.entity.get_position();
fn void Monster.set_position(&self, IVec2 pos) @dynamic => self.entity.set_position(pos);
fn Appearance Monster.get_look(&self) @dynamic => self.entity.get_look();
fn double Monster.get_idle_time(&self) @dynamic => self.entity.get_idle_time();
fn void Monster.give_idle_time(&self, double time) @dynamic => self.entity.give_idle_time(time);

fn void Monster.new_init(&self, Zone* z, MonsterType t, IVec2 p)
{
    self.type = t;
    String name;
    char glyph = '?';
    rl::Color color = colors::MAGENTA;

    Appearance[3] looks; 

    switch (t)
    {
    case GOBLIN:
        glyph = 'g';
        color = colors::GREEN;
        name = "Goblin";

        looks = { GOBLIN_IDLE1, GOBLIN_IDLE2, GOBLIN_POINT };
    default:
        unreachable();
    }

    self.entity.new_init(z, name, p, ...looks);
    self.nav.new_init();
}

fn void Monster.free(&self) @dynamic
{
    self.entity.free();
    self.nav.free();
}

enum Behavior
{
    IDLE,
    WANDER,
    CHASE,
    FLEE,
}

fn Action Monster.next_action(&self, double max_time) @dynamic
{
    if (max_time <= 0) return null;

    Behavior behave = IDLE;

    switch (self.type)
    {
    case GOBLIN:
        break;
    default:
        unreachable();
    }

    // @Todo: Process behavior

    WaitAction* wait = mem::temp_alloc(WaitAction);
    wait.time = max_time - self.idle_time;
    return wait;
}
