module dg;

import std::collections::map;
import std::math;

enum Item : inline int
{
    NO_ITEM,

    SWORD0,
    SWORD1,
    SWORD2,
    SWORD3,
    BOW0,
    BOW1,
    BOW2,
    BOW3,
    STAFF0,
    STAFF1,
    STAFF2,
    STAFF3,

    HELMET1,
    HELMET2,
    HELMET3,
    WIZARD_HAT1,
    WIZARD_HAT2,
    WIZARD_HAT3,
    HOOD1,
    HOOD2,
    HOOD3,
    BODY1,
    BODY2,
    BODY3,
    LEGS1,
    LEGS2,
    LEGS3,
    SHIELD1,
    SHIELD2,
    SHIELD3,
    AMULET1,
    AMULET2,
    AMULET3,
    RING1,
    RING2,
    RING3,

    PICKAXE,
    AXE,
    KNIFE,
    NEEDLE,
    POTION1,
    POTION2,
    POTION3,
    FOOD,
    ORE1,
    ORE2,
    ORE3,
    INGOT1,
    INGOT2,
    INGOT3,
    LOGS,
    KEY,
    COINS,
    GATESTONE,
    AIR_RUNE,
    WATER_RUNE,
    EARTH_RUNE,
    FIRE_RUNE,
}

const int ITEM_COUNT = (int) Item.elements;

enum EquipmentSlot : inline int
{
    NONE,
    HEAD,
    CHEST,
    LEGS,
    WEAPON,
    SHIELD,
    AMULET,
    RING,
}

struct EquipmentStats
{
    EquipmentSlot slot;
}

fn EquipmentStats* create_stats(EquipmentSlot slot)
{
    EquipmentStats* stats = mem::new(EquipmentStats);
    stats.slot = slot;
    return stats;
}

struct ItemInfo
{
    Item item;
    String name;
    int stack_size;
    EquipmentStats* stats;

    Appearance look;
}

struct ItemStack
{
    Item item;
    int count;
    int metadata;
}

struct ItemCache
{
    ItemInfo[ITEM_COUNT] items;
    HashMap(<String, Item>) item_names;
}
ItemCache g_items;

