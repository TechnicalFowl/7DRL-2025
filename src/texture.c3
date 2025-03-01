module dg;

import std::collections::map;
import std::io;

import raylib5::rl;

struct Font
{
    String path;
    int width;
    int height;
    rl::Texture2D texture;
}

String font_directory;
HashMap(<String, Font*>) font_cache;

fn void set_font_directory(String path)
{
    font_directory = path;
}

<*
@require size[0] > 0, "Font width must be greater than zero"
@require size[1] > 0, "Font height must be greater than zero"
*>
fn Font*! get_font(String font_name, IVec2 size)
{
    String path = string::new_format("%s/%s_%dx%d.png", font_directory, font_name, size[0], size[1]);

    if (try Font* font = font_cache.get(path))
    {
        path.free();
        return font;
    }

    Font* result = mem::new(Font);
    result.path = path;
    rl::traceLog(rl::TraceLogLevel.INFO, "C3RL: Loading font %s", result.path);
    result.width = size[0];
    result.height = size[1];
    result.texture = rl::loadTexture(result.path.zstr_tcopy());
    font_cache.set(path, result);
    return result;
}
