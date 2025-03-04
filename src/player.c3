module dg;

import std::io;
import std::math;
import raylib5::rl;

const INVENTORY_SIZE = 26;

enum Attunement : (rl::Color color)
{
    NONE = colors::WHITE,
    AIR = colors::SILVER,
    WATER = colors::SKY_BLUE,
    EARTH = colors::BROWN,
    FIRE = colors::RED,
    CHAOS = colors::YELLOW,
    NATURE = colors::DARK_GREEN,
    BLOOD = colors::DARK_RED,
}

struct Player (Entity)
{
    inline EntityCommon entity;
    uint flags;

    Navigator nav;
    float nav_delay;

    VisibilityTracker vis;

    int health;

    ItemStack[INVENTORY_SIZE] inventory;
    ItemStack[EquipmentSlot.elements] equipment;

    int[Skill.elements] boosted_level;
    int[Skill.elements] level;
    int[Skill.elements] experience;

    Attunement attunement;
}

// @Todo: There should be an easy way to avoid this boilerplate?...
fn Zone* Player.get_zone(&self) @dynamic => self.entity.get_zone();
fn String Player.get_name(&self) @dynamic => self.entity.get_name();
fn IVec2 Player.get_position(&self) @dynamic => self.entity.get_position();
fn void Player.set_position(&self, IVec2 pos) @dynamic
{
    self.entity.set_position(pos);
    self.vis.sweep(pos, 16);
}
fn Appearance Player.get_look(&self) @dynamic => self.entity.get_look();
fn double Player.get_idle_time(&self) @dynamic => self.entity.get_idle_time();
fn void Player.give_idle_time(&self, double time) @dynamic => self.entity.give_idle_time(time);
fn bool Player.is_dead(&self) @dynamic => self.health <= 0;

// Implement EntityVisibility
fn VisibilityTracker* Player.get_visibility(&self) @dynamic => &self.vis;
fn void Player.on_post_load(&self) @dynamic => self.vis.sweep(self.get_position(), 16);

fn void Player.explore(&self, IVec2 pos, IVec2 size)
{
    for (int y = pos.y; y < pos.y + size.y; ++y)
    {
        for (int x = pos.x; x < pos.x + size.x; ++x)
        {
            self.vis.explored.set({x, y}, true);
        }
    }
}

fn void Player.new_init(&self, Zone* z, String n, IVec2 p)
{
    self.entity.new_init(z, n, p, WARRIOR_IDLE1, WARRIOR_IDLE2, WARRIOR_POINT);
    self.nav.new_init();
    self.nav_delay = 0.1f;

    self.vis.new_init(z);

    for (int i = 0; i < Skill.elements; ++i)
    {
        self.level[i] = 1;
        self.boosted_level[i] = 1;
    }
    self.give_exp(HITPOINTS, EXPERIENCE_TABLE[10], supress_message: true);
    self.health = self.level[Skill.HITPOINTS];
}

fn void Player.free(&self) @dynamic
{
    self.entity.free();
    self.nav.free();
    self.vis.free();
}

fn bool Player.is_inventory_full(&self, ItemStack item)
{
    ItemInfo* info = &g_items.items[item.item];
    foreach (&slot: self.inventory)
    {
        if (slot.item == NO_ITEM) return false;
        if (slot.item == item.item)
        {
            if (slot.count + item.count <= info.stack_size) return false;
            item.count -= info.stack_size - slot.count;
        }
    }
    return true;
}

fn bool Player.remove_item(&self, ItemStack item)
{
    assert(item.item != NO_ITEM);
    if (!self.has_item(item.item, item.count)) return false;
    ItemInfo* info = &g_items.items[item.item];
    bool done = false;
    for (int i = 0; i < self.inventory.len; ++i)
    {
        ItemStack* slot = &self.inventory[i];
        if (slot.item == item.item)
        {
            if (slot.count >= item.count)
            {
                slot.count -= item.count;
                if (slot.count == 0)
                {
                    slot.item = NO_ITEM;
                }
                done = true;
                break;
            }
            item.count -= slot.count;
            slot.count = 0;
            slot.item = NO_ITEM;
        }
    }

    if (item.item >= AIR_RUNE && item.item <= BLOOD_RUNE)
    {
        if (!self.has_item(item.item, 1) && self.attunement == Attunement.from_ordinal(item.item - BLANK_RUNE))
        {
            log(string::new_format("You ran out of %s and lose your attunement!", g_items.items[item.item].name));
            self.attunement = NONE;
        }
    }

    assert(done);
    return true;
}