fn void ItemCache.new_init(&self)
{
    self.item_names.new_init();
    
    self.items[Item.SWORD0] = { SWORD0, "Rusty Sword", 1, create_stats(EquipmentSlot.WEAPON), ITEM_SWORD0 };
    self.items[Item.SWORD1] = { SWORD1, "Novite Sword", 1, create_stats(EquipmentSlot.WEAPON), ITEM_SWORD1 };
    self.items[Item.SWORD2] = { SWORD2, "Fractite Sword", 1, create_stats(EquipmentSlot.WEAPON), ITEM_SWORD2 };
    self.items[Item.SWORD3] = { SWORD3, "Promethium Sword", 1, create_stats(EquipmentSlot.WEAPON), ITEM_SWORD3 };
    self.items[Item.BOW0] = { BOW0, "Bow", 1, create_stats(EquipmentSlot.WEAPON), ITEM_BOW0 };
    self.items[Item.BOW1] = { BOW1, "Novite Bow", 1, create_stats(EquipmentSlot.WEAPON), ITEM_BOW1 };
    self.items[Item.BOW2] = { BOW2, "Fractite Bow", 1, create_stats(EquipmentSlot.WEAPON), ITEM_BOW2 };
    self.items[Item.BOW3] = { BOW3, "Promethium Bow", 1, create_stats(EquipmentSlot.WEAPON), ITEM_BOW3 };
    self.items[Item.STAFF0] = { STAFF0, "Staff", 1, create_stats(EquipmentSlot.WEAPON), ITEM_STAFF0 };
    self.items[Item.STAFF1] = { STAFF1, "Novite Staff", 1, create_stats(EquipmentSlot.WEAPON), ITEM_STAFF1 };
    self.items[Item.STAFF2] = { STAFF2, "Fractite Staff", 1, create_stats(EquipmentSlot.WEAPON), ITEM_STAFF2 };
    self.items[Item.STAFF3] = { STAFF3, "Promethium Staff", 1, create_stats(EquipmentSlot.WEAPON), ITEM_STAFF3 };

    self.items[Item.HELMET1] = { HELMET1, "Novite Helmet", 1, create_stats(EquipmentSlot.HEAD), ITEM_HELM1 };
    self.items[Item.HELMET2] = { HELMET2, "Fractite Helmet", 1, create_stats(EquipmentSlot.HEAD), ITEM_HELM2 };
    self.items[Item.HELMET3] = { HELMET3, "Promethium Helmet", 1, create_stats(EquipmentSlot.HEAD), ITEM_HELM3 };
    self.items[Item.WIZARD_HAT1] = { WIZARD_HAT1, "Wizard Hat", 1, create_stats(EquipmentSlot.HEAD), ITEM_WIZARD_HAT1 };
    self.items[Item.WIZARD_HAT2] = { WIZARD_HAT2, "Enchanted Hat", 1, create_stats(EquipmentSlot.HEAD), ITEM_WIZARD_HAT2 };
    self.items[Item.WIZARD_HAT3] = { WIZARD_HAT3, "Mystic Hat", 1, create_stats(EquipmentSlot.HEAD), ITEM_WIZARD_HAT3 };
    self.items[Item.HOOD1] = { HOOD1, "Leather Hood", 1, create_stats(EquipmentSlot.HEAD), ITEM_HOOD1 };
    self.items[Item.HOOD2] = { HOOD2, "Studded Hood", 1, create_stats(EquipmentSlot.HEAD), ITEM_HOOD2 };
    self.items[Item.HOOD3] = { HOOD3, "Dragonhide Hood", 1, create_stats(EquipmentSlot.HEAD), ITEM_HOOD3 };
    self.items[Item.BODY1] = { BODY1, "Novite Chestplate", 1, create_stats(EquipmentSlot.CHEST), ITEM_BODY1 };
    self.items[Item.BODY2] = { BODY2, "Fractite Chestplate", 1, create_stats(EquipmentSlot.CHEST), ITEM_BODY2 };
    self.items[Item.BODY3] = { BODY3, "Promethium Chestplate", 1, create_stats(EquipmentSlot.CHEST), ITEM_BODY3 };
    self.items[Item.LEGS1] = { LEGS1, "Novite Leggings", 1, create_stats(EquipmentSlot.LEGS), ITEM_LEGS1 };
    self.items[Item.LEGS2] = { LEGS2, "Fractite Leggings", 1, create_stats(EquipmentSlot.LEGS), ITEM_LEGS2 };
    self.items[Item.LEGS3] = { LEGS3, "Promethium Leggings", 1, create_stats(EquipmentSlot.LEGS), ITEM_LEGS3 };
    self.items[Item.SHIELD1] = { SHIELD1, "Novite Shield", 1, create_stats(EquipmentSlot.SHIELD), ITEM_SHIELD1 };
    self.items[Item.SHIELD2] = { SHIELD2, "Fractite Shield", 1, create_stats(EquipmentSlot.SHIELD), ITEM_SHIELD2 };
    self.items[Item.SHIELD3] = { SHIELD3, "Promethium Shield", 1, create_stats(EquipmentSlot.SHIELD), ITEM_SHIELD3 };
    self.items[Item.AMULET1] = { AMULET1, "Amulet of Power", 1, create_stats(EquipmentSlot.AMULET), ITEM_AMULET1 };
    self.items[Item.AMULET2] = { AMULET2, "Amulet of Defense", 1, create_stats(EquipmentSlot.AMULET), ITEM_AMULET2 };
    self.items[Item.AMULET3] = { AMULET3, "Amulet of Magic", 1, create_stats(EquipmentSlot.AMULET), ITEM_AMULET3 };
    self.items[Item.RING1] = { RING1, "Ring of Strength", 1, create_stats(EquipmentSlot.RING), ITEM_RING1 };
    self.items[Item.RING2] = { RING2, "Ring of Dexterity", 1, create_stats(EquipmentSlot.RING), ITEM_RING2 };
    self.items[Item.RING3] = { RING3, "Ring of Intelligence", 1, create_stats(EquipmentSlot.RING), ITEM_RING3 };

    self.items[Item.PICKAXE] = { PICKAXE, "Pickaxe", 1, null, ITEM_PICKAXE };
    self.items[Item.AXE] = { AXE, "Axe", 1, null, ITEM_AXE };
    self.items[Item.KNIFE] = { KNIFE, "Knife", 1, null, ITEM_KNIFE };
    self.items[Item.NEEDLE] = { NEEDLE, "Needle", 1, null, ITEM_NEEDLE };
    self.items[Item.POTION1] = { POTION1, "Health Potion", 5, null, ITEM_POTION1 };
    self.items[Item.POTION2] = { POTION2, "Mana Potion", 5, null, ITEM_POTION2 };
    self.items[Item.POTION3] = { POTION3, "Stamina Potion", 5, null, ITEM_POTION3 };
    self.items[Item.FOOD] = { FOOD, "Food", 5, null, ITEM_FOOD };
    self.items[Item.ORE1] = { ORE1, "Novite Ore", 5, null, ITEM_ORE1 };
    self.items[Item.ORE2] = { ORE2, "Fractite Ore", 5, null, ITEM_ORE2 };
    self.items[Item.ORE3] = { ORE3, "Promethium Ore", 5, null, ITEM_ORE3 };
    self.items[Item.INGOT1] = { INGOT1, "Novite Ingot", 5, null, ITEM_INGOT1 };
    self.items[Item.INGOT2] = { INGOT2, "Fractite Ingot", 5, null, ITEM_INGOT2 };
    self.items[Item.INGOT3] = { INGOT3, "Promethium Ingot", 5, null, ITEM_INGOT3 };
    self.items[Item.LOGS] = { LOGS, "Logs", 5, null, ITEM_LOGS };
    self.items[Item.KEY] = { KEY, "Key", 1, null, ITEM_KEY };
    self.items[Item.COINS] = { COINS, "Coins", 999, null, ITEM_COINS };
    self.items[Item.GATESTONE] = { GATESTONE, "Gatestone", 1, null, ITEM_GATESTONE };
    self.items[Item.AIR_RUNE] = { AIR_RUNE, "Air Rune", 999, null, ITEM_AIR_RUNE };
    self.items[Item.WATER_RUNE] = { WATER_RUNE, "Water Rune", 999, null, ITEM_WATER_RUNE };
    self.items[Item.EARTH_RUNE] = { EARTH_RUNE, "Earth Rune", 999, null, ITEM_EARTH_RUNE };
    self.items[Item.FIRE_RUNE] = { FIRE_RUNE, "Fire Rune", 999, null, ITEM_FIRE_RUNE };

    for (int i = 0; i < ITEM_COUNT; ++i)
    {
        ItemInfo* info = &self.items[i];
        assert(info.item.ordinal == i, "ItemCache: Item in %d slot is not correct (expected %s)", i, Item.names[i]);
        self.item_names.set(info.name, info.item);
    }

    init_drop_tables();
}

