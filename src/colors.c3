module dg;

import std::math;

import raylib5::rl;

fn Color Color.add(&self, Color other)
{
    Color result;
    result.r = (char) math::min(self.r + other.r, 255u);
    result.g = (char) math::min(self.g + other.g, 255u);
    result.b = (char) math::min(self.b + other.b, 255u);
    result.a = self.a;
    return result;
}

fn Color Color.sub(&self, Color other)
{
    Color result;
    result.r = (char) math::max(self.r - other.r, 0u);
    result.g = (char) math::max(self.g - other.g, 0u);
    result.b = (char) math::max(self.b - other.b, 0u);
    result.a = self.a;
    return result;
}

fn Color Color.mix(&self, Color other)
{
    Color result;
    float a = other.a / 255.0f;
    result.r = (char) math::clamp(math::floor(self.r * (1 - a) + other.r * a), 0, 255);
    result.g = (char) math::clamp(math::floor(self.g * (1 - a) + other.g * a), 0, 255);
    result.b = (char) math::clamp(math::floor(self.b * (1 - a) + other.b * a), 0, 255);
    result.a = (char) math::clamp(math::floor(((self.a / 255.0f) * a) * 255), 0, 255);
    return result;
}

fn bool Color.equals(&self, Color other)
{
    return self.r == other.r && self.g == other.g && self.b == other.b && self.a == other.a;
}

fn float[<3>] Color.to_hsv(&self)
{
    float r = self.r / 255.0f;
    float g = self.g / 255.0f;
    float b = self.b / 255.0f;

    float cmax = math::max(r, math::max(g, b));
    float cmin = math::min(r, math::min(g, b));
    float delta = cmax - cmin;

    float h = 0.0f;
    if (delta != 0.0f)
    {
        if (cmax == r)
        {
            h = 60.0f * (((g - b) / delta) % 6.0f);
        }
        else if (cmax == g)
        {
            h = 60.0f * ((b - r) / delta + 2.0f);
        }
        else if (cmax == b)
        {
            h = 60.0f * ((r - g) / delta + 4.0f);
        }
    }

    float s = 0.0f;
    if (cmax != 0.0f)
    {
        s = delta / cmax;
    }

    float v = cmax;

    return {h, s, v};
}

fn Color color_from_hsv(float[<3>] hsv)
{
    float h = hsv[0];
    float s = hsv[1];
    float v = hsv[2];

    float c = v * s;
    float hprime = (h / 60.0f) % 6.0f;
    float x = c * (1.0f - math::abs((hprime % 2.0f) - 1.0f));
    float m = v - c;

    float r = 0.0f;
    float g = 0.0f;
    float b = 0.0f;

    switch (true)
    {
        case hprime >= 0 && hprime < 1:
            r = c;
            g = x;
        case hprime >= 1 && hprime < 2:
            r = x;
            g = c;
        case hprime >= 2 && hprime < 3:
            g = c;
            b = x;
        case hprime >= 3 && hprime < 4:
            g = x;
            b = c;
        case hprime >= 4 && hprime < 5:
            r = x;
            b = c;
        case hprime >= 5 && hprime < 6:
            r = c;
            b = x;
    }

    r += m;
    g += m;
    b += m;

    return { (char) math::floor(r * 255.0f), (char) math::floor(g * 255.0f), (char) math::floor(b * 255.0f), 255 };
}

fn Color Color.grayscale(&self)
{
    char gray = (char) math::floor(0.299f * self.r + 0.587f * self.g + 0.114f * self.b);
    return { gray, gray, gray, self.a };
}

fn Color Color.darken(&self, float pct)
{
    return {
        (char) math::clamp(math::floor(self.r * (1.0f - pct)), 0, 255),
        (char) math::clamp(math::floor(self.g * (1.0f - pct)), 0, 255),
        (char) math::clamp(math::floor(self.b * (1.0f - pct)), 0, 255),
        self.a
    };
}

