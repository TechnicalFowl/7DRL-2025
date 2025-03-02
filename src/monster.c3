module dg;

import std::collections::list;
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

    double range;
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
    self.mobs[MonsterType.GOBLIN] = { GOBLIN, "Goblin", { GOBLIN_IDLE1, GOBLIN_IDLE2, GOBLIN_POINT }, 1.5 };
    self.mobs[MonsterType.GOBLIN_ARCHER] = { GOBLIN_ARCHER, "Goblin Archer", { GOBLIN_ARCHER_IDLE1, GOBLIN_ARCHER_IDLE2, GOBLIN_ARCHER_POINT }, 4 };
    self.mobs[MonsterType.GOBLIN_MAGE] = { GOBLIN_MAGE, "Goblin Mage", { GOBLIN_MAGE_IDLE1, GOBLIN_MAGE_IDLE2, GOBLIN_MAGE_POINT }, 5 };
    self.mobs[MonsterType.BANDIT] = { BANDIT, "Bandit", { BANDIT_IDLE1, BANDIT_IDLE2, BANDIT_POINT }, 1.5 };
    self.mobs[MonsterType.BANDIT_RANGER] = { BANDIT_RANGER, "Bandit Ranger", { BANDIT_RANGER_IDLE1, BANDIT_RANGER_IDLE2, BANDIT_RANGER_POINT }, 7 };
    self.mobs[MonsterType.BANDIT_MAGE] = { BANDIT_MAGE, "Bandit Mage", { BANDIT_MAGE_IDLE1, BANDIT_MAGE_IDLE2, BANDIT_MAGE_POINT }, 6 };
    self.mobs[MonsterType.DARK_MAGE] = { DARK_MAGE, "Dark Mage", { DARK_MAGE_IDLE1, DARK_MAGE_IDLE2, DARK_MAGE_POINT }, 7 };
    self.mobs[MonsterType.DARK_KNIGHT] = { DARK_KNIGHT, "Dark Knight", { DARK_KNIGHT_IDLE1, DARK_KNIGHT_IDLE2, DARK_KNIGHT_POINT }, 1.5 };
    self.mobs[MonsterType.ASSASSIN] = { ASSASSIN, "Assassin", { ASSASSIN_IDLE1, ASSASSIN_IDLE2, ASSASSIN_POINT }, 4 };
    
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

    MonsterType type;
    MonsterInfo* info;
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
    self.info = &g_mobs.mobs[t.ordinal];
    self.entity.new_init(z, self.info.name, p, ...self.info.looks);
}

fn void Monster.free(&self) @dynamic
{
    self.entity.free();
}

enum Behavior
{
    IDLE,
    WANDER,
    CHASE,
    ATTACK,
}

fn Action Monster.next_action(&self, double max_time) @dynamic
{
    if (max_time <= 0) return null;

    Behavior behave = IDLE;
    
    IVec2 player_pos = self.get_zone().player.get_position();
    IVec2 player_room = { player_pos.x / 17, player_pos.y / 17 };
    IVec2 mob_room = { self.get_position().x / 17, self.get_position().y / 17 };

    if (player_room == mob_room)
    {
        double dist = ivec2_fdistance(player_pos, self.get_position());
        if (dist < self.info.range)
        {
            behave = ATTACK;
        }
        else
        {
            behave = CHASE;
        }
    }
    else
    {
        if (random::next_in_range(&g_rng, 0, 5) == 0)
        {
            behave = WANDER;
        }
        else
        {
            behave = IDLE;
        }
    }

    switch (behave)
    {
    case IDLE:
        break;
    case CHASE:
        List(<IVec2>) path;
        path.temp_init();
        self.get_zone().path(self.get_position(), player_pos, &path, diagonal_moves: true, reverse: true);
        if (path.is_empty())
        {
            break;
        }
        IVec2 next_pos = path.pop()!!;
        IVec2 next_move = next_pos - self.entity.position;
        ZoneCell* next_cell = self.get_zone().get_cell(...next_pos);
        if (next_cell.isPassable())
        {
            return do_move(next_move);
        }
    case WANDER:
        IVec2 move = { random::next_in_range(&g_rng, -1, 1), random::next_in_range(&g_rng, -1, 1) };
        ZoneCell* cell = self.get_zone().get_cell(...(self.get_position() + move));
        if (cell.isPassable())
        {
            return do_move(move);
        }
    case ATTACK:
        log(string::new_format("The %s attacks!", self.get_name()));
    default:
        unreachable();
    }
    
    WaitAction* wait = mem::temp_alloc(WaitAction);
    wait.time = max_time - self.idle_time;
    return wait;
}
