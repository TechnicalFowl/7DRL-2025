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
    int max_health;

    CombatStyle style;
    double attack_time;
    int attack;
    int strength;
    int defence;
    int[3] defence_bonus;
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
    self.mobs[MonsterType.GOBLIN] = { GOBLIN, "Goblin", { GOBLIN_IDLE1, GOBLIN_IDLE2, GOBLIN_POINT }, 1.5, 4, MELEE, 1.0, 1, 1, 1, {0, -10, 10} };
    self.mobs[MonsterType.GOBLIN_ARCHER] = { GOBLIN_ARCHER, "Goblin Archer", { GOBLIN_ARCHER_IDLE1, GOBLIN_ARCHER_IDLE2, GOBLIN_ARCHER_POINT }, 4, 4, RANGED, 1.0, 1, 1, 1, {-10, 0, 10} };
    self.mobs[MonsterType.GOBLIN_MAGE] = { GOBLIN_MAGE, "Goblin Mage", { GOBLIN_MAGE_IDLE1, GOBLIN_MAGE_IDLE2, GOBLIN_MAGE_POINT }, 5, 3, MAGIC, 1.0, 1, 1, 1, {10, 0, -10} };
    self.mobs[MonsterType.BANDIT] = { BANDIT, "Bandit", { BANDIT_IDLE1, BANDIT_IDLE2, BANDIT_POINT }, 1.5, 15, MELEE, 1.0, 30, 30, 30, {20, -40, 140} };
    self.mobs[MonsterType.BANDIT_RANGER] = { BANDIT_RANGER, "Bandit Ranger", { BANDIT_RANGER_IDLE1, BANDIT_RANGER_IDLE2, BANDIT_RANGER_POINT }, 7, 13, RANGED, 1.0, 30, 30, 30, {-40, 20, 140} };
    self.mobs[MonsterType.BANDIT_MAGE] = { BANDIT_MAGE, "Bandit Mage", { BANDIT_MAGE_IDLE1, BANDIT_MAGE_IDLE2, BANDIT_MAGE_POINT }, 6, 11, MAGIC, 1.0, 30, 30, 30, {140, 20, -40} };
    self.mobs[MonsterType.DARK_MAGE] = { DARK_MAGE, "Dark Mage", { DARK_MAGE_IDLE1, DARK_MAGE_IDLE2, DARK_MAGE_POINT }, 7, 27, MAGIC, 1.0, 50, 50, 50, {250, 50, -50} };
    self.mobs[MonsterType.DARK_KNIGHT] = { DARK_KNIGHT, "Dark Knight", { DARK_KNIGHT_IDLE1, DARK_KNIGHT_IDLE2, DARK_KNIGHT_POINT }, 1.5, 35, MELEE, 1.0, 50, 50, 50, {50, -50, 250} };
    self.mobs[MonsterType.ASSASSIN] = { ASSASSIN, "Assassin", { ASSASSIN_IDLE1, ASSASSIN_IDLE2, ASSASSIN_POINT }, 4, 32, RANGED, 1.0, 50, 50, 50, {-50, 50, 250} };
    
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

    int health;
}

// @Todo: There should be an easy way to avoid this boilerplate?...
fn Zone* Monster.get_zone(&self) @dynamic => self.entity.get_zone();
fn String Monster.get_name(&self) @dynamic => self.entity.get_name();
fn IVec2 Monster.get_position(&self) @dynamic => self.entity.get_position();
fn void Monster.set_position(&self, IVec2 pos) @dynamic => self.entity.set_position(pos);
fn Appearance Monster.get_look(&self) @dynamic => self.entity.get_look();
fn double Monster.get_idle_time(&self) @dynamic => self.entity.get_idle_time();
fn void Monster.give_idle_time(&self, double time) @dynamic => self.entity.give_idle_time(time);
fn bool Monster.is_dead(&self) @dynamic => self.health <= 0;

fn void Monster.new_init(&self, Zone* z, MonsterType t, IVec2 p)
{
    self.type = t;
    self.info = &g_mobs.mobs[t.ordinal];
    self.entity.new_init(z, self.info.name, p, ...self.info.looks);
    self.health = self.info.max_health;
}

fn void Monster.free(&self) @dynamic
{
    self.entity.free();
}

fn void Monster.take_damage(&self, int dmg)
{
    self.health -= dmg;
}