fn ItemStack Player.add_item(&self, ItemStack item)
{
    assert(item.item != NO_ITEM);
    ItemInfo* info = &g_items.items[item.item];
    int empty_slot = -1;
    for (int i = 0; i < self.inventory.len; ++i)
    {
        ItemStack* slot = &self.inventory[i];
        if (slot.item == NO_ITEM)
        {
            if (empty_slot == -1) empty_slot = i;
        }
        else if (slot.item == item.item)
        {
            if (slot.count + item.count <= info.stack_size)
            {
                slot.count += item.count;
                return {NO_ITEM, 0, 0};
            }
            item.count -= info.stack_size - slot.count;
            slot.count = info.stack_size;
        }
    }
    assert(item.count > 0);
    if (empty_slot != -1)
    {
        self.inventory[empty_slot] = item;
        return {NO_ITEM, 0, 0};
    }
    return item;
}

fn ItemStack Player.equip(&self, ItemStack item)
{
    assert(item.item != NO_ITEM);
    ItemInfo* info = &g_items.items[item.item];
    assert(info.stats, "Item is not equippable");
    ItemStack old_item = self.equipment[info.stats.slot];
    self.equipment[info.stats.slot] = item;
    return old_item;
}

fn bool Player.has_item(&self, Item item, int count=1)
{
    foreach (&slot: self.inventory)
    {
        if (slot.item == item)
        {
            count -= slot.count;
            if (count <= 0) return true;
        }
    }
    return false;
}

fn void Player.use_item_pair(&self, int first, int second)
{
    ItemStack item1 = self.inventory[first];
    ItemStack item2 = self.inventory[second];
    if (item1.item == NO_ITEM || item2.item == NO_ITEM)
    {
        log("Nothing interesting happens.");
        return;
    }
    if (item1.item > item2.item)
    {
        ItemStack temp = item1;
        item1 = item2;
        item2 = temp;
    }

    
    log("Nothing interesting happens.");
}

fn void Player.quaff(&self, ItemStack stack)
{
    switch (stack.item)
    {
    case FOOD:
        self.health = math::min(self.health + 5, self.level[Skill.HITPOINTS]);
        log("You eat the food.");
    case POTION1:
        self.health = math::min(self.health + 10, self.level[Skill.HITPOINTS]);
        log("You drink the potion, it heals some health.");
    case POTION2:
        self.boosted_level[Skill.MELEE] = self.level[Skill.MELEE] + 10;
        self.boosted_level[Skill.RANGED] = self.level[Skill.RANGED] + 10;
        self.boosted_level[Skill.MAGIC] = self.level[Skill.MAGIC] + 10;
        log("You drink the potion, you feel stronger.");
    case POTION3:
        self.boosted_level[Skill.DEFENCE] = self.level[Skill.DEFENCE] + 10;
        log("You drink the potion, you feel safer.");
    default:
        log(string::new_format("You quaff the %s, it tastes awful.", g_items.items[stack.item].name));
    }
}

fn void Player.give_exp(&self, Skill skill, int exp, bool supress_message=false)
{
    self.experience[skill] += exp;
    int prev_level = self.level[skill];
    self.level[skill] = get_level(self.experience[skill]);
    if (prev_level != self.level[skill])
    {
        if (!supress_message) log(string::new_format("You have reached level %d in %s.", self.level[skill], skill));
        if (skill == HITPOINTS)
        {
            self.health += (self.level[skill] - prev_level);
        }
        if (self.boosted_level[skill] == prev_level)
        {
            self.boosted_level[skill] = self.level[skill];
        }
    }
}

fn void Player.updateBoostedStats(&self)
{
    for (int i = 0; i < Skill.elements; ++i)
    {
        if (self.boosted_level[i] < self.level[i])
        {
            self.boosted_level[i]++;
        }
        else if (self.boosted_level[i] > self.level[i])
        {
            self.boosted_level[i]--;
        }
    }
}

fn Action Player.moveOrInteract(&self, IVec2 dir)
{
    ZoneCell* cell = self.get_zone().get_cell(...(self.get_position() + dir));
    if (cell.isPassable())
    {
        return do_move(dir);
    }
    else
    {
        return do_interact(dir);
    }
}

fn Action Player.tryInteract(&self, IVec2 dir)
{
    ZoneCell* cell = self.get_zone().get_cell(...(self.get_position() + dir));
    if (cell.isPassable())
    {
        inv_action = NO_ACTION;
        return null;
    }
    else
    {
        return do_interact(dir);
    }
}

