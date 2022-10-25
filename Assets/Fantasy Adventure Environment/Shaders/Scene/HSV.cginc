#ifndef BabeltimeHasInc
#define BabeltimeHasInc

inline float3 to_hsv(float3 c)
{
    float r = c.r;
    float g = c.g;
    float b = c.b;

    float3 o;

    float max1 = max(r, max(g, b));
    float min1 = min(r, min(g, b));
    float delta = max1 - min1;

    if (r == max1) o.x = (g - b) / delta;
    if (g == max1) o.x = 2 + (b - r) / delta;
    if (b == max1) o.x = 4 + (r - g) / delta;
    o.x *= 60.0;

    if (o.x < 0) o.x += 360.0;

    o.z = max1;
    o.y = delta / max1;

    return o;
}

inline float3 from_hsv(float3 c)
{
    float r, g, b;
    if (c.y == 0)
    {
        r = g = b = c.z;
    }
    else
    {
        c.x /= 60.0;
        int i = (int)c.x;
        float f = c.x - (float)i;
        float x = c.z * (1 - c.y);
        float y = c.z * (1 - c.y * f);
        float z = c.z * (1 - c.y * (1 - f));
        if (i == 0)
        {
            r = c.z;
            g = z;
            b = x;
        }
        else if (i == 1)
        {
            r = x;
            g = c.z;
            b = z;
        }
        else if (i == 2)
        {
            r = x;
            g = c.z;
            b = z;
        }
        else if (i == 3)
        {
            r = x;
            g = y;
            b = c.z;
        }
        else if (i == 4)
        {
            r = z;
            g = x;
            b = c.z;
        }
        else
        {
            r = c.z;
            g = x;
            b = y;
        }
    }
    return float3(r, g, b);
}

inline float3 apply_hsv(float3 c, float h, float s, float v)
{
    float3 hsv = to_hsv(c);
    hsv.x += h;
    hsv.x = hsv.x % 360;
    hsv.y *= s;
    hsv.z *= v;
    c = from_hsv(hsv);
    return c;
}

#endif