fn Color Color.randomize(&self, Random rng, float pct)
{
    return {
        (char) math::clamp(math::floor(self.r * (1.0f - (random::next_double(rng) * 2 - 1) * pct)), 0, 255),
        (char) math::clamp(math::floor(self.g * (1.0f - (random::next_double(rng) * 2 - 1) * pct)), 0, 255),
        (char) math::clamp(math::floor(self.b * (1.0f - (random::next_double(rng) * 2 - 1) * pct)), 0, 255),
        self.a
    };
}

module dg::colors;

import std::math::random;
import raylib5::rl;

fn Color random_color(Random rng)
{
    return {
        (char) random::next_in_range(rng, 0, 255),
        (char) random::next_in_range(rng, 0, 255),
        (char) random::next_in_range(rng, 0, 255),
        255
    };
}

const Color BLANK = {0, 0, 0, 0};
const Color ALICE_BLUE = {240, 248, 255, 255};
const Color ANTIQUE_WHITE = {250, 235, 215, 255};
const Color AQUA = {0, 255, 255, 255};
const Color AQUAMARINE = {127, 255, 212, 255};
const Color BEIGE = {245, 245, 220, 255};
const Color BLANCHED_ALMOND = {255, 235, 205, 255};
const Color BLUE_VIOLET = {138, 43, 226, 255};
const Color BROWN = {142, 83, 0, 255};
const Color DARK_BROWN = {112, 53, 0, 255};
const Color BURLY_WOOD = {222, 184, 135, 255};
const Color CADET_BLUE = {95, 158, 160, 255};
const Color CHARTREUSE = {127, 255, 0, 255};
const Color CHOCOLATE = {210, 105, 20, 255};
const Color CORAL = {255, 127, 80, 255};
const Color CORNFLOWER_BLUE = {100, 149, 237, 255};
const Color CORNSILK = {255, 248, 220, 255};
const Color CRIMSON = {220, 20, 60, 255};
const Color DARK_BLUE = {0, 0, 139, 255};
const Color DARK_CYAN = {0, 139, 139, 255};
const Color DARK_GOLDEN_ROD = {184, 134, 11, 255};
const Color DARK_KHAKI = {189, 183, 107, 255};
const Color DARK_MAGENTA = {139, 0, 139, 255};
const Color DARK_OLIVE_GREEN = {85, 107, 47, 255};
const Color DARK_ORAGE = {255, 140, 0, 255};
const Color DARK_ORCHID = {255, 140, 0, 255};
const Color DARK_SALMON = {233, 150, 122, 255};
const Color DARK_SEA_GREEN = {143, 188, 143, 255};
const Color DARK_SLATE_BLUE = {72, 61, 139, 255};
const Color DARK_SLATE_GRAY = {47, 79, 79, 255};
const Color DARK_TURQUOISE = {0, 206, 209, 255};
const Color DEEP_VIOLET = {148, 0, 211, 255};
const Color DEEP_PINK = {255, 20, 147, 255};
const Color DEEP_SKY_BLUE = {0, 191, 255, 255};
const Color DIM_GRAY = {105, 105, 105, 255};
const Color DODGER_BLUE = {30, 144, 255, 255};
const Color FIRE_BRICK = {178, 34, 34, 255};
const Color FLORAL_WHITE = {255, 250, 240, 255};
const Color FOREST_GREEN = {34, 139, 34, 255};
const Color GAINSBORO = {220, 220, 220, 255};
const Color GHOST_WHITE = {248, 248, 255, 255};
const Color GOLDEN_ROD = {218, 165, 32, 255};
const Color MID_GREEN = {0, 128, 0, 255};
const Color GREEN_YELLOW = {173, 255, 47, 255};
const Color HONEY_DEW = {240, 255, 240, 255};
const Color HOT_PINK = {255, 105, 180, 255};
const Color INDIAN_RED = {205, 92, 92, 255};
const Color INDIGO = {72, 0, 130, 255};
const Color IVORY = {255, 255, 240, 255};
const Color KHAKI = {240, 230, 140, 255};
const Color LAVENDER = {230, 230, 250, 255};
const Color LAVENDER_BLUSH = {255, 240, 245, 255};
const Color LAWN_GREEN = {124, 252, 0, 255};
const Color LEMON_CHIFFON = {255, 250, 205, 255};
const Color LIGHT_BLUE = {173, 216, 203, 255};
const Color LIGHT_CORAL = {240, 128, 128, 255};
const Color LIGHT_CYAN = {240, 128, 128, 255};
const Color LIGHT_GOLDEN_ROD_YELLOW = {250, 250, 210, 255};
const Color LIGHT_PINK = {255, 182, 193, 255};
const Color LIGHT_SALMON = {255, 160, 122, 255};
const Color LIGHT_SEA_GREEN = {32, 178, 170, 255};
const Color LIGHT_SKY_BLUE = {135, 206, 250, 255};
const Color LIGHT_SLATE_GRAY = {119, 136, 153, 255};
const Color LIGHT_STEEL_BLUE = {176, 196, 222, 255};
const Color LIGHT_YELLOW = {255, 255, 224, 255};
const Color LIME_GREEN = {50, 205, 50, 255};
const Color LINEN = {250, 240, 230, 255};
const Color MAROON = {128, 0, 0, 255};
const Color MEDIUM_AQUAMARINE = {102, 205, 170, 255};
const Color MEDIUM_BLUE = {0, 0, 205, 255};
const Color MEDIUM_ORCHID = {186, 85, 211, 255};
const Color MEDIUM_PURPLE = {147, 112, 219, 255};
const Color MEDIUM_SEA_GREEN = {60, 179, 113, 255};
const Color MEDIUM_SLATE_BLUE = {123, 104, 238, 255};
const Color MEDIUM_SPRING_GREEN = {0, 250, 154, 255};
const Color MEDIUM_TURQUOISE = {72, 209, 204, 255};
const Color MEDIUM_VIOLET_RED = {199, 21, 133, 255};
const Color MIDNIGHT_BLUE = {25, 25, 112, 255};
const Color MINT_CREME = {245, 255, 250, 255};
const Color MISTY_ROSE = {255, 228, 225, 255};
const Color MOCCASIN = {255, 228, 181, 255};
const Color NAVAJO_WHITE = {255, 222, 173, 255};
const Color NAVY = {0, 0, 128, 255};
const Color OLD_LACE = {253, 245, 230, 255};
const Color OLIVE = {128, 128, 0, 255};
const Color OLIVE_DRAB = {107, 142, 35, 255};
const Color ORANGE_RED = {255, 69, 0, 255};
const Color ORCHID = {218, 112, 214, 255};
const Color PALE_GOLDEN_ROD = {238, 232, 170, 255};
const Color PALE_GREEN = {152, 251, 152, 255};
const Color PALE_TURQUOISE = {175, 238, 238, 255};
const Color PALE_VIOLET_RED = {219, 112, 147, 255};
const Color PAPAYA_WHIP = {225, 239, 213, 255};
const Color PEACH_PUFF = {225, 218, 185, 255};
const Color PERU = {205, 133, 63, 255};
const Color PLUM = {221, 160, 221, 255};
const Color POWDER_BLUE = {176, 224, 230, 255};
const Color ROSY_BROWN = {188, 143, 143, 255};
const Color ROYAL_BLUE = {65, 105, 225, 255};
const Color SADDLE_BROWN = {139, 69, 19, 255};
const Color SALMON = {250, 128, 114, 255};
const Color SANDY_BROWN = {244, 164, 96, 255};
const Color SEA_GREEN = {46, 139, 87, 255};
const Color SEA_SHELL = {255, 245, 238, 255};
const Color SIENNA = {160, 82, 45, 255};
const Color SILVER = {192, 192, 192, 255};
const Color SKY_BLUE = {135, 206, 235, 255};
const Color SLATE_BLUE = {106, 90, 205, 255};
const Color SLATE_GRAY = {112, 128, 144, 255};
const Color SNOW = {255, 250, 250, 255};
const Color SPRING_GREEN = {0, 255, 127, 255};
const Color STEEL_BLUE = {70, 130, 180, 255};
const Color TAN = {210, 180, 140, 255};
const Color TEAL = {0, 128, 128, 255};
const Color THISTLE = {216, 191, 216, 255};
const Color TOMATO = {255, 99, 71, 255};
const Color TURQUOISE = {64, 224, 208, 255};
const Color WHEAT = {245, 222, 179, 255};
const Color WHITE_SMOKE = {245, 245, 245, 255};
const Color YELLOW_GREEN = {154, 205, 50, 255};