struct DropEntry
{
    ItemStack item;
    int weight;
}

struct DropTable
{
    DropEntry[] entries;
    DropTable*[] subtables;
    int total_weight;
}

fn void DropTable.new_init(&self, DropTable*[] subtables, DropEntry... entries)
{
    self.subtables = mem::new_array(DropTable*, subtables.len);
    self.entries = mem::new_array(DropEntry, entries.len);
    self.total_weight = 0;
    int i = 0;
    foreach (sub: subtables)
    {
        self.subtables[i++] = sub;
        self.total_weight += sub.total_weight;
    }
    i = 0;
    foreach (entry : entries)
    {
        self.entries[i++] = entry;
        self.total_weight += entry.weight;
    }
}

fn ItemStack DropTable.get_item(&self, int* weight, int roll)
{
    foreach (entry : self.entries)
    {
        *weight += entry.weight;
        if (roll < *weight)
        {
            return entry.item;
        }
    }
    return { Item.NO_ITEM, 0, 0 };
}

fn bool item_uses_metadata_for_range(Item item)
{
    return item == COINS || item == AIR_RUNE || item == WATER_RUNE || item == EARTH_RUNE || item == FIRE_RUNE;
}

fn ItemStack DropTable.roll(&self, random::Pcg32Random* rng)
{
    int roll = random::next_in_range(rng, 0, self.total_weight - 1);
    int weight = 0;
    foreach (entry : self.entries)
    {
        weight += entry.weight;
        if (roll < weight)
        {
            if (item_uses_metadata_for_range(entry.item.item))
            {
                int count = random::next_in_range(rng, entry.item.count - entry.item.metadata, entry.item.count + entry.item.metadata);
                return { entry.item.item, count, 0 };
            }
            return entry.item;
        }
    }
    foreach (sub : self.subtables)
    {
        ItemStack item = sub.get_item(&weight, roll);
        if (item.item != Item.NO_ITEM)
        {
            if (item_uses_metadata_for_range(item.item))
            {
                int count = random::next_in_range(rng, item.count - item.metadata, item.count + item.metadata);
                return { item.item, count, 0 };
            }
            return item;
        }
    }
    return { Item.NO_ITEM, 0, 0 };
}

