module dg;

import std::io;
import std::math;

def IVec2 = int[<2>];
def IVec3 = int[<3>];
def IVec4 = int[<4>];

fn uint IVec2.hash(self) => ((uint) self.x) * 2654435761u + ((uint) self.y);
fn uint IVec3.hash(self) => (((uint) self.x) * 2654435761u + ((uint) self.y)) * 2654435761u + ((uint) self.z);
fn uint IVec4.hash(self) => ((((uint) self.x) * 2654435761u + ((uint) self.y)) * 2654435761u + ((uint) self.z)) * 2654435761u + ((uint) self.y);

fn IVec2 IVec2.sign(self) => { math::sign(self.x), math::sign(self.y) };
fn int IVec2.distance(self, IVec2 other) => math::abs(self - other).sum();
fn int IVec2.dot(self, IVec2 other) => self.x * other.x + self.y * other.y;
fn double IVec2.length(self) => math::sqrt(self.dot(self));
fn int IVec2.length_sq(self) => self.dot(self);
fn double IVec2.fdistance(self, IVec2 other) => (self - other).length();
fn int IVec2.min_element(self) => math::min(self.x, self.y);
fn int IVec2.max_element(self) => math::max(self.x, self.y);
fn IVec2 IVec2.min(self, IVec2 other) => { math::min(self.x, other.x), math::min(self.y, other.y) };
fn IVec2 IVec2.max(self, IVec2 other) => { math::max(self.x, other.x), math::max(self.y, other.y) };
fn IVec2 IVec2.clamp(self, IVec2 min, IVec2 max) => self.max(min).min(max);

fn IVec2 ivec2_clamp(IVec2 value, IVec2 min, IVec2 max) => value.max(min).min(max);

fn float ivec2_angle(IVec2 a, IVec2 b)
{
    float dx = (float) b.x - a.x;
    float dy = (float) b.y - a.y;
    return math::atan2(dy, dx);
}

struct BitBoard
{
    usz width;
    usz height;
    ulong* data;
}

<*
@require w > 0: "Width must be greater than zero"
@require h > 0: "Height must be greater than zero"
*>
fn void BitBoard.new_init(&self, usz w, usz h)
{
    self.width = w;
    self.height = h;
    self.data = mem::new_array(ulong, ((w * h) - 1) / 64 + 1);
}

fn void BitBoard.free(&self)
{
    mem::free(self.data);
}

fn void BitBoard.clear(&self)
{
    mem::set(self.data, 0, (((self.width * self.height) - 1) / 64 + 1) * 8);
}

fn void BitBoard.clear_to(&self, bool value)
{
    char fill = value ? 0xFF : 0x00;
    mem::set(self.data, fill, (((self.width * self.height) - 1) / 64 + 1) * 8);
}

<*
@require w > 0: "Width must be greater than zero"
@require h > 0: "Height must be greater than zero"
*>
fn void BitBoard.resize(&self, usz w, usz h)
{
    mem::free(self.data);
    self.width = w;
    self.height = h;
    self.data = mem::new_array(ulong, ((w * h) - 1) / 64 + 1);
}

<*
@require pos[0] >= 0, pos[0] < self.width: "Invalid position x"
@require pos[1] >= 0, pos[1] < self.height: "Invalid position y"
*>
fn bool BitBoard.get(&self, IVec2 pos)
{
    usz idx = pos[1] * self.width + pos[0];
    usz index = idx / 64;
    usz bit = idx % 64;
    return (self.data[index] & (1ul << bit)) != 0;
}

<*
@require pos[0] >= 0, pos[0] < self.width: "Invalid position x"
@require pos[1] >= 0, pos[1] < self.height: "Invalid position y"
*>
fn void BitBoard.set(&self, IVec2 pos, bool value)
{
    usz idx = pos[1] * self.width + pos[0];
    usz index = idx / 64;
    usz bit = idx % 64;
    if (value)
    {
        self.data[index] |= 1ul << bit;
    }
    else
    {
        self.data[index] &= ~(1ul << bit);
    }
}

extern fn bool isDebuggerPresent() @extern("IsDebuggerPresent") @if(env::WIN32);

fn void waitForDebugger()
{
$if env::WIN32:
    while (!isDebuggerPresent())
    {
        // Wait for the debugger to attach
    }
$else
    int wait_for_debugger = 1;
    while (@volatile_load(wait_for_debugger))
    {
        // Wait for the debugger to attach
    }
$endif
}

struct ExceptionRecord
{
    uint code;
    uint flags;
    void* record;
    void* address;
}

def UnhandledExceptionFilter = fn int (ExceptionRecord* exception_info);
UnhandledExceptionFilter g_previous_filter;
PanicFn g_previous_panic;
bool g_has_panicked;
extern fn UnhandledExceptionFilter setUnhandledExceptionFilter(UnhandledExceptionFilter filter) @extern("SetUnhandledExceptionFilter") @if(env::WIN32);

fn int exceptionHandler(ExceptionRecord* exception_info)
{
    if (!g_has_panicked)
    {
        @stack_mem(512; Allocator allocator)
        {
            DString s;
            s.new_init(allocator: allocator);
            s.appendf("Unhandled exception (%X)", exception_info.code);
            builtin::print_backtrace(s.str_view(), 8);
        };
    }
    if (g_previous_filter)
    {
        return g_previous_filter(exception_info);
    }
    return 1;
}

fn void panic_tracker(String message, String file, String function, uint line)
{
    g_has_panicked = true;
    g_previous_panic(message, file, function, line);
}

fn void initExceptionHandler() @init
{
$if env::WIN32:
    g_previous_filter = setUnhandledExceptionFilter(&exceptionHandler);
    g_previous_panic = builtin::panic;
    builtin::panic = &panic_tracker;
$endif
}