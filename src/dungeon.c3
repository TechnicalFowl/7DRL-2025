module dg;

import std::collections::list;
import std::collections::map;
import std::io;
import std::math;

enum Direction : (IVec2 dir)
{
    NONE = {0, 0},
    NORTH = {0, -1},
    EAST = {1, 0},
    SOUTH = {0, 1},
    WEST = {-1, 0},
}

const Direction[5] ROTATE_LEFT = { NONE, WEST, NORTH, EAST, SOUTH };
const Direction[5] ROTATE_RIGHT = { NONE, EAST, SOUTH, WEST, NORTH };
const Direction[5] FLIP = { NONE, SOUTH, WEST, NORTH, EAST };

enum DoorType
{
    WALL,
    UNLOCKED,
    LOCKED,
    BOSS,
}

struct Door
{
    DoorType type;
    Direction direction;
}

enum RoomType
{
    EMPTY,
    STARTING,
    BOSS,
    STANDARD,
    SPECIAL,
}

struct Room
{
    IVec2 position;
    IVec2 size;

    RoomType type;
    int distance_from_start;
    Door[4] doors;
}

fn void Room.new_init(&self, IVec2 pos, IVec2 sz)
{
    self.position = pos;
    self.size = sz;
    self.distance_from_start = 99;
}

fn void Room.free(&self)
{
}

enum SpecialRoomType
{
    EMPTY_STOREROOM,
    BATTLE_SITE,
    GOBLIN_CAMP,
    BANDIT_CAMP,
    ABANDONED_CAMP,
    BATTLE_SITE_CAMP,
    FORGE,
    DESTROYED_FORGE,
    RICH_MINE,
    EMPTIED_MINE,
    LOGGING_CAMP,
}

enum HotspotType : (int weight, uint exclusive_mask)
{
    EMPTY_SPOT = {40, 0},
    TREE = {5, 0},
    STUMP = {3, 0},
    ROCK = {3, 0},
    ORE = {5, 0},
    FURNACE = {4, 0x1020},
    STORE_CACHE = {8, 0x1000},
    SMALL_WARRIOR = {4, 0xc00},
    SMALL_ARCHER = {4, 0xc00},
    SMALL_MAGE = {4, 0xc00},
    MOB_GROUP = {2, 0xc00},
    BIG_GROUP = {1, 0xc00},
    GRAVESITE = {5, 0x60},
}

int hotspot_total_weight;

fn HotspotType get_random_hotspot(random::Pcg32Random* rng, uint existing_mask)
{
    for (int j = 0; j < 100; ++j)
    {
        int r = random::next_in_range(rng, 0, hotspot_total_weight - 1);
        for (int i = 0; i < HotspotType.elements; ++i)
        {
            r -= HotspotType.from_ordinal(i).weight;
            if (r < 0)
            {
                HotspotType hotspot = HotspotType.from_ordinal(i);
                if ((hotspot.exclusive_mask & existing_mask) == 0)
                {
                    return hotspot;
                }
                break; // reroll
            }
        }
    }
    //unreachable();
    return EMPTY_SPOT;
}

fn IVec2 get_random_pos(random::Pcg32Random* rng, IVec2 pos, IVec2 size, IVec2... avoid)
{
    for(int i = 0; i < 100; ++i)
    {
        IVec2 p = pos + {random::next_in_range(rng, 0, size.x - 1), random::next_in_range(rng, 0, size.y - 1)};
        bool invalid = false;
        foreach (a: avoid)
        {
            if (p == a)
            {
                invalid = true;
                break;
            }
        }
        if (!invalid) return p;
    }
    unreachable();
}

