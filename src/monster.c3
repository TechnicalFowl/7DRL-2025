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
    SLIME,
    SKELETON,
    GHOST,
    GOBLIN_HORDE,
    GOBLIN_MAGE_BOSS,
    BANDIT_LEADER,
    NECROMANCER,
}
const int MONSTER_COUNT = (int) MonsterType.elements;

const MonsterType[3] WARRIOR_TYPES = { GOBLIN, BANDIT, DARK_KNIGHT };
const MonsterType[3] ARCHER_TYPES = { GOBLIN_ARCHER, BANDIT_RANGER, ASSASSIN };
const MonsterType[3] MAGE_TYPES = { GOBLIN_MAGE, BANDIT_MAGE, DARK_MAGE };
const MonsterType[3] SPECIAL_TYPES = { SLIME, SKELETON, GHOST };

enum MonsterLevel : inline int
{
    ACCURACY,
    STRENGTH,
    DEFENCE,
}

struct MonsterInfo
{
    MonsterType type;
    String name;
    String description;
    String ext_description;
    Appearance[3] looks;

    double range;
    int max_health;

    CombatStyle style;
    double attack_time;
    int[MonsterLevel.elements] level;
    int[CombatStyle.elements] defence_bonus;

    int[Attunement.elements] attunement_weights;
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
    self.mobs[MonsterType.GOBLIN] = { GOBLIN, "Goblin", "a goblin", "  it is armed with a rough looking spear.", { GOBLIN_IDLE1, GOBLIN_IDLE2, GOBLIN_POINT }, 1.5, 4, MELEE, 1.0, {1, 1, 1}, {0, -10, 10}, { 10, 2, 2, 2, 2, 0, 0, 0} };
    self.mobs[MonsterType.GOBLIN_ARCHER] = { GOBLIN_ARCHER, "Goblin Archer", "a goblin archer", "  it is armed with a shortbow.", { GOBLIN_ARCHER_IDLE1, GOBLIN_ARCHER_IDLE2, GOBLIN_ARCHER_POINT }, 4, 4, RANGED, 1.0, {1, 1, 1}, {-10, 0, 10}, { 10, 2, 2, 2, 2, 0, 0, 0} };
    self.mobs[MonsterType.GOBLIN_MAGE] = { GOBLIN_MAGE, "Hobgoblin Mage", "a hobgoblin mage", "", { GOBLIN_MAGE_IDLE1, GOBLIN_MAGE_IDLE2, GOBLIN_MAGE_POINT }, 5, 3, MAGIC, 1.0, {1, 1, 1}, {10, 0, -10}, { 10, 2, 2, 2, 2, 0, 0, 0} };
    self.mobs[MonsterType.BANDIT] = { BANDIT, "Bandit", "a bandit", "", { BANDIT_IDLE1, BANDIT_IDLE2, BANDIT_POINT }, 1.5, 15, MELEE, 1.0, {30, 30, 30}, {20, -40, 140}, { 10, 4, 4, 4, 4, 1, 1, 1} };
    self.mobs[MonsterType.BANDIT_RANGER] = { BANDIT_RANGER, "Bandit Ranger", "a bandit crossbowman", "", { BANDIT_RANGER_IDLE1, BANDIT_RANGER_IDLE2, BANDIT_RANGER_POINT }, 7, 13, RANGED, 1.0, {30, 30, 30}, {-40, 20, 140}, { 10, 4, 4, 4, 4, 1, 1, 1} };
    self.mobs[MonsterType.BANDIT_MAGE] = { BANDIT_MAGE, "Bandit Mage", "a bandit mage", "", { BANDIT_MAGE_IDLE1, BANDIT_MAGE_IDLE2, BANDIT_MAGE_POINT }, 6, 11, MAGIC, 1.0, {30, 30, 30}, {140, 20, -40}, { 10, 4, 4, 4, 4, 1, 1, 1} };
    self.mobs[MonsterType.DARK_MAGE] = { DARK_MAGE, "Dark Mage", "a dark mage", "", { DARK_MAGE_IDLE1, DARK_MAGE_IDLE2, DARK_MAGE_POINT }, 7, 27, MAGIC, 1.0, {50, 50, 50}, {250, 50, -50}, { 5, 3, 3, 3, 3, 3, 3, 3} };
    self.mobs[MonsterType.DARK_KNIGHT] = { DARK_KNIGHT, "Dark Knight", "a dark knight", "", { DARK_KNIGHT_IDLE1, DARK_KNIGHT_IDLE2, DARK_KNIGHT_POINT }, 1.5, 35, MELEE, 1.0, {50, 50, 50}, {50, -50, 250}, { 5, 3, 3, 3, 3, 3, 3, 3} };
    self.mobs[MonsterType.ASSASSIN] = { ASSASSIN, "Assassin", "an assassin", "", { ASSASSIN_IDLE1, ASSASSIN_IDLE2, ASSASSIN_POINT }, 4, 32, RANGED, 1.0, {50, 50, 50}, {-50, 50, 250}, { 5, 3, 3, 3, 3, 3, 3, 3} };
    self.mobs[MonsterType.SLIME] = { SLIME, "Slime", "a slime", "", { SLIME_IDLE1, SLIME_IDLE2, SLIME_POINT }, 1.5, 5, MELEE, 1.0, {1, 1, 1}, {0, 0, 0}, { 10, 0, 2, 2, 0, 0, 0, 5} };
    self.mobs[MonsterType.SKELETON] = { SKELETON, "Skeleton", "a skeleton", "", { SKELETON_IDLE1, SKELETON_IDLE2, SKELETON_POINT }, 1.5, 10, MELEE, 1.0, {20, 20, 20}, {0, 20, 20}, { 10, 2, 2, 2, 2, 0, 0, 0} };
    self.mobs[MonsterType.GHOST] = { GHOST, "Ghost", "a ghost", "", { GHOST_IDLE1, GHOST_IDLE2, GHOST_POINT }, 1.5, 10, MAGIC, 1.0, {20, 20, 20}, {20, 0, 20}, { 10, 5, 5, 0, 0, 0, 10, 0} };
    self.mobs[MonsterType.GOBLIN_MAGE_BOSS] = { GOBLIN_MAGE_BOSS, "Hobgoblin Mage", "a particularly strong hobgoblin mage", "", { GOBLIN_MAGE_IDLE1, GOBLIN_MAGE_IDLE2, GOBLIN_MAGE_POINT }, 8, 15, MAGIC, 1.0, {40, 40, 40}, {10, 0, -10}, { 0, 0, 0, 0, 0, 1, 0, 0} };
    self.mobs[MonsterType.GOBLIN_HORDE] = { GOBLIN_HORDE, "Goblin Horde", "a goblin", "", { GOBLIN_IDLE1, GOBLIN_IDLE2, GOBLIN_POINT }, 1.5, 7, MELEE, 1.0, {10, 10, 10}, {0, -10, 10}, { 0, 2, 2, 2, 2, 0, 0, 0} };
    self.mobs[MonsterType.BANDIT_LEADER] = { BANDIT_LEADER, "Bandit Leader", "a bandit", "", { BANDIT_MAGE_IDLE1, BANDIT_MAGE_IDLE2, BANDIT_MAGE_POINT }, 7, 25, MAGIC, 1.0, {30, 30, 30}, {20, -40, 140}, { 0, 4, 4, 4, 4, 1, 1, 1} };
    self.mobs[MonsterType.NECROMANCER] = { NECROMANCER, "Necromancer", "a necromancer", "", { DARK_MAGE_IDLE1, DARK_MAGE_IDLE2, DARK_MAGE_POINT }, 7, 40, MAGIC, 1.0, {50, 50, 50}, {250, 50, -50}, { 0, 0, 0, 0, 0, 3, 3, 3} };