fn IVec2 Player.get_room(&self)
{
    return self.get_position() / 17;
}

fn CombatStyle Player.getAttackStyle(&self)
{
    return getStyle(self.equipment[EquipmentSlot.WEAPON].item);
}

fn double Player.getAttackRange(&self)
{
    Item item = self.equipment[EquipmentSlot.WEAPON].item;
    if (item == NO_ITEM) return 1.5;
    ItemInfo* info = &g_items.items[item];
    return info.stats.range;
}

fn Action Player.next_action(&self, double max_time) @dynamic
{
    if (devmode && !gui::want_key_input())
    {
        if (is_key_pressed(REVEAL_MAP, false))
        {
            self.vis.explored.clear_to(true);
        }
    }

    if (self.nav.is_idle())
    {
        if (!ui_wants_keys())
        {
            if (devmode)
            {
                if (is_key_down(PATH_TO_BOSS))
                {
                    for (int y= 0; y < FLOOR_SIZE && self.nav.is_idle(); ++y)
                    {
                        for (int x = 0; x < FLOOR_SIZE && self.nav.is_idle(); ++x)
                        {
                            Room* r = current_floor.rooms.get({x, y})!!;
                            if (r.type == BOSS)
                            {
                                IVec2 pos = {x * 17 + 8, y * 17 + 8};
                                self.nav.path_to(self.get_zone(), self.get_position(), pos);
                            }
                        }
                    }
                }
            }

            if (is_key_pressed(WAIT) || (g_settings.scroll_to_wait && math::abs(rl::getMouseWheelMove()) > 0.01))
            {
                return do_wait(1.0);
            }
            
            if (rl::isMouseButtonPressed(rl::MouseButton.LEFT) && !gui::want_mouse_input())
            {
                IVec2 pos = math::clamp(self.get_zone().get_mouse_position(), IVec2 {0, 0}, IVec2 {self.get_zone().width - 1, self.get_zone().height - 1});
                if (pos == self.get_position())
                {
                    return do_grab();
                }
                ZoneCell* cell = self.get_zone().get_cell(...pos);
                if (!cell.entities.is_empty()
                        && self.get_room() == pos / 17
                        && self.getAttackStyle() != MELEE
                        && ivec2_distance(self.get_position(), pos) <= self.getAttackRange())
                {
                    return do_ranged_attack(1.0, pos);
                }
                else
                {
                    self.nav.path_to(self.get_zone(), self.get_position(), pos);
                }
            }

            bool is_shift = is_key_down(DIAGONAL_UP);
            bool is_ctrl = is_key_down(DIAGONAL_DOWN);
            if (is_key_pressed(MOVE_UP))
            {
                return self.moveOrInteract({0, -1});
            }
            if (is_key_pressed(MOVE_DOWN))
            {
                return self.moveOrInteract({0, 1});
            }
            if (is_key_pressed(MOVE_LEFT))
            {
                if (is_shift)
                {
                    return self.moveOrInteract({-1, -1});
                }
                else if (is_ctrl)
                {
                    return self.moveOrInteract({-1, 1});
                }
                else
                {
                    return self.moveOrInteract({-1, 0});
                }
            }
            if (is_key_pressed(MOVE_RIGHT))
            {
                if (is_shift)
                {
                    return self.moveOrInteract({1, -1});
                }
                else if (is_ctrl)
                {
                    return self.moveOrInteract({1, 1});
                }
                else
                {
                    return self.moveOrInteract({1, 0});
                }
            }
            if (is_key_pressed(MOVE_UP_RIGHT))
            {
                return self.moveOrInteract({1, -1});
            }
            if (is_key_pressed(MOVE_DOWN_RIGHT))
            {
                return self.moveOrInteract({1, 1});
            }
            if (is_key_pressed(MOVE_DOWN_LEFT))
            {
                return self.moveOrInteract({-1, 1});
            }
            if (is_key_pressed(MOVE_UP_LEFT))
            {
                return self.moveOrInteract({-1, -1});
            }
            if (is_key_pressed(GRAB))
            {
                return do_grab();
            }
        }
        else if (inv_action == ACT_USE_ON)
        {
            bool is_shift = is_key_down(DIAGONAL_UP);
            bool is_ctrl = is_key_down(DIAGONAL_DOWN);
            if (is_key_pressed(MOVE_UP))
            {
                return self.tryInteract({0, -1});
            }
            if (is_key_pressed(MOVE_DOWN))
            {
                return self.tryInteract({0, 1});
            }
            if (is_key_pressed(MOVE_LEFT))
            {
                if (is_shift)
                {
                    return self.tryInteract({-1, -1});
                }
                else if (is_ctrl)
                {
                    return self.tryInteract({-1, 1});
                }
                else
                {
                    return self.tryInteract({-1, 0});
                }
            }
            if (is_key_pressed(MOVE_RIGHT))
            {
                if (is_shift)
                {
                    return self.tryInteract({1, -1});
                }
                else if (is_ctrl)
                {
                    return self.tryInteract({1, 1});
                }
                else
                {
                    return self.tryInteract({1, 0});
                }
            }
            if (is_key_pressed(MOVE_UP_RIGHT))
            {
                return self.tryInteract({1, -1});
            }
            if (is_key_pressed(MOVE_DOWN_RIGHT))
            {
                return self.tryInteract({1, 1});
            }
            if (is_key_pressed(MOVE_DOWN_LEFT))
            {
                return self.tryInteract({-1, 1});
            }
            if (is_key_pressed(MOVE_UP_LEFT))
            {
                return self.tryInteract({-1, -1});
            }
        }
        else if (inv_action == ACT_AIM)
        {
            if (rl::isMouseButtonPressed(rl::MouseButton.LEFT) && !gui::want_mouse_input())
            {
                inv_action = NO_ACTION;
                return do_ranged_attack(1.0, inv_action_target);
            }
            if (is_key_pressed(ZAP, false, true))
            {
                inv_action = NO_ACTION;
                return do_ranged_attack(1.0, inv_action_target);
            }
        }
    }
    else
    {
        if (rl::isMouseButtonPressed(rl::MouseButton.LEFT) && !gui::want_mouse_input())
        {
            self.nav.abort();
        }
        else
        {
            self.nav_delay -= rl::getFrameTime();
            if (self.nav_delay <= 0)
            {
                self.nav_delay = 0.1f;
                IVec2 next_pos = self.nav.next_point();
                IVec2 next_move = next_pos - self.entity.position;
                ZoneCell* next_cell = self.get_zone().get_cell(...next_pos);
                if (next_move == {0, 0})
                {
                    return null;
                }
                else if (next_cell.isPassable())
                {
                    return do_move(next_move);
                }
                else if (is_door_terrain(next_cell.terrain))
                {
                    if (is_locked_door_terrain(next_cell.terrain))
                    {
                        if (self.remove_item({KEY, 1, 0}))
                        {
                            log("You unlock the door.");
                            open_door(self.get_zone(), next_pos);
                        }
                        else
                        {
                            log("The door is locked.");
                            self.nav.abort();
                            return null;
                        }
                    }
                    return do_interact(next_move);
                }
                else
                {
                    self.nav.abort();
                    return do_interact(next_move);
                }
            }
        }
    }
    return null;
}

