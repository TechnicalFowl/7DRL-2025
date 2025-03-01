module dg;

import std::io;
import std::math;
import raylib5::rl;

struct Player (Entity)
{
    inline EntityCommon entity;
    uint flags;

    Navigator nav;
    float nav_delay;

    VisibilityTracker vis;
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
}

fn void Player.free(&self) @dynamic
{
    self.entity.free();
    self.nav.free();
    self.vis.free();
}

fn Action Player.moveOrInteract(&self, IVec2 dir)
{
    ZoneCell* cell = self.get_zone().get_cell(...(self.get_position() + dir));
    if (cell.terrain.passable)
    {
        return do_move(dir);
    }
    else
    {
        return do_interact(dir);
    }
}

fn Action Player.next_action(&self, double max_time) @dynamic
{
    if (is_key_pressed(REVEAL_MAP, false))
    {
        self.vis.explored.clear_to(true);
    }

    if (rl::isMouseButtonPressed(rl::MouseButton.LEFT))
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

        bool is_shift = is_key_down(DIAGONAL_UP);
        bool is_ctrl = is_key_down(DIAGONAL_DOWN);
        if (is_key_pressed(MOVE_UP))
        {
            if (is_shift || is_ctrl)
            {
                log("Invalid move.");
            }
            else
            {
                return self.moveOrInteract({0, -1});
            }
        }
        if (is_key_pressed(MOVE_DOWN))
        {
            if (is_shift || is_ctrl)
            {
                log("Invalid move.");
            }
            else
            {
                return self.moveOrInteract({0, 1});
            }
        }
        if (is_key_pressed(MOVE_LEFT))
        {
            if (is_shift && is_ctrl)
            {
                log("Invalid move.");
            }
            else if (is_shift)
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
            if (is_shift && is_ctrl)
            {
                log("Invalid move.");
            }
            else if (is_shift)
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
            if (next_cell.terrain.passable)
            {
                return do_move(next_move);
            }
            else if (next_cell.terrain.look.glyph == '+')
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

    ZoneCell* cell = entity.get_zone().get_cell(...new_pos);
    if (cell.terrain.look.glyph == '+')
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
        Player* player = (Player*) entity;
        player.explore(next_room.position, next_room.size);
    }
    else if (cell.terrain.look.glyph == '>')
    {
        want_exit_floor = true;
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
