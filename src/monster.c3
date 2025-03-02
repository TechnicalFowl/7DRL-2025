module dg;

import std::collections::map;
import std::io;
import std::math;
import raylib5::rl;

enum MonsterType : inline int
{
    GOBLIN,
    GOBLIN_ARCHER,
    GOBLIN_MAGE,
    BANDIT,
    BANDIT_RANGER,
    BANDIT_MAGE,
    DARK_MAGE,
    DARK_KNIGHT,
    ASSASSIN,
}
const int MONSTER_COUNT = (int) MonsterType.elements;

const MonsterType[3] WARRIOR_TYPES = { GOBLIN, BANDIT, DARK_KNIGHT };
const MonsterType[3] ARCHER_TYPES = { GOBLIN_ARCHER, BANDIT_RANGER, ASSASSIN };
const MonsterType[3] MAGE_TYPES = { GOBLIN_MAGE, BANDIT_MAGE, DARK_MAGE };

struct MonsterInfo
{
    MonsterType type;
    String name;
    Appearance[3] looks;
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
    self.mobs[MonsterType.GOBLIN] = { GOBLIN, "Goblin", { GOBLIN_IDLE1, GOBLIN_IDLE2, GOBLIN_POINT } };
    self.mobs[MonsterType.GOBLIN_ARCHER] = { GOBLIN_ARCHER, "Goblin Archer", { GOBLIN_ARCHER_IDLE1, GOBLIN_ARCHER_IDLE2, GOBLIN_ARCHER_POINT } };
    self.mobs[MonsterType.GOBLIN_MAGE] = { GOBLIN_MAGE, "Goblin Mage", { GOBLIN_MAGE_IDLE1, GOBLIN_MAGE_IDLE2, GOBLIN_MAGE_POINT } };
    self.mobs[MonsterType.BANDIT] = { BANDIT, "Bandit", { BANDIT_IDLE1, BANDIT_IDLE2, BANDIT_POINT } };
    self.mobs[MonsterType.BANDIT_RANGER] = { BANDIT_RANGER, "Bandit Ranger", { BANDIT_RANGER_IDLE1, BANDIT_RANGER_IDLE2, BANDIT_RANGER_POINT } };
    self.mobs[MonsterType.BANDIT_MAGE] = { BANDIT_MAGE, "Bandit Mage", { BANDIT_MAGE_IDLE1, BANDIT_MAGE_IDLE2, BANDIT_MAGE_POINT } };
    self.mobs[MonsterType.DARK_MAGE] = { DARK_MAGE, "Dark Mage", { DARK_MAGE_IDLE1, DARK_MAGE_IDLE2, DARK_MAGE_POINT } };
    self.mobs[MonsterType.DARK_KNIGHT] = { DARK_KNIGHT, "Dark Knight", { DARK_KNIGHT_IDLE1, DARK_KNIGHT_IDLE2, DARK_KNIGHT_POINT } };
    self.mobs[MonsterType.ASSASSIN] = { ASSASSIN, "Assassin", { ASSASSIN_IDLE1, ASSASSIN_IDLE2, ASSASSIN_POINT } };
    
    for (int i = 0; i < MONSTER_COUNT; ++i)
    {
        MonsterInfo* info = &self.mobs[i];
        assert(info.type.ordinal == i, "MonsterCache: Monster in %d slot is not correct (expected %s)", i, MonsterType.names[i]);
        self.mob_names.set(info.name, info.type);
    }
}

fn Monster* spawn_monster(Zone* zone, IVec2 pos, MonsterType type)
{
    Monster* mob = mem::new(Monster);
    mob.new_init(zone, type, pos);
    zone.add_entity(mob);
    return mob;
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
    MonsterInfo* info = &g_mobs.mobs[t.ordinal];
    self.entity.new_init(z, info.name, p, ...info.looks);
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

    // @Todo: Process behavior

    WaitAction* wait = mem::temp_alloc(WaitAction);
    wait.time = max_time - self.idle_time;
    return wait;
}