struct InteractAction (Action)
{
    IVec2 dir;
}
fn double InteractAction.duration(&self) @dynamic => 1.0;

fn void InteractAction.apply(&self, Entity entity) @dynamic
{
    IVec2 new_pos = entity.get_position() + self.dir;
    Player* player = (Player*) entity;
    Zone* zone = entity.get_zone();
    ZoneCell* cell = zone.get_cell(...new_pos);
    if (inv_action == ACT_USE_ON)
    {
        inv_action = NO_ACTION;
        ItemStack item = player.inventory[inv_action_source];
        if (cell.object == OBJ_FURNACE)
        {
            if (item.item == ORE1 || item.item == ORE2 || item.item == ORE3)
            {
                int ore_tier = (item.item - Item.ORE1);
                ItemStack result = { Item.INGOT1 + ore_tier, 1, 0 };
                if (player.is_inventory_full(result))
                {
                    log("Your inventory is full.");
                }
                else
                {
                    player.add_item(result);
                    player.inventory[inv_action_source].count -= 1;
                    if (player.inventory[inv_action_source].count == 0)
                    {
                        player.inventory[inv_action_source] = { NO_ITEM, 0, 0 };
                    }
                    log("You smelt the ore into an ingot.");
                    player.give_exp(SMITHING, 175 * (1 << ore_tier));
                }
                return;
            }
            else if (item.item == LOGS)
            {
                log("You burn the logs in the furnace.");
                player.inventory[inv_action_source].count -= 1;
                if (player.inventory[inv_action_source].count == 0)
                {
                    player.inventory[inv_action_source] = { NO_ITEM, 0, 0 };
                }
            }
        }
        else if (cell.object == OBJ_ORE_ROCK1 || cell.object == OBJ_ORE_ROCK2 || cell.object == OBJ_ORE_ROCK3)
        {
            if (item.item != PICKAXE)
            {
                log("You need a pickaxe to mine ore.");
                return;
            }
            int ore_tier = (cell.object - OBJ_ORE_ROCK1);
            ItemStack result_item = { Item.ORE1 + ore_tier, 1, 0 };
            if (player.is_inventory_full(result_item))
            {
                log("Your inventory is full.");
            }
            else
            {
                player.add_item(result_item);
                cell.object = OBJ_ROCKS;
                log("You mine the ore.");
                player.give_exp(MINING, 400 * (1 << ore_tier));
            }
            return;
        }
        else if (cell.object == OBJ_TREE)
        {
            if (item.item != AXE)
            {
                log("You need an axe to chop down trees.");
                return;
            }
            ItemStack result_item = { LOGS, 1, 0 };
            if (player.is_inventory_full(result_item))
            {
                log("Your inventory is full.");
            }
            else
            {
                player.add_item(result_item);
                cell.object = OBJ_STUMP;
                log("You chop down the tree.");
                player.give_exp(WOODCUTTING, 250);
            }
            return;
        }
        else if (cell.object == OBJ_STUMP)
        {
            if (item.item == AXE)
            {
                log("You can't get any more wood from this stump.");
                return;
            }
        }
        else if (cell.object == OBJ_ROCKS)
        {
            if (item.item == PICKAXE)
            {
                log("You can't get any useful ore from these rocks.");
                cell.object = OBJ_SMALL_ROCKS;
                return;
            }
        }
        else if (is_wall_terrain(cell.terrain))
        {
            if (item.item == PICKAXE)
            {
                log("The bricks are too hard to break.");
                return;
            }
        }
        log("Nothing interesting happens.");
    }
    else if (is_door_terrain(cell.terrain))
    {
        if (is_locked_door_terrain(cell.terrain))
        {
            log("The door is locked.");
        }
        else
        {
            Room* r = find_room(new_pos)!!;
            Direction dir = get_door_direction(new_pos);
            Door* d = &r.doors[dir.ordinal - 1];
            switch (dir)
            {
            case NORTH:
                IVec2 end_pos = entity.get_position() + IVec2{0, -4};
                if (self.dir.x != 0) end_pos.x += self.dir.x;
                entity.set_position(end_pos);
            case EAST:
                IVec2 end_pos = entity.get_position() + IVec2{4, 0};
                if (self.dir.y != 0) end_pos.y += self.dir.y;
                entity.set_position(end_pos);
            case SOUTH:
                IVec2 end_pos = entity.get_position() + IVec2{0, 4};
                if (self.dir.x != 0) end_pos.x += self.dir.x;
                entity.set_position(end_pos);
            case WEST:
                IVec2 end_pos = entity.get_position() + IVec2{-4, 0};
                if (self.dir.y != 0) end_pos.y += self.dir.y;
                entity.set_position(end_pos);
            default:
                unreachable();
            }
            log("You go through the door.");
            open_door(zone, new_pos);
            Room* next_room = find_room(entity.get_position())!!;
            player.explore(next_room.position, next_room.size);
        }
    }
    else if (is_exit_terrain(cell.terrain))
    {
        want_exit_floor = true;
    }
    else if (cell.object == OBJ_ORE_ROCK1 || cell.object == OBJ_ORE_ROCK2 || cell.object == OBJ_ORE_ROCK3)
    {
        if (!player.has_item(PICKAXE))
        {
            log("You need a pickaxe to mine ore.");
            return;
        }
        int ore_tier = (cell.object - OBJ_ORE_ROCK1);
        ItemStack item = { Item.ORE1 + ore_tier, 1, 0 };
        if (player.is_inventory_full(item))
        {
            log("Your inventory is full.");
        }
        else
        {
            player.add_item(item);
            cell.object = OBJ_ROCKS;
            log("You mine the ore.");
            player.give_exp(MINING, 400 * (1 << ore_tier));
        }
    }
    else if (cell.object == OBJ_ANVIL)
    {
        gui::open_popup("Smith Item");
    }
    else if (cell.object == OBJ_TREE)
    {
        if (!player.has_item(AXE))
        {
            log("You need an axe to chop down trees.");
            return;
        }
        ItemStack item = { LOGS, 1, 0 };
        if (player.is_inventory_full(item))
        {
            log("Your inventory is full.");
        }
        else
        {
            player.add_item(item);
            cell.object = OBJ_STUMP;
            log("You chop down the tree.");
            player.give_exp(WOODCUTTING, 250);
        }
    }
    else if (cell.object == OBJ_CRATE)
    {
        gui::open_popup("Search Crate");
        cell.object = OBJ_OPEN_CRATE;
        log("You search the crate.");

        int count = random::next_in_range(&g_rng, 1, 4);
        DropTable* table = &crate_loot[current_floor.depth];
        
        for (int i = 0; i < count; ++i)
        {
            ItemStack item = table.roll(&g_rng);
            storage_contents.push(item);
        }
    }
    else if (cell.object == OBJ_OPEN_CRATE)
    {
        log("The crate is empty.");
    }
    else if (cell.object == OBJ_STUMP)
    {
        log("The remains of a tree.");
    }
    else if (cell.object == OBJ_ROCKS)
    {
        log("There is no ore available in this rock.");
    }
    else if (cell.object == OBJ_FURNACE)
    {
        bool done = false;
        for (int i = 0; i < INVENTORY_SIZE; ++i)
        {
            ItemStack* item = &player.inventory[i];
            if (item.item == ORE1 || item.item == ORE2 || item.item == ORE3)
            {
                int ore_tier = (item.item - Item.ORE1);
                ItemStack result = { Item.INGOT1 + ore_tier, 1, 0 };
                if (player.is_inventory_full(result))
                {
                    log("Your inventory is full.");
                }
                else
                {
                    player.add_item(result);
                    item.count -= 1;
                    if (item.count == 0)
                    {
                        item.item = NO_ITEM;
                    }
                    log("You smelt the ore into an ingot.");
                    player.give_exp(SMITHING, 175 * (1 << ore_tier));
                }
                done = true;
                break;
            }
        }
        if (!done)
        {
            log("You have no ore to smelt.");
        }
    }
    else if (!cell.entities.is_empty())
    {
        Entity target = cell.entities[0];
        if (target.type == Monster.typeid)
        {
            player.attack((Monster*) target, true);
        }
        else
        {
            log("Nothing interesting happens.");
        }
    }
    else
    {
        log("Nothing interesting happens.");
    }
}