    for (int i = 0; i < MONSTER_COUNT; ++i)
    {
        MonsterInfo* info = &self.mobs[i];
        assert(info.type.ordinal == i, "MonsterCache: Monster in %d slot is not correct (expected %s)", i, MonsterType.names[i]);
        self.mob_names.set(info.name, info.type);
    }
}

fn Attunement get_attunement(int[Attunement.elements] weights)
{
    int total_weight = 0;
    for (int i = 0; i < Attunement.elements; ++i)
    {
        total_weight += weights[i];
    }
    int roll = random::next_in_range(&g_rng, 0, total_weight - 1);
    for (int i = 0; i < Attunement.elements; ++i)
    {
        roll -= weights[i];
        if (roll <= 0)
        {
            return Attunement.from_ordinal(i);
        }
    }
    return NONE;
}

fn Monster* spawn_monster(Zone* zone, IVec2 pos, MonsterType type)
{
    Monster* mob = mem::new(Monster);
    mob.new_init(zone, type, pos);
    zone.add_entity(mob);
    mob.attunement = get_attunement(mob.info.attunement_weights);
    return mob;
}

struct Monster (Entity)
{
    inline EntityCommon entity;

    MonsterType type;
    MonsterInfo* info;

    int health;
    int[MonsterLevel.elements] boosted_level;

    Attunement attunement;
    
