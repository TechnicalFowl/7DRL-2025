module dg;

import std::io;
import std::math;
import raylib5::rl;

const INVENTORY_SIZE = 26;

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

    int[Skill.elements] level;
    int[Skill.elements] experience;
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
        inv_use_source = -1;
        return null;
    }
    else
    {
        return do_interact(dir);
    }
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

    if (rl::isMouseButtonPressed(rl::MouseButton.LEFT) && !gui::want_mouse_input())
    {
        if (self.nav.is_idle())
        {
            IVec2 pos = math::clamp(self.get_zone().get_mouse_position(), IVec2 {0, 0}, IVec2 {self.get_zone().width - 1, self.get_zone().height - 1});
            self.nav.path_to(self.get_zone(), self.get_position(), pos);
        }
        else
        {
            self.nav.abort();
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
                    for (int y= 0; y < 8 && self.nav.is_idle(); ++y)
                    {
                        for (int x = 0; x < 8 && self.nav.is_idle(); ++x)
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

            if (is_key_pressed(WAIT) || math::abs(rl::getMouseWheelMove()) > 0.01)
            {
                return do_wait(1.0);
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
                ZoneCell* cell = self.get_zone().get_cell(...self.get_position());
                if (cell.dropped_items.is_empty())
                {
                    log("There is nothing to grab here.");
                }
                else if (cell.dropped_items.len() == 1)
                {
                    ItemStack item = cell.dropped_items[0];
                    if (self.is_inventory_full(item))
                    {
                        log("Your inventory is full.");
                    }
                    else
                    {
                        self.add_item(cell.dropped_items[0]);
                        cell.dropped_items.clear();
                    }
                }
                else
                {
                    grab_target = self.get_position();
                    gui::open_popup("Grab Item");
                }
                return null;
            }
        }
        else if (inv_use_source != -1)
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
            if (next_cell.isPassable())
            {
                return do_move(next_move);
            }
            else if (is_door_terrain(next_cell.terrain))
            {
                return do_interact(next_move);
            }
            else
            {
                self.nav.abort();
                return do_interact(next_move);
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
    ZoneCell* cell = entity.get_zone().get_cell(...new_pos);
    if (inv_use_source != -1)
    {
        ItemStack item = player.inventory[inv_use_source];
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
                    player.inventory[inv_use_source].count -= 1;
                    if (player.inventory[inv_use_source].count == 0)
                    {
                        player.inventory[inv_use_source] = { NO_ITEM, 0, 0 };
                    }
                    log("You smelt the ore into an ingot.");
                    player.give_exp(SMITHING, 175 * (1 << ore_tier));
                }
                inv_use_source = -1;
                return;
            }
            else if (item.item == LOGS)
            {
                log("You burn the logs in the furnace.");
                player.inventory[inv_use_source].count -= 1;
                if (player.inventory[inv_use_source].count == 0)
                {
                    player.inventory[inv_use_source] = { NO_ITEM, 0, 0 };
                }
            }
        }
        else if (cell.object == OBJ_ORE_ROCK1 || cell.object == OBJ_ORE_ROCK2 || cell.object == OBJ_ORE_ROCK3)
        {
            if (item.item != PICKAXE)
            {
                log("You need a pickaxe to mine ore.");
                inv_use_source = -1;
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
            inv_use_source = -1;
            return;
        }
        else if (cell.object == OBJ_TREE)
        {
            if (item.item != AXE)
            {
                log("You need an axe to chop down trees.");
                inv_use_source = -1;
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
            inv_use_source = -1;
            return;
        }
        else if (cell.object == OBJ_STUMP)
        {
            if (item.item == AXE)
            {
                log("You can't get any more wood from this stump.");
                inv_use_source = -1;
                return;
            }
        }
        else if (cell.object == OBJ_ROCKS)
        {
            if (item.item == PICKAXE)
            {
                log("You can't get any useful ore from these rocks.");
                cell.object = OBJ_SMALL_ROCKS;
                inv_use_source = -1;
                return;
            }
        }
        else if (is_wall_terrain(cell.terrain))
        {
            if (item.item == PICKAXE)
            {
                log("The bricks are too hard to break.");
                inv_use_source = -1;
                return;
            }
        }
        log("Nothing interesting happens.");
        inv_use_source = -1;
    }
    else if (is_door_terrain(cell.terrain))
    {
        Room* r = find_room(new_pos)!!;
        Direction dir = get_door_direction(new_pos);
        Door* d = &r.doors[dir.ordinal - 1];
        assert(d.type == UNLOCKED);
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
        Room* next_room = find_room(entity.get_position())!!;
        player.explore(next_room.position, next_room.size);
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

        int count = random::next_in_range(&g_rng, 3, 5);
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
            Monster* monster = (Monster*) target;
            int damage = player.calculate_melee_damage(monster);
            String success = damage > 0 ? "attack" : "miss";
            monster.take_damage(damage);
            String killed = "";
            if (monster.is_dead())
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
            log(string::new_format("You %s%s the %s%s", success, killed, monster.get_name(), ending));
            player.give_exp(MELEE, damage * 30);
            player.give_exp(HITPOINTS, damage * 10);
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

fn int Player.calculate_melee_damage(&self, Monster* target)
{
    MonsterInfo* target_info = target.info;
    int str = self.level[Skill.MELEE] + 9;
    int[3] stats = self.get_style_stats(MELEE);
    int max_hit = (str * (stats[1] + 64) + 320) / 640;
    int atk = self.level[Skill.MELEE] + 9;
    int attack_roll = atk * (stats[0] + 64);
    int defence_roll = (target_info.defence + 9) * (target_info.defence_bonus[0] + 16);
    float hit_chance;
    if (attack_roll > defence_roll)
    {
        hit_chance = 1.0f - (defence_roll + 2.0f) / (2.0f * (attack_roll + 1.0f));
    }
    else
    {
        hit_chance = attack_roll / (2.0f * (defence_roll + 1.0f));
    }
    bool hit = random::next_float(&g_rng) < hit_chance;
    io::printfn("Attach: max_hit %d, atk %d, attack_roll %d, defence_roll %d, hit_chance %.01f%%, hit %s", max_hit, atk, attack_roll, defence_roll, hit_chance * 100, hit ? "yes" : "no");
    if (!hit) return 0;
    int damage = random::next_in_range(&g_rng, 1, max_hit);
    return damage;
}