const Color BLACK = {0,0,0, 255};
const Color WHITE = {255,255,255, 255};

const Color DESATURATED_RED = {128,64,64, 255};
const Color LIGHTEST_RED = {255,191,191, 255};
const Color LIGHTER_RED = {255,166,166, 255};
const Color LIGHT_RED = {255,115,115, 255};
const Color RED = {255,0,0, 255};
const Color DARK_RED = {191,0,0, 255};
const Color DARKER_RED = {128,0,0, 255};
const Color DARKEST_RED = {64,0,0, 255};
const Color FLAME = {255,63,0, 255};
const Color ORANGE = {255,127,0, 255};
const Color AMBER = {255,191,0, 255};
const Color YELLOW = {255,255,0, 255};
const Color LIME = {191,255,0, 255};
const Color DESATURATED_GREEN = {64,128,64, 255};
const Color LIGHTEST_GREEN = {191,255,191, 255};
const Color LIGHTER_GREEN = {166,255,166, 255};
const Color LIGHT_GREEN = {115,255,115, 255};
const Color GREEN = {0,255,0, 255};
const Color DARK_GREEN = {0,191,0, 255};
const Color DARKER_GREEN = {0,128,0, 255};
const Color DARKEST_GREEN = {0,64,0, 255};
const Color SEA = {0,255,127, 255};
const Color CYAN = {0,255,255, 255};
const Color SKY = {0,191,255, 255};
const Color AZURE = {0,127,255, 255};
const Color BLUE = {0,0,255, 255};
const Color HAN = {63,0,255, 255};
const Color VIOLET = {127,0,255, 255};
const Color PURPLE = {191,0,255, 255};
const Color FUCHSIA = {255,0,191, 255};
const Color MAGENTA = {255,0,255, 255};
const Color PINK = {255,0,127, 255};

const Color BRASS = {191,151,96, 255};
const Color COPPER = {200,117,51, 255};
const Color GOLD = {229,191,0, 255};

const Color CELADON = {172,255,171, 255};
const Color PEACH = {255,159,127, 255};

const Color LIGHTEST_GREY = {223,223,223, 255};
const Color LIGHTER_GREY = {191,191,191, 255};
const Color LIGHT_GREY = {159,159,159, 255};
const Color GREY = {127,127,127, 255};
const Color DARK_GREY = {95,95,95, 255};
const Color DARKER_GREY = {63,63,63, 255};
const Color DARKEST_GREY = {31,31,31, 255};

const Color LIGHTEST_SEPIA = {222,211,195, 255};
const Color LIGHTER_SEPIA = {191,171,143, 255};
const Color LIGHT_SEPIA = {158,134,100, 255};
const Color SEPIA = {127,101,63, 255};
const Color DARK_SEPIA = {94,75,47, 255};
const Color DARKER_SEPIA = {63,50,31, 255};
const Color DARKEST_SEPIA = {31,24,15, 255};