fn void Room.generate(&self, DungeonFloor* floor, Zone* zone, random::Pcg32Random* rng)
{
    IVec2 pos = self.position;
    for (int i = 0; i < 4; ++i)
    {
        Door* d = &self.doors[i];
        if (d.type == WALL) continue;
        assert(d.direction.ordinal == i + 1);
        switch (d.type)
        {
        case UNLOCKED:
            switch (d.direction)
            {
            case NORTH:
                zone.set_terrain(pos.x + 7, pos.y, TERR_DOOR_NORTH_L);
                zone.set_terrain(pos.x + 8, pos.y, TERR_DOOR_NORTH_R);
            case EAST:
                zone.set_terrain(pos.x + 15, pos.y + 7, TERR_DOOR_EAST_U);
                zone.set_terrain(pos.x + 15, pos.y + 8, TERR_DOOR_EAST_L);
            case SOUTH:
                zone.set_terrain(pos.x + 7, pos.y + 15, TERR_DOOR_SOUTH_L);
                zone.set_terrain(pos.x + 8, pos.y + 15, TERR_DOOR_SOUTH_R);
            case WEST:
                zone.set_terrain(pos.x, pos.y + 7, TERR_DOOR_WEST_U);
                zone.set_terrain(pos.x, pos.y + 8, TERR_DOOR_WEST_L);
            default:
                unreachable();
            }
        case LOCKED:
            switch (d.direction)
            {
            case NORTH:
                zone.set_terrain(pos.x + 7, pos.y, TERR_LDOOR_NORTH_L);
                zone.set_terrain(pos.x + 8, pos.y, TERR_LDOOR_NORTH_R);
            case EAST:
                zone.set_terrain(pos.x + 15, pos.y + 7, TERR_LDOOR_EAST_U);
                zone.set_terrain(pos.x + 15, pos.y + 8, TERR_LDOOR_EAST_L);
            case SOUTH:
                zone.set_terrain(pos.x + 7, pos.y + 15, TERR_LDOOR_SOUTH_L);
                zone.set_terrain(pos.x + 8, pos.y + 15, TERR_LDOOR_SOUTH_R);
            case WEST:
                zone.set_terrain(pos.x, pos.y + 7, TERR_LDOOR_WEST_U);
                zone.set_terrain(pos.x, pos.y + 8, TERR_LDOOR_WEST_L);
            default:
                unreachable();
            }
        case BOSS:
            switch (d.direction)
            {
            case NORTH:
                zone.set_terrain(pos.x + 7, pos.y, TERR_BDOOR_NORTH_L);
                zone.set_terrain(pos.x + 8, pos.y, TERR_BDOOR_NORTH_R);
            case EAST:
                zone.set_terrain(pos.x + 15, pos.y + 7, TERR_BDOOR_EAST_U);
                zone.set_terrain(pos.x + 15, pos.y + 8, TERR_BDOOR_EAST_L);
            case SOUTH:
                zone.set_terrain(pos.x + 7, pos.y + 15, TERR_BDOOR_SOUTH_L);
                zone.set_terrain(pos.x + 8, pos.y + 15, TERR_BDOOR_SOUTH_R);
            case WEST:
                zone.set_terrain(pos.x, pos.y + 7, TERR_BDOOR_WEST_U);
                zone.set_terrain(pos.x, pos.y + 8, TERR_BDOOR_WEST_L);
            default:
                unreachable();
            }
        default:
            break;
        }
    }
    if (self.type == EMPTY)
    {
        self.type = random::next_in_range(rng, 0, 5) == 0 ? SPECIAL : STANDARD;
    }

    switch (self.type)
    {
    case STARTING:
        zone.fill_terrain(pos + {1, 1}, {6, 6}, TERR_BRICKS);
        zone.set_object(pos.x + 4, pos.y + 4, OBJ_TRADER);
        if (random::next_in_range(rng, 0, 10) == 0) zone.set_object(pos.x + 12, pos.y + 4, OBJ_ANVIL);

        zone.drop_item(pos.x + 3, pos.y + 1, starting_room_weapons.roll(rng));
        if (random::next_in_range(rng, 0, 1) == 0) zone.drop_item(pos.x + 2, pos.y + 1, starting_room_weapons.roll(rng));
        if (random::next_in_range(rng, 0, 1) == 0) zone.drop_item(pos.x + 4, pos.y + 1, starting_room_weapons.roll(rng));

        int supplies0 = random::next_in_range(rng, 2, 5);
        for (int i = 0; i < supplies0; ++i)
        {
            zone.drop_item(pos.x + 1, pos.y + 2, starting_room_supplies.roll(rng));
        }
        int supplies1 = random::next_in_range(rng, 2, 5);
        for (int i = 0; i < supplies1; ++i)
        {
            zone.drop_item(pos.x + 1, pos.y + 3, starting_room_supplies.roll(rng));
        }
        int supplies2 = random::next_in_range(rng, 2, 5);
        for (int i = 0; i < supplies2; ++i)
        {
            zone.drop_item(pos.x + 1, pos.y + 4, starting_room_supplies.roll(rng));
        }
    case BOSS:
        self.spawn_exit_hole(zone);
        switch (boss_ordering[floor.depth])
        {
        default:
            break;
        }
    case STANDARD:
        int ne = math::max(random::next_in_range(rng, -2, 6), 0);
        int se = math::max(random::next_in_range(rng, -2, 6), 0);
        int sw = math::max(random::next_in_range(rng, -2, 6), 0);
        int nw = math::max(random::next_in_range(rng, -2, 6), 0);

        int[25] meta_grid;
        switch (ne)
        {
        case 0: break;
        case 1: meta_grid[4] = 1;
        case 2: meta_grid[4] = 1; meta_grid[3] = 1;
        case 3: meta_grid[4] = 1; meta_grid[1 * 5 + 4] = 1;
        case 4: meta_grid[4] = 1; meta_grid[3] = 1; meta_grid[1 * 5 + 4] = 1; meta_grid[1 * 5 + 3] = 1;
        case 5: meta_grid[4] = 1; meta_grid[3] = random::next_in_range(rng, 0, 1); meta_grid[1 * 5 + 4] = 1; meta_grid[1 * 5 + 3] = 1;
        case 6: meta_grid[4] = 1; meta_grid[3] = 1; meta_grid[1 * 5 + 4] = random::next_in_range(rng, 0, 1); meta_grid[1 * 5 + 3] = 1;
        default: unreachable();
        }
        switch (nw)
        {
        case 0: break;
        case 1: meta_grid[0] = 1;
        case 2: meta_grid[0] = 1; meta_grid[1] = 1;
        case 3: meta_grid[0] = 1; meta_grid[1 * 5] = 1;
        case 4: meta_grid[0] = 1; meta_grid[1] = 1; meta_grid[1 * 5] = 1; meta_grid[1 * 5 + 1] = 1;
        case 5: meta_grid[0] = 1; meta_grid[1] = random::next_in_range(rng, 0, 1); meta_grid[1 * 5] = 1; meta_grid[1 * 5 + 1] = 1;
        case 6: meta_grid[0] = 1; meta_grid[1] = 1; meta_grid[1 * 5] = random::next_in_range(rng, 0, 1); meta_grid[1 * 5 + 1] = 1;
        default: unreachable();
        }
        switch (se)
        {
        case 0: break;
        case 1: meta_grid[24] = 1;
        case 2: meta_grid[24] = 1; meta_grid[23] = 1;
        case 3: meta_grid[24] = 1; meta_grid[3 * 5 + 4] = 1;
        case 4: meta_grid[24] = 1; meta_grid[23] = 1; meta_grid[3 * 5 + 4] = 1; meta_grid[3 * 5 + 3] = 1;
        case 5: meta_grid[24] = 1; meta_grid[23] = random::next_in_range(rng, 0, 1); meta_grid[3 * 5 + 4] = 1; meta_grid[3 * 5 + 3] = 1;
        case 6: meta_grid[24] = 1; meta_grid[23] = 1; meta_grid[3 * 5 + 4] = random::next_in_range(rng, 0, 1); meta_grid[3 * 5 + 3] = 1;
        default: unreachable();
        }
        switch (sw)
        {
        case 0: break;
        case 1: meta_grid[20] = 1;
        case 2: meta_grid[20] = 1; meta_grid[21] = 1;
        case 3: meta_grid[20] = 1; meta_grid[3 * 5] = 1;
        case 4: meta_grid[20] = 1; meta_grid[21] = 1; meta_grid[3 * 5] = 1; meta_grid[3 * 5 + 1] = 1;
        case 5: meta_grid[20] = 1; meta_grid[21] = random::next_in_range(rng, 0, 1); meta_grid[3 * 5] = 1; meta_grid[3 * 5 + 1] = 1;
        case 6: meta_grid[20] = 1; meta_grid[21] = 1; meta_grid[3 * 5] = random::next_in_range(rng, 0, 1); meta_grid[3 * 5 + 1] = 1;
        default: unreachable();
        }
        if (self.doors[Direction.NORTH.ordinal - 1].type == WALL)
        {
            if (meta_grid[1] == 1 && meta_grid[3] == 1) meta_grid[2] = random::next_in_range(rng, 0, 1);
            if (meta_grid[6] == 1 && meta_grid[8] == 1 && meta_grid[2] == 1) meta_grid[7] = random::next_in_range(rng, 0, 1);
        }
        if (self.doors[Direction.EAST.ordinal - 1].type == WALL)
        {
            if (meta_grid[9] == 1 && meta_grid[19] == 1) meta_grid[14] = random::next_in_range(rng, 0, 1);
            if (meta_grid[8] == 1 && meta_grid[18] == 1 && meta_grid[14] == 1) meta_grid[7] = random::next_in_range(rng, 0, 1);
        }
        if (self.doors[Direction.SOUTH.ordinal - 1].type == WALL)
        {
            if (meta_grid[21] == 1 && meta_grid[23] == 1) meta_grid[22] = random::next_in_range(rng, 0, 1);
            if (meta_grid[16] == 1 && meta_grid[18] == 1 && meta_grid[22] == 1) meta_grid[17] = random::next_in_range(rng, 0, 1);
        }
        if (self.doors[Direction.WEST.ordinal - 1].type == WALL)
        {
            if (meta_grid[5] == 1 && meta_grid[15] == 1) meta_grid[10] = random::next_in_range(rng, 0, 1);
            if (meta_grid[11] == 1 && meta_grid[16] == 1 && meta_grid[10] == 1) meta_grid[11] = random::next_in_range(rng, 0, 1);
        }

        uint hotspot_mask = 0;

        for (int y = 0; y < 5; ++y)
        {
            int h = y == 2 ? 2 : 1;
            int y0 = y > 2 ? y * 3 + 1 : y * 3;
            for (int x = 0; x < 5; ++x)
            {
                int w = x == 2 ? 2 : 1;
                int x0 = x > 2 ? x * 3 + 1 : x * 3;
                if (meta_grid[y * 5 + x] == 1)
                {
                    bool up = y != 0 && meta_grid[(y - 1) * 5 + x] != 1;
                    bool down = y != 4 && meta_grid[(y + 1) * 5 + x] != 1;
                    bool left = x != 0 && meta_grid[y * 5 + x - 1] != 1;
                    bool right = x != 4 && meta_grid[y * 5 + x + 1] != 1;
                    bool upleft = y != 0 && x != 0 && meta_grid[(y - 1) * 5 + x - 1] != 1;
                    bool upright = y != 0 && x != 4 && meta_grid[(y - 1) * 5 + x + 1] != 1;
                    bool downleft = y != 4 && x != 0 && meta_grid[(y + 1) * 5 + x - 1] != 1;
                    bool downright = y != 4 && x != 4 && meta_grid[(y + 1) * 5 + x + 1] != 1;

                    if (up && left)
                    {
                        zone.set_terrain(pos.x + x0, pos.y + y0, TERR_PILLAR);
                    }
                    else if (!up && !left && upleft)
                    {
                        zone.set_terrain(pos.x + x0, pos.y + y0, TERR_WALL_SE);
                    }
                    else if (y == 0 && left)
                    {
                        zone.set_terrain(pos.x + x0, pos.y + y0, TERR_WALL_NE);
                    }
                    else if (x == 0 && up)
                    {
                        zone.set_terrain(pos.x + x0, pos.y + y0, TERR_WALL_SW);
                    }
                    else if (left && !up)
                    {
                        zone.set_terrain(pos.x + x0, pos.y + y0, TERR_WALL_EAST);
                    }
                    else if (up && !left)
                    {
                        zone.set_terrain(pos.x + x0, pos.y + y0, TERR_WALL_SOUTH);
                    }
                    else
                    {
                        zone.set_terrain(pos.x + x0, pos.y + y0, EMPTY_VOID);
                    }

                    if (up && right)
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0, TERR_PILLAR);
                    }
                    else if (!up && !right && upright)
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0, TERR_WALL_SW);
                    }
                    else if (y == 0 && right)
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0, TERR_WALL_NW);
                    }
                    else if (x == 4 && up)
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0, TERR_WALL_SE);
                    }
                    else if (right && !up)
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0, TERR_WALL_WEST);
                    }
                    else if (up && !right)
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0, TERR_WALL_SOUTH);
                    }
                    else
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0, EMPTY_VOID);
                    }

                    if (down && left)
                    {
                        zone.set_terrain(pos.x + x0, pos.y + y0 + 1 + h, TERR_PILLAR);
                    }
                    else if (!down && !left && downleft)
                    {
                        zone.set_terrain(pos.x + x0, pos.y + y0 + 1 + h, TERR_WALL_NE);
                    }
                    else if (y == 4 && left)
                    {
                        zone.set_terrain(pos.x + x0, pos.y + y0 + 1 + h, TERR_WALL_SE);
                    }
                    else if (x == 0 && down)
                    {
                        zone.set_terrain(pos.x + x0, pos.y + y0 + 1 + h, TERR_WALL_NW);
                    }
                    else if (left && !down)
                    {
                        zone.set_terrain(pos.x + x0, pos.y + y0 + 1 + h, TERR_WALL_EAST);
                    }
                    else if (down && !left)
                    {
                        zone.set_terrain(pos.x + x0, pos.y + y0 + 1 + h, TERR_WALL_NORTH);
                    }
                    else
                    {
                        zone.set_terrain(pos.x + x0, pos.y + y0 + 1 + h, EMPTY_VOID);
                    }

                    if (down && right)
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0 + 1 + h, TERR_PILLAR);
                    }
                    else if (!down && !right && downright)
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0 + 1 + h, TERR_WALL_NW);
                    }
                    else if (y == 4 && right)
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0 + 1 + h, TERR_WALL_SW);
                    }
                    else if (x == 4 && down)
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0 + 1 + h, TERR_WALL_NE);
                    }
                    else if (right && !down)
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0 + 1 + h, TERR_WALL_WEST);
                    }
                    else if (down && !right)
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0 + 1 + h, TERR_WALL_NORTH);
                    }
                    else
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0 + 1 + h, EMPTY_VOID);
                    }


                    for (int yy = 0; yy < h; ++yy)
                    {
                        for (int xx = 0; xx < w; ++xx)
                        {
                            zone.set_terrain(pos.x + x0 + xx + 1, pos.y + y0 + yy + 1, EMPTY_VOID);
                        }
                        if (left)
                        {
                            zone.set_terrain(pos.x + x0, pos.y + y0 + yy + 1, TERR_WALL_EAST);
                        }
                        else
                        {
                            zone.set_terrain(pos.x + x0, pos.y + y0 + yy + 1, EMPTY_VOID);
                        }
                        if (right)
                        {
                            zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0 + yy + 1, TERR_WALL_WEST);
                        }
                        else
                        {
                            zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0 + yy + 1, EMPTY_VOID);
                        }
                    }
                    for (int xx = 0; xx < w; ++xx)
                    {
                        if (up)
                        {
                            zone.set_terrain(pos.x + x0 + xx + 1, pos.y + y0, TERR_WALL_SOUTH);
                        }
                        else
                        {
                            zone.set_terrain(pos.x + x0 + xx + 1, pos.y + y0, EMPTY_VOID);
                        }
                        if (down)
                        {
                            zone.set_terrain(pos.x + x0 + xx + 1, pos.y + y0 + 1 + h, TERR_WALL_NORTH);
                        }
                        else
                        {
                            zone.set_terrain(pos.x + x0 + xx + 1, pos.y + y0 + 1 + h, EMPTY_VOID);
                        }
                    }
                }
                else if ((x == 2
                        && ((y == 0 && self.doors[Direction.NORTH.ordinal - 1].type != WALL)
                            || (y == 4 && self.doors[Direction.SOUTH.ordinal - 1].type != WALL)))
                    || (y == 2
                        && ((x == 0 && self.doors[Direction.WEST.ordinal - 1].type != WALL)
                            || (x == 4 && self.doors[Direction.EAST.ordinal - 1].type != WALL))))
                {
                    // Don't place anything in front of the doors
                }
                else
                {
                    IVec2 min = pos + {x0, y0};
                    IVec2 size = {w + 2, h + 2};
                    if (x == 0)
                    {
                        min.x += 1;
                        size.x -= 1;
                    }
                    else if (x == 4)
                    {
                        size.x -= 1;
                    }
                    if (y == 0)
                    {
                        min.y += 1;
                        size.y -= 1;
                    }
                    else if (y == 4)
                    {
                        size.y -= 1;
                    }
                    HotspotType hst = get_random_hotspot(rng, hotspot_mask);
                    hotspot_mask |= (1 << hst.ordinal);
                    switch (hst)
                    {
                    case EMPTY_SPOT:
                        break;
                    case TREE:
                        IVec2 p0 = get_random_pos(rng, min, size);
                        zone.set_object(...p0, OBJ_TREE);
                        if (random::next_in_range(rng, 0, 1) == 0) zone.set_object(...get_random_pos(rng, min, size, p0), OBJ_TREE);
                        if (random::next_in_range(rng, 0, 1) == 0) zone.set_object(...get_random_pos(rng, min, size, p0), OBJ_STUMP);
                    case STUMP:
                        IVec2 p0 = get_random_pos(rng, min, size);
                        zone.set_object(...p0, OBJ_STUMP);
                        if (random::next_in_range(rng, 0, 1) == 0) zone.set_object(...get_random_pos(rng, min, size, p0), OBJ_STUMP);
                    case ROCK:
                        IVec2 p0 = get_random_pos(rng, min, size);
                        zone.set_object(...p0, OBJ_ROCKS);
                        if (random::next_in_range(rng, 0, 1) == 0) zone.set_object(...get_random_pos(rng, min, size, p0), OBJ_ROCKS);
                        if (random::next_in_range(rng, 0, 1) == 0) zone.set_object(...get_random_pos(rng, min, size, p0), OBJ_SMALL_ROCKS);
                    case ORE:
                        IVec2 p0 = get_random_pos(rng, min, size);
                        zone.set_object(...p0, OBJ_ORE_ROCK1);
                        if (random::next_in_range(rng, 0, 1) == 0) zone.set_object(...get_random_pos(rng, min, size, p0), OBJ_ORE_ROCK1);
                        if (random::next_in_range(rng, 0, 1) == 0) zone.set_object(...get_random_pos(rng, min, size, p0), OBJ_ROCKS);
                    case FURNACE:
                        zone.fill_terrain(min, size, TERR_BRICKS);
                        IVec2 p0 = get_random_pos(rng, min, size); zone.set_object(...p0, OBJ_FURNACE);
                        IVec2 p1 = get_random_pos(rng, min, size, p0); zone.set_object(...p1, OBJ_ANVIL);
                        IVec2 p2 = get_random_pos(rng, min, size, p0, p1); zone.set_object(...p2, random::next_in_range(rng, 0, 1) == 0 ? OBJ_CRATE : OBJ_OPEN_CRATE);
                    case STORE_CACHE:
                        IVec2 p0 = get_random_pos(rng, min, size); zone.set_object(...p0, random::next_in_range(rng, 0, 1) == 0 ? OBJ_CRATE : OBJ_OPEN_CRATE);
                        IVec2 p1 = get_random_pos(rng, min, size, p0);
                        if (random::next_in_range(rng, 0, 1) == 0) zone.set_object(...p1, random::next_in_range(rng, 0, 1) == 0 ? OBJ_CRATE : OBJ_OPEN_CRATE);
                        IVec2 p2 = get_random_pos(rng, min, size, p0, p1);
                        if (random::next_in_range(rng, 0, 1) == 0) zone.set_object(...p2, random::next_in_range(rng, 0, 1) == 0 ? OBJ_CRATE : OBJ_OPEN_CRATE);
                    case SMALL_WARRIOR:
                        int tier = current_floor.depth / 3;
                        if (random::next_in_range(rng, 0, (current_floor.depth % 3) * 3) == 0) tier--;
                        if (random::next_in_range(rng, 0, (3 - (current_floor.depth % 3)) * 3) == 0) tier++;
                        tier = math::clamp(tier, 0, 2);
                        int count = random::next_in_range(rng, 1, 3);
                        for (int i = 0; i < count; ++i)
                        {
                            IVec2 p0 = get_random_pos(rng, min, size);
                            p0 = zone.find_nearest_empty(p0);
                            spawn_monster(zone, p0, WARRIOR_TYPES[tier]);
                        }
                    case SMALL_ARCHER:
                        int tier = current_floor.depth / 3;
                        if (random::next_in_range(rng, 0, (current_floor.depth % 3) * 3) == 0) tier--;
                        if (random::next_in_range(rng, 0, (3 - (current_floor.depth % 3)) * 3) == 0) tier++;
                        tier = math::clamp(tier, 0, 2);
                        int count = random::next_in_range(rng, 1, 3);
                        for (int i = 0; i < count; ++i)
                        {
                            IVec2 p0 = get_random_pos(rng, min, size);
                            p0 = zone.find_nearest_empty(p0);
                            spawn_monster(zone, p0, ARCHER_TYPES[tier]);
                        }
                    case SMALL_MAGE:
                        int tier = current_floor.depth / 3;
                        if (random::next_in_range(rng, 0, (current_floor.depth % 3) * 3) == 0) tier--;
                        if (random::next_in_range(rng, 0, (3 - (current_floor.depth % 3)) * 3) == 0) tier++;
                        tier = math::clamp(tier, 0, 2);
                        int count = random::next_in_range(rng, 1, 3) / 2;
                        for (int i = 0; i < count; ++i)
                        {
                            IVec2 p0 = get_random_pos(rng, min, size);
                            p0 = zone.find_nearest_empty(p0);
                            spawn_monster(zone, p0, MAGE_TYPES[tier]);
                        }
                    case MOB_GROUP:
                        int tier = current_floor.depth / 3;
                        if (random::next_in_range(rng, 0, (current_floor.depth % 3) * 3) == 0) tier--;
                        if (random::next_in_range(rng, 0, (3 - (current_floor.depth % 3)) * 3) == 0) tier++;
                        tier = math::clamp(tier, 0, 2);
                        spawn_monster(zone, zone.find_nearest_empty(get_random_pos(rng, min, size)), MAGE_TYPES[tier]);
                        spawn_monster(zone, zone.find_nearest_empty(get_random_pos(rng, min, size)), ARCHER_TYPES[tier]);
                        spawn_monster(zone, zone.find_nearest_empty(get_random_pos(rng, min, size)), WARRIOR_TYPES[tier]);
                    case BIG_GROUP:
                        int tier = current_floor.depth / 3;
                        if (random::next_in_range(rng, 0, (current_floor.depth % 3) * 3) == 0) tier--;
                        if (random::next_in_range(rng, 0, (3 - (current_floor.depth % 3)) * 3) == 0) tier++;
                        tier = math::clamp(tier, 0, 2);
                        spawn_monster(zone, zone.find_nearest_empty(get_random_pos(rng, min, size)), MAGE_TYPES[tier]);
                        spawn_monster(zone, zone.find_nearest_empty(get_random_pos(rng, min, size)), ARCHER_TYPES[tier]);
                        spawn_monster(zone, zone.find_nearest_empty(get_random_pos(rng, min, size)), ARCHER_TYPES[tier]);
                        spawn_monster(zone, zone.find_nearest_empty(get_random_pos(rng, min, size)), WARRIOR_TYPES[tier]);
                        spawn_monster(zone, zone.find_nearest_empty(get_random_pos(rng, min, size)), WARRIOR_TYPES[tier]);
                        spawn_monster(zone, zone.find_nearest_empty(get_random_pos(rng, min, size)), WARRIOR_TYPES[tier]);
                    case GRAVESITE:
                        IVec2 p0 = get_random_pos(rng, min, size);
                        zone.set_object(...p0, OBJ_GRAVE);
                        if (random::next_in_range(rng, 0, 1) == 0) zone.set_object(...get_random_pos(rng, min, size, p0), OBJ_GRAVE2);
                        if (random::next_in_range(rng, 0, 1) == 0) zone.set_object(...get_random_pos(rng, min, size, p0), OBJ_SMALL_ROCKS);
                        if (random::next_in_range(rng, 0, 1) == 0) zone.set_object(...get_random_pos(rng, min, size, p0), OBJ_STUMP);
                    }
                }
            }
        }

    case SPECIAL:
        SpecialRoomType srt = SpecialRoomType.from_ordinal(random::next_in_range(rng, 0, (int) SpecialRoomType.elements - 1));
        switch (srt)
        {
        default:
            break;
        }
    default:
        break;
    }
}