enum Behavior
{
    IDLE,
    WANDER,
    CHASE,
    ATTACK,
}

struct MonsterLosChecker
{
    Monster* mob;
    IVec2 player_pos;
    bool can_see;
}
fn bool MonsterLosChecker.lineCB(&self, IVec2 next)
{
    ZoneCell* cell = g_zone.get_cell(...next);
    if (cell.isTerrainPassable())
    {
        return true;
    }
    else
    {
        self.can_see = false;
        return false;
    }
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
            MonsterLosChecker checker = { self, player_pos, true };
            line(self.get_position(), player_pos, (LineCallback) &MonsterLosChecker.lineCB, &checker);
            if (checker.can_see)
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
        if (max_time > 1)
        {
            List(<IVec2>) path;
            path.temp_init();
            //self.get_zone().path(self.get_position(), player_pos, &path, diagonal_moves: true, reverse: true);
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
        }
    case WANDER:
        if (max_time > 1)
        {
            IVec2 move = { random::next_in_range(&g_rng, -1, 1), random::next_in_range(&g_rng, -1, 1) };
            ZoneCell* cell = self.get_zone().get_cell(...(self.get_position() + move));
            if (cell.isPassable())
            {
                return do_move(move);
            }
        }
    case ATTACK:
        //log(string::new_format("The %s attacks!", self.get_name()));
        if (max_time > self.info.attack_time)
        {
            return do_mob_attack(self.info.attack_time);
        }
        break;
    default:
        unreachable();
    }
    
    return do_wait(max_time - self.idle_time);
}

fn MobAttackAction* do_mob_attack(double time)
{
    MobAttackAction* attack = mem::temp_alloc(MobAttackAction);
    attack.time = time;
    return attack;
}

struct MobAttackAction (Action)
{
    double time;
}
fn double MobAttackAction.duration(&self) @dynamic => self.time;

fn void MobAttackAction.apply(&self, Entity entity) @dynamic
{
    Monster* mob = (Monster*) entity;
    Player* player = (Player*) mob.get_zone().player;
    IVec2 player_pos = player.get_position();
    IVec2 player_room = { player_pos.x / 17, player_pos.y / 17 };
    IVec2 mob_room = { mob.get_position().x / 17, mob.get_position().y / 17 };

    if (player_room == mob_room)
    {
        double dist = ivec2_fdistance(player_pos, mob.get_position());
        if (dist <= mob.info.range)
        {
            int damage = mob.calculate_damage(player, mob.info.style);
            if (damage > 0)
            {
                DString ending;
                ending.temp_init();
                if (damage < 5) ending.append_char('.');
                for (int i = 0; i < damage/5; ++i)
                {
                    ending.append_char('!');
                }
                log(string::new_format("The %s hits you%s", mob.get_name(), ending), colors::RED);
                player.health -= damage;
                player.give_exp(DEFENCE, damage * 20);
                player.give_exp(HITPOINTS, damage * 10);
            }
            else
            {
                log(string::new_format("The %s misses you.", mob.get_name()), colors::LIGHT_RED);
            }
        }
    }
}

fn int Monster.calculate_damage(&self, Player* target, CombatStyle style)
{
    int str = self.info.strength + 9;
    int max_hit = (str * 64 + 320) / 640;
    int atk = self.info.attack + 9;
    int attack_roll = atk * 64;
    int[3] target_stats = target.get_style_stats(style);
    int defence_roll = (target.level[Skill.DEFENCE] + 9) * (target_stats[2] + 64);
    float hit_chance;
    if (attack_roll > defence_roll)
    {
        hit_chance = 1.0f - (defence_roll + 2.0f) / (2.0f * (attack_roll + 1.0f));
    }
    else
    {
        hit_chance = attack_roll / (2.0f * (defence_roll + 1.0f));
    }

    float range = (float) (ivec2_fdistance(self.get_position(), target.get_position()) / self.info.range);
    hit_chance *= math::clamp(1.0f - range / 2, 0.1f, 1.0f);

    bool hit = random::next_float(&g_rng) < hit_chance;
    io::printfn("Monster attack: max_hit %d, atk %d, attack_roll %d, defence_roll %d, hit_chance %.01f%%, hit %s", max_hit, atk, attack_roll, defence_roll, hit_chance * 100, hit ? "yes" : "no");
    if (!hit) return 0;
    int damage = random::next_in_range(&g_rng, 1, max_hit);
    return damage;
}