fn void open_door(Zone* zone, IVec2 p)
{
    ZoneCell* cell = zone.get_cell(...p);
    switch (cell.terrain)
    {
    case TERR_DOOR_NORTH_L:
    case TERR_LDOOR_NORTH_L:
    case TERR_BDOOR_NORTH_L:
        cell.terrain = TERR_ODOOR_NORTH_L;
        zone.get_cell(p.x + 1, p.y).terrain = TERR_ODOOR_NORTH_R;
        zone.get_cell(p.x, p.y - 2).terrain = TERR_ODOOR_SOUTH_L;
        zone.get_cell(p.x + 1, p.y - 2).terrain = TERR_ODOOR_SOUTH_R;
    case TERR_DOOR_NORTH_R:
    case TERR_LDOOR_NORTH_R:
    case TERR_BDOOR_NORTH_R:
        cell.terrain = TERR_ODOOR_NORTH_R;
        zone.get_cell(p.x - 1, p.y).terrain = TERR_ODOOR_NORTH_L;
        zone.get_cell(p.x - 1, p.y - 2).terrain = TERR_ODOOR_SOUTH_L;
        zone.get_cell(p.x, p.y - 2).terrain = TERR_ODOOR_SOUTH_R;
    case TERR_DOOR_EAST_U:
    case TERR_LDOOR_EAST_U:
    case TERR_BDOOR_EAST_U:
        cell.terrain = TERR_ODOOR_EAST_U;
        zone.get_cell(p.x, p.y + 1).terrain = TERR_ODOOR_EAST_L;
        zone.get_cell(p.x + 2, p.y).terrain = TERR_ODOOR_WEST_U;
        zone.get_cell(p.x + 2, p.y + 1).terrain = TERR_ODOOR_WEST_L;
    case TERR_DOOR_EAST_L:
    case TERR_LDOOR_EAST_L:
    case TERR_BDOOR_EAST_L:
        cell.terrain = TERR_ODOOR_EAST_L;
        zone.get_cell(p.x, p.y - 1).terrain = TERR_ODOOR_EAST_U;
        zone.get_cell(p.x + 2, p.y - 1).terrain = TERR_ODOOR_WEST_U;
        zone.get_cell(p.x + 2, p.y).terrain = TERR_ODOOR_WEST_L;
    case TERR_DOOR_SOUTH_L:
    case TERR_LDOOR_SOUTH_L:
    case TERR_BDOOR_SOUTH_L:
        cell.terrain = TERR_ODOOR_SOUTH_L;
        zone.get_cell(p.x + 1, p.y).terrain = TERR_ODOOR_SOUTH_R;
        zone.get_cell(p.x, p.y + 2).terrain = TERR_ODOOR_NORTH_L;
        zone.get_cell(p.x + 1, p.y + 2).terrain = TERR_ODOOR_NORTH_R;
    case TERR_DOOR_SOUTH_R:
    case TERR_LDOOR_SOUTH_R:
    case TERR_BDOOR_SOUTH_R:
        cell.terrain = TERR_ODOOR_SOUTH_R;
        zone.get_cell(p.x - 1, p.y).terrain = TERR_ODOOR_SOUTH_L;
        zone.get_cell(p.x - 1, p.y + 2).terrain = TERR_ODOOR_NORTH_L;
        zone.get_cell(p.x, p.y + 2).terrain = TERR_ODOOR_NORTH_R;
    case TERR_DOOR_WEST_U:
    case TERR_LDOOR_WEST_U:
    case TERR_BDOOR_WEST_U:
        cell.terrain = TERR_ODOOR_WEST_U;
        zone.get_cell(p.x, p.y + 1).terrain = TERR_ODOOR_WEST_L;
        zone.get_cell(p.x - 2, p.y).terrain = TERR_ODOOR_EAST_U;
        zone.get_cell(p.x - 2, p.y + 1).terrain = TERR_ODOOR_EAST_L;
    case TERR_DOOR_WEST_L:
    case TERR_LDOOR_WEST_L:
    case TERR_BDOOR_WEST_L:
        cell.terrain = TERR_ODOOR_WEST_L;
        zone.get_cell(p.x, p.y - 1).terrain = TERR_ODOOR_WEST_U;
        zone.get_cell(p.x - 2, p.y - 1).terrain = TERR_ODOOR_EAST_U;
        zone.get_cell(p.x - 2, p.y).terrain = TERR_ODOOR_EAST_L;
    case TERR_ODOOR_NORTH_L:
    case TERR_ODOOR_NORTH_R:
    case TERR_ODOOR_EAST_U:
    case TERR_ODOOR_EAST_L:
    case TERR_ODOOR_SOUTH_L:
    case TERR_ODOOR_SOUTH_R:
    case TERR_ODOOR_WEST_U:
    case TERR_ODOOR_WEST_L:
        break;
    default:
        unreachable();
    }
}