fn void Room.spawn_exit_hole(&self, Zone* zone)
{
    IVec2 pos = self.position;
    if (self.doors[Direction.NORTH.ordinal - 1].type != WALL)
    {
        // Offset to the right
        zone.set_terrain(pos.x + 12, pos.y, TERR_EXIT_WALL_L);
        zone.set_terrain(pos.x + 13, pos.y, TERR_EXIT_WALL_R);
        zone.set_terrain(pos.x + 12, pos.y + 1, TERR_EXIT_HOLE_L);
        zone.set_terrain(pos.x + 13, pos.y + 1, TERR_EXIT_HOLE_R);
    }
    else
    {
        zone.set_terrain(pos.x + 7, pos.y, TERR_EXIT_WALL_L);
        zone.set_terrain(pos.x + 8, pos.y, TERR_EXIT_WALL_R);
        zone.set_terrain(pos.x + 7, pos.y + 1, TERR_EXIT_HOLE_L);
        zone.set_terrain(pos.x + 8, pos.y + 1, TERR_EXIT_HOLE_R);
    }
}

fn Room*! find_room(IVec2 pos)
{
    IVec2 room_pos = { pos.x / 17, pos.y / 17 };
    return current_floor.rooms.get(room_pos);
}

fn Direction get_door_direction(IVec2 pos)
{
    IVec2 lpos = { pos.x % 17, pos.y % 17 };
    Direction dir;
    if (lpos.x > 2 && lpos.x < 14)
    {
        if (lpos.y == 0) {dir = NORTH;}
        else if (lpos.y == 15) {dir = SOUTH;}
        else {unreachable();}
    }
    else if (lpos.x == 0) {dir = WEST;}
    else if (lpos.x == 15) {dir = EAST;}
    else {io::printfn("Invalid door pos %d %d", ...lpos); unreachable();}
    return dir;
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

enum BossTypes : inline int
{
    GOBLIN_MAGE,
    GOBLIN_HORDE,
    BANDIT_LEADER,
    ASSASSINS,
    SLIMES,
    HAUNTED_MAGE,
    DARK_WARRIORS,
    NECROMANCER,
    RITUAL_SITE,
    ANCIENT_DAEMON,
}

BossTypes[10] boss_ordering;

fn void shuffle(random::Pcg32Random* rng, int[] arr)
{
    for (int i = arr.len - 1; i > 0; --i)
    {
        int j = random::next_in_range(rng, 0, i);
        if (i == j) continue;
        int tmp = arr[i];
        arr[i] = arr[j];
        arr[j] = tmp;
    }
}

fn void generate_whole_dungeon_stuff(random::Pcg32Random* rng)
{
    int[] t0 = {0, 1, 2};
    shuffle(rng, t0);
    boss_ordering[0] = BossTypes.from_ordinal(t0[0]); boss_ordering[1] = BossTypes.from_ordinal(t0[1]); boss_ordering[2] = BossTypes.from_ordinal(t0[2]);
    int[] t1 = {3, 4, 5};
    shuffle(rng, t1);
    boss_ordering[3] = BossTypes.from_ordinal(t1[0]); boss_ordering[4] = BossTypes.from_ordinal(t1[1]); boss_ordering[5] = BossTypes.from_ordinal(t1[2]);
    int[] t2 = {6, 7, 8};
    shuffle(rng, t2);
    boss_ordering[6] = BossTypes.from_ordinal(t2[0]); boss_ordering[7] = BossTypes.from_ordinal(t2[1]); boss_ordering[8] = BossTypes.from_ordinal(t2[2]);
    boss_ordering[9] = ANCIENT_DAEMON;
    
    int total_weight = 0;
    for (int i = 0; i < HotspotType.elements; ++i)
    {
        total_weight += HotspotType.from_ordinal(i).weight;
    }
    hotspot_total_weight = total_weight;
}