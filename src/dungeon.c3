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
    SECRET,
    SKILL_CHECK,
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

enum HotspotType : (int weight)
{
    EMPTY_SPOT = 40,
    TREE = 5,
    STUMP = 3,
    ROCK = 3,
    ORE = 5,
    FURNACE = 2,
    ANVIL = 2,
    STORE_CACHE = 8,
    SMALL_MOB = 25,
    MOB_GROUP = 20,
    GRAVESITE = 5,
}

int hotspot_total_weight;

fn HotspotType get_random_hotspot(random::Pcg32Random* rng)
{
    int r = random::next_in_range(rng, 0, hotspot_total_weight - 1);
    for (int i = 0; i < HotspotType.elements; ++i)
    {
        r -= HotspotType.from_ordinal(i).weight;
        if (r < 0) return HotspotType.from_ordinal(i);
    }
    unreachable();
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
        switch (d.direction)
        {
        case NORTH:
            zone.set_terrain(pos.x + 7, pos.y, DOOR_NORTH_L, colors::BLACK, false);
            zone.set_terrain(pos.x + 8, pos.y, DOOR_NORTH_R, colors::BLACK, false);
        case EAST:
            zone.set_terrain(pos.x + 15, pos.y + 7, DOOR_EAST_U, colors::BLACK, false);
            zone.set_terrain(pos.x + 15, pos.y + 8, DOOR_EAST_L, colors::BLACK, false);
        case SOUTH:
            zone.set_terrain(pos.x + 7, pos.y + 15, DOOR_SOUTH_L, colors::BLACK, false);
            zone.set_terrain(pos.x + 8, pos.y + 15, DOOR_SOUTH_R, colors::BLACK, false);
        case WEST:
            zone.set_terrain(pos.x, pos.y + 7, DOOR_WEST_U, colors::BLACK, false);
            zone.set_terrain(pos.x, pos.y + 8, DOOR_WEST_L, colors::BLACK, false);
        default:
            unreachable();
        }
    }
    if (self.type == EMPTY)
    {
        self.type = random::next_in_range(rng, 0, 5) == 0 ? SPECIAL : STANDARD;
    }

    switch (self.type)
    {
    case STARTING:
        zone.set_terrain(pos.x + 4, pos.y + 4, TRADER, colors::BLACK, false);
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
                        zone.set_terrain(pos.x + x0, pos.y + y0, PILLAR, colors::BLACK, false);
                    }
                    else if (!up && !left && upleft)
                    {
                        zone.set_terrain(pos.x + x0, pos.y + y0, WALL_SE, colors::BLACK, false);
                    }
                    else if (y == 0 && left)
                    {
                        zone.set_terrain(pos.x + x0, pos.y + y0, WALL_NE, colors::BLACK, false);
                    }
                    else if (x == 0 && up)
                    {
                        zone.set_terrain(pos.x + x0, pos.y + y0, WALL_SW, colors::BLACK, false);
                    }
                    else if (left && !up)
                    {
                        zone.set_terrain(pos.x + x0, pos.y + y0, WALL_EAST, colors::BLACK, false);
                    }
                    else if (up && !left)
                    {
                        zone.set_terrain(pos.x + x0, pos.y + y0, WALL_SOUTH, colors::BLACK, false);
                    }
                    else
                    {
                        zone.set_terrain(pos.x + x0, pos.y + y0, EMPTY_LOOK, colors::BLACK, false);
                    }

                    if (up && right)
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0, PILLAR, colors::BLACK, false);
                    }
                    else if (!up && !right && upright)
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0, WALL_SW, colors::BLACK, false);
                    }
                    else if (y == 0 && right)
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0, WALL_NW, colors::BLACK, false);
                    }
                    else if (x == 4 && up)
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0, WALL_SE, colors::BLACK, false);
                    }
                    else if (right && !up)
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0, WALL_WEST, colors::BLACK, false);
                    }
                    else if (up && !right)
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0, WALL_SOUTH, colors::BLACK, false);
                    }
                    else
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0, EMPTY_LOOK, colors::BLACK, false);
                    }

                    if (down && left)
                    {
                        zone.set_terrain(pos.x + x0, pos.y + y0 + 1 + h, PILLAR, colors::BLACK, false);
                    }
                    else if (!down && !left && downleft)
                    {
                        zone.set_terrain(pos.x + x0, pos.y + y0 + 1 + h, WALL_NE, colors::BLACK, false);
                    }
                    else if (y == 4 && left)
                    {
                        zone.set_terrain(pos.x + x0, pos.y + y0 + 1 + h, WALL_SE, colors::BLACK, false);
                    }
                    else if (x == 0 && down)
                    {
                        zone.set_terrain(pos.x + x0, pos.y + y0 + 1 + h, WALL_NW, colors::BLACK, false);
                    }
                    else if (left && !down)
                    {
                        zone.set_terrain(pos.x + x0, pos.y + y0 + 1 + h, WALL_EAST, colors::BLACK, false);
                    }
                    else if (down && !left)
                    {
                        zone.set_terrain(pos.x + x0, pos.y + y0 + 1 + h, WALL_NORTH, colors::BLACK, false);
                    }
                    else
                    {
                        zone.set_terrain(pos.x + x0, pos.y + y0 + 1 + h, EMPTY_LOOK, colors::BLACK, false);
                    }

                    if (down && right)
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0 + 1 + h, PILLAR, colors::BLACK, false);
                    }
                    else if (!down && !right && downright)
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0 + 1 + h, WALL_NW, colors::BLACK, false);
                    }
                    else if (y == 4 && right)
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0 + 1 + h, WALL_SW, colors::BLACK, false);
                    }
                    else if (x == 4 && down)
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0 + 1 + h, WALL_NE, colors::BLACK, false);
                    }
                    else if (right && !down)
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0 + 1 + h, WALL_WEST, colors::BLACK, false);
                    }
                    else if (down && !right)
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0 + 1 + h, WALL_NORTH, colors::BLACK, false);
                    }
                    else
                    {
                        zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0 + 1 + h, EMPTY_LOOK, colors::BLACK, false);
                    }


                    for (int yy = 0; yy < h; ++yy)
                    {
                        for (int xx = 0; xx < w; ++xx)
                        {
                            zone.set_terrain(pos.x + x0 + xx + 1, pos.y + y0 + yy + 1, EMPTY_LOOK, colors::BLACK, false);
                        }
                        if (left)
                        {
                            zone.set_terrain(pos.x + x0, pos.y + y0 + yy + 1, WALL_EAST, colors::BLACK, false);
                        }
                        else
                        {
                            zone.set_terrain(pos.x + x0, pos.y + y0 + yy + 1, EMPTY_LOOK, colors::BLACK, false);
                        }
                        if (right)
                        {
                            zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0 + yy + 1, WALL_WEST, colors::BLACK, false);
                        }
                        else
                        {
                            zone.set_terrain(pos.x + x0 + 1 + w, pos.y + y0 + yy + 1, EMPTY_LOOK, colors::BLACK, false);
                        }
                    }
                    for (int xx = 0; xx < w; ++xx)
                    {
                        if (up)
                        {
                            zone.set_terrain(pos.x + x0 + xx + 1, pos.y + y0, WALL_SOUTH, colors::BLACK, false);
                        }
                        else
                        {
                            zone.set_terrain(pos.x + x0 + xx + 1, pos.y + y0, EMPTY_LOOK, colors::BLACK, false);
                        }
                        if (down)
                        {
                            zone.set_terrain(pos.x + x0 + xx + 1, pos.y + y0 + 1 + h, WALL_NORTH, colors::BLACK, false);
                        }
                        else
                        {
                            zone.set_terrain(pos.x + x0 + xx + 1, pos.y + y0 + 1 + h, EMPTY_LOOK, colors::BLACK, false);
                        }
                    }
                }
                else if ((x == 2 && (y == 0 || y == 4)) || (y == 2 && (x == 0 || x == 4)))
                {

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
                    HotspotType hst = get_random_hotspot(rng);
                    switch (hst)
                    {
                    case EMPTY_SPOT:
                        break;
                    case TREE:
                        IVec2 p0 = get_random_pos(rng, min, size);
                        zone.set_object(...p0, TREE, false);
                        if (random::next_in_range(rng, 0, 1) == 0) zone.set_object(...get_random_pos(rng, min, size, p0), TREE, false);
                        if (random::next_in_range(rng, 0, 1) == 0) zone.set_object(...get_random_pos(rng, min, size, p0), STUMP, false);
                    case STUMP:
                        IVec2 p0 = get_random_pos(rng, min, size);
                        zone.set_object(...p0, STUMP, false);
                        if (random::next_in_range(rng, 0, 1) == 0) zone.set_object(...get_random_pos(rng, min, size, p0), STUMP, false);
                    case ROCK:
                        IVec2 p0 = get_random_pos(rng, min, size);
                        zone.set_object(...p0, ROCKS, false);
                        if (random::next_in_range(rng, 0, 1) == 0) zone.set_object(...get_random_pos(rng, min, size, p0), ROCKS, false);
                        if (random::next_in_range(rng, 0, 1) == 0) zone.set_object(...get_random_pos(rng, min, size, p0), SMALL_ROCKS, false);
                    case ORE:
                        IVec2 p0 = get_random_pos(rng, min, size);
                        zone.set_object(...p0, ORE1, false);
                        if (random::next_in_range(rng, 0, 1) == 0) zone.set_object(...get_random_pos(rng, min, size, p0), ORE1, false);
                        if (random::next_in_range(rng, 0, 1) == 0) zone.set_object(...get_random_pos(rng, min, size, p0), ROCKS, false);
                    case FURNACE:
                        IVec2 p0 = get_random_pos(rng, min, {size.x, 1});
                        zone.set_object(...p0, FURNACE, false);
                        if (random::next_in_range(rng, 0, 1) == 0) zone.set_object(...get_random_pos(rng, min, size, p0, pos + {x0, y0 + 1}, pos + {x0 + 1, y0 + 1}, pos + {x0 + 2, y0 + 1}), CRATE, false);
                        if (random::next_in_range(rng, 0, 1) == 0) zone.set_object(...get_random_pos(rng, min, size, p0, pos + {x0, y0 + 1}, pos + {x0 + 1, y0 + 1}, pos + {x0 + 2, y0 + 1}), OPEN_CRATE, false);
                    case ANVIL:
                        IVec2 p0 = get_random_pos(rng, min, size);
                        zone.set_object(...p0, ANVIL, false);
                    case STORE_CACHE:
                        IVec2 p0 = get_random_pos(rng, min, size);
                        zone.set_object(...p0, CRATE, false);
                    case SMALL_MOB:
                        break;
                    case MOB_GROUP:
                        break;
                    case GRAVESITE:
                        IVec2 p0 = get_random_pos(rng, min, size);
                        zone.set_object(...p0, GRAVE, false);
                        if (random::next_in_range(rng, 0, 1) == 0) zone.set_object(...get_random_pos(rng, min, size, p0), GRAVE2, false);
                        if (random::next_in_range(rng, 0, 1) == 0) zone.set_object(...get_random_pos(rng, min, size, p0), SMALL_ROCKS, false);
                        if (random::next_in_range(rng, 0, 1) == 0) zone.set_object(...get_random_pos(rng, min, size, p0), STUMP, false);
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

    bool debug_notes = false;
    if (debug_notes)
    {
        zone.set_terrain(pos.x, pos.y + 16, {'D', colors::WHITE, -1}, colors::BLACK, false);
        zone.set_terrain(pos.x + 1, pos.y + 16, {':', colors::WHITE, -1}, colors::BLACK, false);
        zone.set_terrain(pos.x + 2, pos.y + 16, {(char) (self.distance_from_start / 10) + '0', colors::WHITE, -1}, colors::BLACK, false);
        zone.set_terrain(pos.x + 3, pos.y + 16, {(char) (self.distance_from_start % 10) + '0', colors::WHITE, -1}, colors::BLACK, false);

        switch (self.type)
        {
        case STARTING:
            zone.set_terrain(pos.x + 15, pos.y + 16, {'S', colors::WHITE, -1}, colors::BLACK, false);
        case BOSS:
            zone.set_terrain(pos.x + 15, pos.y + 16, {'B', colors::WHITE, -1}, colors::BLACK, false);
        case STANDARD:
            zone.set_terrain(pos.x + 15, pos.y + 16, {'R', colors::WHITE, -1}, colors::BLACK, false);
        case SPECIAL:
            zone.set_terrain(pos.x + 15, pos.y + 16, {'P', colors::WHITE, -1}, colors::BLACK, false);
        default:
            zone.set_terrain(pos.x + 15, pos.y + 16, {'?', colors::WHITE, -1}, colors::BLACK, false);
        }
    }
}

fn void Room.spawn_exit_hole(&self, Zone* zone)
{
    IVec2 pos = self.position;
    if (self.doors[Direction.NORTH.ordinal - 1].type != WALL)
    {
        // Offset to the right
        zone.set_terrain(pos.x + 12, pos.y, EXIT_WALL_L, colors::BLACK, false);
        zone.set_terrain(pos.x + 13, pos.y, EXIT_WALL_R, colors::BLACK, false);
        zone.set_terrain(pos.x + 12, pos.y + 1, EXIT_HOLE_L, colors::BLACK, false);
        zone.set_terrain(pos.x + 13, pos.y + 1, EXIT_HOLE_R, colors::BLACK, false);
    }
    else
    {
        zone.set_terrain(pos.x + 7, pos.y, EXIT_WALL_L, colors::BLACK, false);
        zone.set_terrain(pos.x + 8, pos.y, EXIT_WALL_R, colors::BLACK, false);
        zone.set_terrain(pos.x + 7, pos.y + 1, EXIT_HOLE_L, colors::BLACK, false);
        zone.set_terrain(pos.x + 8, pos.y + 1, EXIT_HOLE_R, colors::BLACK, false);
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