fn InteractAction* do_interact(IVec2 dir)
{
    InteractAction* move_action = mem::temp_alloc(InteractAction);
    move_action.dir = dir;
    return move_action;
}

fn int[3] Player.get_style_stats(&self, CombatStyle style)
{
    int[3] stats = {0, 0, 0};
    foreach (item: self.equipment)
    {
        if (item.item != NO_ITEM)
        {
            ItemInfo* info = &g_items.items[item.item];
            assert(info.stats);
            stats[0] += info.stats.accuracy[style];
            stats[1] += info.stats.strength[style];
            stats[2] += info.stats.defence[style];
        }
    }
    return stats;
}

fn int Player.calculate_damage(&self, Monster* target, CombatStyle style)
{
    MonsterInfo* target_info = target.info;
    int str = self.boosted_level[Skill.MELEE.ordinal + style.ordinal] + 9;
    int[3] stats = self.get_style_stats(style);
    int max_hit = (str * (stats[1] + 64) + 320) / 640;
    int atk = self.boosted_level[Skill.MELEE.ordinal + style.ordinal] + 9;
    int attack_roll = atk * (stats[0] + 64);
    int defence_roll = (target.boosted_level[MonsterLevel.DEFENCE] + 9) * (target_info.defence_bonus[style] + 16);
    float hit_chance;
    if (attack_roll > defence_roll)
    {
        hit_chance = 1.0f - (defence_roll + 2.0f) / (2.0f * (attack_roll + 1.0f));
    }
    else
    {
        hit_chance = attack_roll / (2.0f * (defence_roll + 1.0f));
    }

    float range = (float) (ivec2_fdistance(self.get_position(), target.get_position()) / self.getAttackRange());
    hit_chance *= math::clamp(1.0f - range / 2, 0.1f, 1.0f);

    bool hit = random::next_float(&g_rng) < hit_chance;
    io::printfn("Player attack: max_hit %d, atk %d, attack_roll %d, defence_roll %d, hit_chance %.01f%%, hit %s", max_hit, atk, attack_roll, defence_roll, hit_chance * 100, hit ? "yes" : "no");
    if (!hit) return 0;
    int damage = random::next_in_range(&g_rng, 1, max_hit);
    return damage;
}

