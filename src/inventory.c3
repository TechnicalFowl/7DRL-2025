module dg;

import std::collections::map;

enum Item : inline int
{
    SWORD,
    BOW,
    STAFF,
    PICKAXE,
    AXE,

    HELMET,
    WIZARD_HAT,
    HOOD,
    CHEST,
    LEGS,
    BOOTS,
    GLOVES,
    SHIELD,
    AMULET,
    RING,

    KNIFE,
    NEEDLE,
    POTION,
    FOOD,
    ORE,
    INGOT,
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

struct ItemInfo
{
    Item item;
    String name;
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
    
    self.items[Item.SWORD] = { SWORD, "Sword"};
    self.items[Item.BOW] = { BOW, "Bow"};
    self.items[Item.STAFF] = { STAFF, "Staff"};
    self.items[Item.PICKAXE] = { PICKAXE, "Pickaxe"};
    self.items[Item.AXE] = { AXE, "Axe"};

    self.items[Item.HELMET] = { HELMET, "Helmet"};
    self.items[Item.WIZARD_HAT] = { WIZARD_HAT, "Wizard Hat"};
    self.items[Item.HOOD] = { HOOD, "Hood"};
    self.items[Item.CHEST] = { CHEST, "Chest"};
    self.items[Item.LEGS] = { LEGS, "Legs"};
    self.items[Item.BOOTS] = { BOOTS, "Boots"};
    self.items[Item.GLOVES] = { GLOVES, "Gloves"};
    self.items[Item.SHIELD] = { SHIELD, "Shield"};
    self.items[Item.AMULET] = { AMULET, "Amulet"};
    self.items[Item.RING] = { RING, "Ring"};

    self.items[Item.KNIFE] = { KNIFE, "Knife"};
    self.items[Item.NEEDLE] = { NEEDLE, "Needle"};
    self.items[Item.POTION] = { POTION, "Potion"};
    self.items[Item.FOOD] = { FOOD, "Food"};
    self.items[Item.ORE] = { ORE, "Ore"};
    self.items[Item.INGOT] = { INGOT, "Ingot"};
    self.items[Item.LOGS] = { LOGS, "Logs"};
    self.items[Item.KEY] = { KEY, "Key"};
    self.items[Item.COINS] = { COINS, "Coins"};
    self.items[Item.GATESTONE] = { GATESTONE, "Gatestone"};
    self.items[Item.AIR_RUNE] = { AIR_RUNE, "Air Rune"};
    self.items[Item.WATER_RUNE] = { WATER_RUNE, "Water Rune"};
    self.items[Item.EARTH_RUNE] = { EARTH_RUNE, "Earth Rune"};
    self.items[Item.FIRE_RUNE] = { FIRE_RUNE, "Fire Rune"};

    for (int i = 0; i < ITEM_COUNT; ++i)
    {
        ItemInfo* info = &self.items[i];
        assert(info.item.ordinal == i, "ItemCache: Item in %d slot is not correct (expected %s)", i, Item.names[i]);
        self.item_names.set(info.name, info.item);
    }
}