DropTable starting_room_weapons;
DropTable starting_room_supplies;

DropTable[10] crate_loot;

fn void init_drop_tables()
{
    starting_room_weapons.new_init({},
        { { SWORD0, 1, 0 }, 300 },
        { { BOW0, 1, 0 }, 200 },
        { { STAFF0, 1, 0 }, 100 },
        { { SWORD1, 1, 0 }, 3 },
        { { BOW1, 1, 0 }, 2 },
        { { STAFF1, 1, 0 }, 1 },
    );
    starting_room_supplies.new_init({},
        { { FOOD, 1, 0}, 20 },
        { { PICKAXE, 1, 0}, 5 },
        { { AXE, 1, 0}, 5 },
        { { COINS, 10, 5}, 5 },
        { { COINS, 50, 20}, 5 },
        { { AIR_RUNE, 20, 5}, 5 },
        { { WATER_RUNE, 20, 5}, 5 },
        { { EARTH_RUNE, 20, 5}, 5 },
        { { FIRE_RUNE, 20, 5}, 5 },
    );

    crate_loot[0].new_init({ &starting_room_supplies },
        { { COINS, 50, 20}, 5 },
        { { ORE1, 1, 0}, 5 },
        { { LOGS, 1, 0}, 5 },
        { { INGOT1, 1, 0}, 5 },
        { { POTION1, 1, 0}, 5 },
    );
    crate_loot[1].new_init({ &starting_room_supplies },
        { { COINS, 50, 20}, 5 },
        { { ORE1, 1, 0}, 5 },
        { { ORE2, 1, 0}, 1 },
        { { LOGS, 1, 0}, 5 },
        { { INGOT1, 1, 0}, 5 },
        { { INGOT2, 1, 0}, 1 },
        { { POTION1, 1, 0}, 5 },
        { { POTION2, 1, 0}, 1 },
    );
    crate_loot[2].new_init({ &starting_room_supplies },
        { { COINS, 50, 20}, 5 },
        { { ORE1, 1, 0}, 3 },
        { { ORE2, 1, 0}, 3 },
        { { LOGS, 1, 0}, 5 },
        { { INGOT1, 1, 0}, 3 },
        { { INGOT2, 1, 0}, 3 },
        { { POTION1, 1, 0}, 3 },
        { { POTION2, 1, 0}, 3 },
        { { POTION3, 1, 0}, 3 },
        { { RING1, 1, 0}, 1 },
        { { AMULET1, 1, 0}, 1 },
    );
    crate_loot[3].new_init({ &starting_room_supplies },
        { { COINS, 70, 20}, 5 },
        { { ORE2, 1, 0}, 5 },
        { { LOGS, 1, 0}, 5 },
        { { INGOT2, 1, 0}, 5 },
        { { POTION1, 1, 0}, 3 },
        { { POTION2, 1, 0}, 3 },
        { { POTION3, 1, 0}, 3 },
        { { RING1, 1, 0}, 1 },
        { { AMULET1, 1, 0}, 1 },
    );
    crate_loot[4].new_init({ &starting_room_supplies },
        { { COINS, 90, 20}, 5 },
        { { ORE2, 1, 0}, 5 },
        { { ORE3, 1, 0}, 1 },
        { { LOGS, 1, 0}, 5 },
        { { INGOT2, 1, 0}, 5 },
        { { INGOT3, 1, 0}, 1 },
        { { POTION1, 1, 0}, 3 },
        { { POTION2, 1, 0}, 3 },
        { { POTION3, 1, 0}, 3 },
        { { RING1, 1, 0}, 2 },
        { { RING2, 1, 0}, 1 },
        { { AMULET1, 1, 0}, 2 },
        { { AMULET2, 1, 0}, 1 },
    );
    crate_loot[5].new_init({ &starting_room_supplies },
        { { COINS, 100, 20}, 5 },
        { { ORE2, 1, 0}, 3 },
        { { ORE3, 1, 0}, 3 },
        { { LOGS, 1, 0}, 5 },
        { { INGOT2, 1, 0}, 3 },
        { { INGOT3, 1, 0}, 3 },
        { { POTION1, 1, 0}, 3 },
        { { POTION2, 1, 0}, 3 },
        { { POTION3, 1, 0}, 3 },
        { { RING1, 1, 0}, 4 },
        { { RING2, 1, 0}, 2 },
        { { AMULET1, 1, 0}, 4 },
        { { AMULET2, 1, 0}, 2 },
    );
    crate_loot[5].new_init({ &starting_room_supplies },
        { { COINS, 100, 20}, 5 },
        { { ORE2, 1, 0}, 1 },
        { { ORE3, 1, 0}, 5 },
        { { LOGS, 1, 0}, 5 },
        { { INGOT2, 1, 0}, 1 },
        { { INGOT3, 1, 0}, 5 },
        { { POTION1, 1, 0}, 3 },
        { { POTION2, 1, 0}, 3 },
        { { POTION3, 1, 0}, 3 },
        { { RING1, 1, 0}, 3 },
        { { RING2, 1, 0}, 3 },
        { { RING3, 1, 0}, 1 },
        { { AMULET1, 1, 0}, 3 },
        { { AMULET2, 1, 0}, 3 },
        { { AMULET3, 1, 0}, 1 },
    );
    crate_loot[6].new_init({ &starting_room_supplies },
        { { COINS, 100, 20}, 5 },
        { { ORE3, 1, 0}, 5 },
        { { LOGS, 1, 0}, 5 },
        { { INGOT3, 1, 0}, 5 },
        { { POTION1, 1, 0}, 3 },
        { { POTION2, 1, 0}, 3 },
        { { POTION3, 1, 0}, 3 },
        { { RING1, 1, 0}, 2 },
        { { RING2, 1, 0}, 2 },
        { { RING3, 1, 0}, 2 },
        { { AMULET1, 1, 0}, 2 },
        { { AMULET2, 1, 0}, 2 },
        { { AMULET3, 1, 0}, 2 },
    );
    crate_loot[7].new_init({ &starting_room_supplies },
        { { COINS, 100, 20}, 5 },
        { { ORE3, 1, 0}, 5 },
        { { LOGS, 1, 0}, 5 },
        { { INGOT3, 1, 0}, 5 },
        { { POTION1, 1, 0}, 3 },
        { { POTION2, 1, 0}, 3 },
        { { POTION3, 1, 0}, 3 },
        { { RING1, 1, 0}, 2 },
        { { RING2, 1, 0}, 2 },
        { { RING3, 1, 0}, 2 },
        { { AMULET1, 1, 0}, 2 },
        { { AMULET2, 1, 0}, 2 },
        { { AMULET3, 1, 0}, 2 },
    );
    crate_loot[8].new_init({ &starting_room_supplies },
        { { COINS, 100, 20}, 5 },
        { { ORE3, 1, 0}, 5 },
        { { LOGS, 1, 0}, 5 },
        { { INGOT3, 1, 0}, 5 },
        { { POTION1, 1, 0}, 3 },
        { { POTION2, 1, 0}, 3 },
        { { POTION3, 1, 0}, 3 },
        { { RING1, 1, 0}, 2 },
        { { RING2, 1, 0}, 2 },
        { { RING3, 1, 0}, 2 },
        { { AMULET1, 1, 0}, 2 },
        { { AMULET2, 1, 0}, 2 },
        { { AMULET3, 1, 0}, 2 },
    );
    crate_loot[9].new_init({ &starting_room_supplies },
        { { COINS, 100, 20}, 5 },
        { { ORE3, 1, 0}, 5 },
        { { LOGS, 1, 0}, 5 },
        { { INGOT3, 1, 0}, 5 },
        { { POTION1, 1, 0}, 3 },
        { { POTION2, 1, 0}, 3 },
        { { POTION3, 1, 0}, 3 },
        { { RING1, 1, 0}, 2 },
        { { RING2, 1, 0}, 2 },
        { { RING3, 1, 0}, 2 },
        { { AMULET1, 1, 0}, 2 },
        { { AMULET2, 1, 0}, 2 },
        { { AMULET3, 1, 0}, 2 },
    );
}