fn void Player.attack(&self, Monster* target, bool apply_attunement)
{
    CombatStyle style = getStyle(self.equipment[EquipmentSlot.WEAPON].item);
    int damage = self.calculate_damage(target, style);
    String success = damage > 0 ? "hit" : "miss";
    target.take_damage(damage);
    self.applyAttunement(target, damage);
    String killed = "";
    if (target.is_dead())
    {
        killed = " and killed";
    }
    DString ending;
    ending.temp_init();
    if (damage < 5) ending.append_char('.');
    for (int i = 0; i < damage/5; ++i)
    {
        ending.append_char('!');
    }
    log(string::new_format("You %s%s the %s%s", success, killed, target.get_name(), ending), damage > 0 ? colors::GREEN : colors::ORANGE);
    self.give_exp(Skill.from_ordinal(Skill.MELEE.ordinal + style.ordinal), damage * 20);
    self.give_exp(HITPOINTS, damage * 2);
}

fn void Player.applyAttunement(&self, Monster* target, int damage)
{
    if (self.attunement == NONE) return;
    Item rune = Item.BLANK_RUNE + self.attunement.ordinal;
    Attunement attunement = self.attunement;
    if (!self.remove_item({rune, 1, 0}))
    {
        log(string::new_format("You lose your attunement to %s as you ran out of runes.", Attunement.names[self.attunement.ordinal]));
        self.attunement = NONE;
        return;
    }
    switch (attunement)
    {
    case AIR:
        // Apply extra damage
        break;
    case WATER:
        // Apply stat drain
        break;
    case EARTH:
        // Apply knockback
        break;
    case FIRE:
        // Apply burning
        break;
    case CHAOS:
        // Apply AoE
        break;
    case NATURE:
        // Apply life steal
        break;
    case BLOOD:
        // Apply bleed
        break;
    case NONE:
        unreachable();
    }
}

