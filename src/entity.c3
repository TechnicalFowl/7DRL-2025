module dg;

import std::collections::list;
import std::collections::map;
import std::io;
import std::math;

import raylib5::rl;

interface PostLoadEvent
{
    fn void on_post_load() @optional;
}

macro @call_event($Type, #func, any e, ...)
{
    $Type h = ($Type) e;
    if (&h.#func) h.#func($vasplat);
}

interface Action
{
    fn double duration();
    fn void apply(Entity ent);
}

struct WaitAction (Action)
{
    double time;
}
fn double WaitAction.duration(&self) @dynamic => self.time;
fn void WaitAction.apply(&self, Entity ent) @dynamic
{
    ent.give_idle_time(self.time);
}

fn WaitAction* do_wait(double time)
{
    WaitAction* wait = mem::temp_alloc(WaitAction);
    wait.time = time;
    return wait;
}

struct MoveAction (Action)
{
    IVec2 move;
}
fn double MoveAction.duration(&self) @dynamic => 1.0;

fn void MoveAction.apply(&self, Entity entity) @dynamic
{
    IVec2 new_pos = entity.get_position() + self.move;

    ZoneCell* cell = entity.get_zone().get_cell(...new_pos);
    if (cell.isPassable())
    {
        entity.set_position(new_pos);
    }
}

fn MoveAction* do_move(IVec2 move)
{
    MoveAction* move_action = mem::temp_alloc(MoveAction);
    move_action.move = move;
    return move_action;
}

interface Entity
{
    fn void free();

    fn Zone* get_zone();
    fn String get_name();
    fn IVec2 get_position();
    fn void set_position(IVec2 pos);
    fn Appearance get_look();
    fn double get_idle_time();
    fn void give_idle_time(double time);
    fn bool is_dead();

    fn Action next_action(double max_time);

    fn void onUpdate(double delta_time);
}

struct EntityCommon (Entity)
{
    Zone* zone;
    String name;
    IVec2 position;
    Appearance[3] look;

    double idle_time;
}

fn Zone* EntityCommon.get_zone(&self) @dynamic => self.zone;
fn String EntityCommon.get_name(&self) @dynamic => self.name;
fn IVec2 EntityCommon.get_position(&self) @dynamic => self.position;
fn void EntityCommon.set_position(&self, IVec2 pos) @dynamic
{
    ZoneCell* cell = self.zone.get_cell(...self.position);
    Entity this_ent;
    foreach (ent: cell.entities)
    {
        if (ent.ptr == self)
        {
            this_ent = ent;
            break;
        }
    }
    cell.entities.remove_first_item(this_ent);
    self.position = pos;
    ZoneCell* new_cell = self.zone.get_cell(...self.position);
    new_cell.entities.push(this_ent);
}

fn Appearance EntityCommon.get_look(&self) @dynamic => self.look[0];
fn double EntityCommon.get_idle_time(&self) @dynamic => self.idle_time;
fn void EntityCommon.give_idle_time(&self, double time) @dynamic
{
    self.idle_time += time;
}
fn bool EntityCommon.is_dead(&self) @dynamic => false;

fn void EntityCommon.new_init(&self, Zone* z, String n, IVec2 p, Appearance idle1, Appearance idle2, Appearance point)
{
    self.zone = z;
    self.name = n;
    self.position = p;
    self.look = { idle1, idle2, point };
}

fn void EntityCommon.free(&self) @dynamic
{
}

fn Action EntityCommon.next_action(&self, double max_time) @dynamic
{
    if (max_time <= 0) return null;
    WaitAction* wait = mem::temp_alloc(WaitAction);
    wait.time = max_time - self.idle_time;
    return wait;
}

fn void EntityCommon.onUpdate(&self, double duration) @dynamic
{
}

struct Navigator
{
    List(<IVec2>) path;
}

fn void Navigator.new_init(&self)
{
    self.path.new_init();
}
fn void Navigator.free(&self)
{
    self.path.free();
}

fn bool Navigator.is_idle(&self) => self.path.is_empty();

fn void Navigator.path_to(&self, Zone* zone, IVec2 start, IVec2 end)
{
    self.path.clear();
    zone.path(start, end, &self.path, diagonal_moves: true, reverse: true);
}

fn IVec2 Navigator.next_point(&self)
{
    assert(!self.path.is_empty(), "No path to follow");
    return self.path.pop()!!;
}

fn void Navigator.abort(&self)
{
    self.path.clear();
}

interface EntityVisibility
{
    fn VisibilityTracker* get_visibility();
}

struct VisibilityTracker
{
    Zone* zone;
    BitBoard visible;
    BitBoard explored;
}

fn void VisibilityTracker.new_init(&self, Zone* z)
{
    self.zone = z;
    self.visible.new_init(z.width, z.height);
    self.explored.new_init(z.width, z.height);
}

fn void VisibilityTracker.free(&self)
{
    self.visible.free();
    self.explored.free();
}

struct VisibilityTrackerCB
{
    VisibilityTracker* vis;
    int step;
    int range;
    int pen_depth;
}

fn bool VisibilityTrackerCB.line_cb(&self, IVec2 pos) @private
{
    self.vis.set_visible(pos, true);
    self.vis.set_explored(pos, true);
    if (self.step++ >= self.range) return false;
    if (!self.vis.zone.get_cell(...pos).isPassable())
    {
        self.pen_depth++;
        if (self.pen_depth > 1) return false;
        return true;
    }
    self.pen_depth = 0;
    return true;
}

fn void VisibilityTracker.sweep_line(&self, IVec2 from, IVec2 to)
{
    self.set_visible(from, true);
    self.set_explored(from, true);
    VisibilityTrackerCB cb_data = { self, 0, ivec2_distance(from, to), 0 };
    line(from, to, (LineCallback) &VisibilityTrackerCB.line_cb, &cb_data);
}

fn void VisibilityTracker.sweep(&self, IVec2 pos, int range)
{
    self.visible.clear();
    self.set_visible(pos, true);
    self.set_explored(pos, true);
    
    VisibilityTrackerCB cb_data = { self, 0, range, 0 };

    // Box sweep
    for (int i = -range; i <= range; ++i)
    {
        cb_data.step = 0; cb_data.pen_depth = 0; cb_data.range = range + math::abs(range) / 2;
        line(pos, ivec2_clamp(pos + {i, -range}, {0, 0}, {self.zone.width - 1, self.zone.height - 1}), (LineCallback) &VisibilityTrackerCB.line_cb, &cb_data);
        cb_data.step = 0; cb_data.pen_depth = 0; cb_data.range = range + math::abs(range) / 2;
        line(pos, ivec2_clamp(pos + {i, range}, {0, 0}, {self.zone.width - 1, self.zone.height - 1}), (LineCallback) &VisibilityTrackerCB.line_cb, &cb_data);
        cb_data.step = 0; cb_data.pen_depth = 0; cb_data.range = range + math::abs(range) / 2;
        line(pos, ivec2_clamp(pos + {-range, i}, {0, 0}, {self.zone.width - 1, self.zone.height - 1}), (LineCallback) &VisibilityTrackerCB.line_cb, &cb_data);
        cb_data.step = 0; cb_data.pen_depth = 0; cb_data.range = range + math::abs(range) / 2;
        line(pos, ivec2_clamp(pos + {range, i}, {0, 0}, {self.zone.width - 1, self.zone.height - 1}), (LineCallback) &VisibilityTrackerCB.line_cb, &cb_data);
    }
}

fn void VisibilityTracker.clear(&self)
{
    self.visible.clear();
    self.explored.clear();
}

fn bool VisibilityTracker.is_visible(&self, IVec2 pos)
{
    return self.visible.get(pos);
}

fn bool VisibilityTracker.is_explored(&self, IVec2 pos)
{
    return self.explored.get(pos);
}

fn void VisibilityTracker.set_visible(&self, IVec2 pos, bool visible)
{
    self.visible.set(pos, visible);
}

fn void VisibilityTracker.set_explored(&self, IVec2 pos, bool visible)
{
    self.explored.set(pos, visible);
}