    List(<StatusEffectApplication>) status_effects;
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
fn void Monster.updateLookFrame(&self, bool was_interact) @dynamic => self.entity.updateLookFrame(was_interact);

fn void Monster.new_init(&self, Zone* z, MonsterType t, IVec2 p)
{
    self.type = t;
    self.info = &g_mobs.mobs[t.ordinal];
    self.entity.new_init(z, self.info.name, p, ...self.info.looks);
    self.health = self.info.max_health;
    self.status_effects.new_init();
}

fn void Monster.free(&self) @dynamic
{
    self.entity.free();
    self.status_effects.free();
}

fn void Monster.take_damage(&self, int dmg)
{
    self.health -= dmg;
}

fn void Monster.onUpdate(&self, double duration) @dynamic
{
    for (int i = (int) self.status_effects.len() - 1; i >= 0; --i)
    {
        self.status_effects[i].duration -= duration;
        if (self.status_effects[i].duration <= 0)
        {
            self.status_effects.remove_at(i);
        }
    }
}

fn void Monster.updateBoostedStats(&self)
{
    for (int i = 0; i < MonsterLevel.elements; ++i)
    {
        if (self.boosted_level[i] < self.info.level[i])
        {
            self.boosted_level[i]++;
        }
        else if (self.boosted_level[i] > self.info.level[i])
        {
            self.boosted_level[i]--;
        }
    }
}

fn void Monster.apply_effect(&self, StatusEffect effect, double duration)
{
    foreach (&e: self.status_effects)
    {
        if (e.effect == effect)
        {
            e.duration = math::max(e.duration, duration);
            return;
        }
    }
    self.status_effects.push({effect, duration});
}

fn bool Monster.has_effect(&self, StatusEffect effect)
{
    foreach (&e: self.status_effects)
    {
        if (e.effect == effect) return true;
    }
    return false;
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
    ZoneCell*! cell = g_zone.get_cell(...next);
    if (cell.isTerrainPassable() ?? true)
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

    if ((behave == CHASE || behave == WANDER) && self.has_effect(ROOTED))
    {
        behave = IDLE;
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
            self.get_zone().path(self.get_position(), player_pos, &path, diagonal_moves: true, reverse: true);
            if (path.is_empty())
            {
                break;
            }
            IVec2 next_pos = path.pop()!!;
            IVec2 next_move = next_pos - self.entity.position;
            ZoneCell*! next_cell = self.get_zone().get_cell(...next_pos);
            if (try next_cell && next_cell.isPassable())
            {
                return do_move(next_move);
            }
        }
    case WANDER:
        if (max_time > 1)
        {
            IVec2 move = { random::next_in_range(&g_rng, -1, 1), random::next_in_range(&g_rng, -1, 1) };
            ZoneCell*! cell = self.get_zone().get_cell(...(self.get_position() + move));
            if (try cell && cell.isPassable())
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
    entity.updateLookFrame(true);
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
            mob.applyAttunement(player, &damage);
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
                if (!player.nav.is_idle())
                {
                    player.nav.abort();
                }
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
    int str = self.boosted_level[MonsterLevel.STRENGTH] + 9;
    int max_hit = (str * 64 + 320) / 640;
    int atk = self.boosted_level[MonsterLevel.ACCURACY] + 9;
    int attack_roll = atk * 64;
    int[3] target_stats = target.get_style_stats(style);
    int defence_roll = (target.boosted_level[Skill.DEFENCE] + 9) * (target_stats[2] + 64);
    float hit_chance;
    if (attack_roll > defence_roll)
    {
        hit_chance = 1.0f - (defence_roll + 2.0f) / (2.0f * (attack_roll + 1.0f));
    }
    else
    {
        hit_chance = attack_roll / (2.0f * (defence_roll + 1.0f));
    }

    // Attack range accuracy falloff
    //float range = (float) (ivec2_fdistance(self.get_position(), target.get_position()) / self.info.range);
    //hit_chance *= math::clamp(1.0f - (range / 2) * (range / 2), 0.1f, 1.0f);

    bool hit = random::next_float(&g_rng) < hit_chance;
    io::printfn("Monster attack: max_hit %d, atk %d, attack_roll %d, defence_roll %d, hit_chance %.01f%%, hit %s", max_hit, atk, attack_roll, defence_roll, hit_chance * 100, hit ? "yes" : "no");
    if (!hit) return 0;
    int damage = random::next_in_range(&g_rng, 1, max_hit);
    return damage;
}

fn void Monster.applyAttunement(&self, Player* target, int* damage)
{
    switch (self.attunement)
    {
    case AIR:
        // Apply bonus accuracy
        if (*damage == 0)
        {
            // reroll damage
            *damage = self.calculate_damage(target, self.info.style);
        }
    case WATER:
        // Apply stat drain
        if (*damage > 0)
        {
            Skill skill = Skill.from_ordinal(random::next_in_range(&g_rng, 0, 3));
            target.boosted_level[skill] = math::max(math::max(1, target.level[skill] - 10), target.boosted_level[skill] - *damage);
        }
    case EARTH:
        // Apply knockback
        if (*damage > 0)
        {
            IVec2 knockback = ivec2_sign(target.get_position() - self.get_position());
            ZoneCell*! cell = target.get_zone().get_cell(...(target.get_position() + knockback));
            if (try cell && cell.isPassable())
            {
                target.set_position(target.get_position() + knockback);
            }
        }
    case FIRE:
        // Apply extra damage
        if (*damage > 0)
        {
            *damage += math::max(1, *damage / 2);
        }
    case CHAOS:
        // Apply a random attunement...
        if (*damage > 0)
        {
            self.attunement = Attunement.from_ordinal(random::next_in_range(&g_rng, 1, Attunement.elements - 1));
            self.applyAttunement(target, damage);
            self.attunement = CHAOS;
        }
    case NATURE:
        // Apply rooted
        if (*damage > 0)
        {
            target.apply_effect(ROOTED, 10);
        }
    case BLOOD:
        // Apply life steal
        if (*damage > 0)
        {
            self.health = math::min(self.health + math::max(1, *damage / 4), self.info.max_health);
        }
    case NONE:
        break;
    }
}