fn PlayerRangedAction* do_ranged_attack(double time, IVec2 target)
{
    PlayerRangedAction* attack = mem::temp_alloc(PlayerRangedAction);
    attack.time = time;
    attack.target = target;
    return attack;
}

struct PlayerRangedAction (Action)
{
    double time;
    IVec2 target;
    bool los;
}
fn double PlayerRangedAction.duration(&self) @dynamic => self.time;

fn bool PlayerRangedAction.lineCB(&self, IVec2 next)
{
    ZoneCell* cell = g_zone.get_cell(...next);
    if (cell.isTerrainPassable())
    {
        return true;
    }
    else
    {
        self.los = false;
        return false;
    }
}

fn void PlayerRangedAction.apply(&self, Entity entity) @dynamic
{
    Player* player = (Player*) entity;
    ZoneCell* target_cell = player.get_zone().get_cell(...self.target);
    if (target_cell.entities.is_empty())
    {
        log("Your attack doesn't hit anything.");
        return;
    }
    self.los = true;
    line(player.get_position(), self.target, (LineCallback) &PlayerRangedAction.lineCB, self);
    if (!self.los)
    {
        log("You can't see your target.");
        return;
    }
    Entity target = target_cell.entities[0];
    if (target.type == Monster.typeid)
    {
        player.attack((Monster*) target, true);
    }
    else
    {
        log("Your attack doesn't hit anything.");
    }
}

fn GrabAction* do_grab()
{
    GrabAction* action = mem::temp_alloc(GrabAction);
    action.time = 0.5;
    return action;
}

struct GrabAction (Action)
{
    double time;
}

fn double GrabAction.duration(&self) @dynamic => self.time;

fn void GrabAction.apply(&self, Entity entity) @dynamic
{
    Player* player = (Player*) entity;
    ZoneCell* cell = player.get_zone().get_cell(...player.get_position());
    if (cell.dropped_items.is_empty())
    {
        log("There is nothing to grab here.");
    }
    else if (cell.dropped_items.len() == 1)
    {
        ItemStack item = cell.dropped_items[0];
        if (player.is_inventory_full(item))
        {
            log("Your inventory is full.");
        }
        else
        {
            player.add_item(cell.dropped_items[0]);
            cell.dropped_items.clear();
        }
    }
    else
    {
        inv_action_target = player.get_position();
        gui::open_popup("Grab Item");
    }
}
