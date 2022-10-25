
half4 DecodeHDR(half4 rgba)
{
#ifdef HDR_RGB111110
    return rgba;
#else
    return half4(rgba.rgb * rgba.a * 8.0, 1.0);
#endif
}

half4 EncodeHDR(half3 rgb)
{
#ifdef HDR_RGB111110
    return half4(rgb, 1.0);
#else
    rgb *= 1.0 / 8.0;
    float m = max(max(rgb.r, rgb.g), max(rgb.b, 1e-6));
    m = ceil(m * 255.0) / 255.0;
    return half4(rgb / m, m);
#endif
}

// Brightness function
half Brightness(half3 c)
{
	return max(c.x, max(c.y, c.z));
}

// 3-tap median filter
half3 Median(half3 a, half3 b, half3 c)
{
	return a + b + c - min(min(a, b), c) - max(max(a, b), c);
}


// 3 * 3 = 9
//
// HIGH
//
// 0.0947416 0.118318 0.0947416
//
// 0.118318  0.147761 0.118318
//
// 0.0947416 0.118318 0.0947416

// LOW
//
// 0.0   0.15  0.0
//
// 0.15  0.4   0.15
//
// 0.0   0.15  0.0

half3 DownsampleFilter(sampler2D tex, float2 uv, float2 texelSize)
{
	float4 d = texelSize.xyxy * float4(-1.0, -1.0, 1.0, 1.0);
	float3 d1 = texelSize.xxx * float3(1.0, -1.0, 0.0);
	float3 d2 = texelSize.yyy * float3(0.0, 1.0, -1.0);

    //#define POST_EFFECT_HIGH_QUALITY

#ifdef POST_EFFECT_HIGH_QUALITY
    half3 s;
    s = DecodeHDR(tex2D(tex, uv)) * 0.147761;
	s += DecodeHDR(tex2D(tex, uv + d1.xz)) * 0.118318;
	s += DecodeHDR(tex2D(tex, uv + d1.yz)) * 0.118318;
	s += DecodeHDR(tex2D(tex, uv + d2.xy)) * 0.118318;
    s += DecodeHDR(tex2D(tex, uv + d2.xz)) * 0.118318;
	s += DecodeHDR(tex2D(tex, uv + d.xy)) * 0.0947416;
    s += DecodeHDR(tex2D(tex, uv + d.zy)) * 0.0947416;
    s += DecodeHDR(tex2D(tex, uv + d.xw)) * 0.0947416;
    s += DecodeHDR(tex2D(tex, uv + d.zw)) * 0.0947416;

	return s;
#else
	half3 s;
    s =  DecodeHDR(tex2D(tex, uv)) * 0.4;
	s += DecodeHDR(tex2D(tex, uv + d1.xz)) * 0.15;
	s += DecodeHDR(tex2D(tex, uv + d1.yz)) * 0.15;
	s += DecodeHDR(tex2D(tex, uv + d2.xy)) * 0.15;
    s += DecodeHDR(tex2D(tex, uv + d2.xz)) * 0.15;
	return s;
#endif
}

half3 UpsampleFilter(sampler2D tex, float2 uv, float2 texelSize, float sampleScale)
{
	float4 d = texelSize.xyxy * float4(-1.0, -1.0, 1.0, 1.0) * (sampleScale);
	float3 d1 = texelSize.xxx * float3(1.0, -1.0, 0.0) * (sampleScale);
	float3 d2 = texelSize.yyy * float3(0.0, 1.0, -1.0) * (sampleScale);

    //#define POST_EFFECT_HIGH_QUALITY

#ifdef POST_EFFECT_HIGH_QUALITY
    half3 s;
    s = DecodeHDR(tex2D(tex, uv)) * 0.147761;
	s += DecodeHDR(tex2D(tex, uv + d1.xz)) * 0.118318;
	s += DecodeHDR(tex2D(tex, uv + d1.yz)) * 0.118318;
	s += DecodeHDR(tex2D(tex, uv + d2.xy)) * 0.118318;
    s += DecodeHDR(tex2D(tex, uv + d2.xz)) * 0.118318;
	s += DecodeHDR(tex2D(tex, uv + d.xy)) * 0.0947416;
    s += DecodeHDR(tex2D(tex, uv + d.zy)) * 0.0947416;
    s += DecodeHDR(tex2D(tex, uv + d.xw)) * 0.0947416;
    s += DecodeHDR(tex2D(tex, uv + d.zw)) * 0.0947416;
	return s;
#else
	half3 s;
    s =  DecodeHDR(tex2D(tex, uv)) * 0.4;
	s += DecodeHDR(tex2D(tex, uv + d1.xz)) * 0.15;
	s += DecodeHDR(tex2D(tex, uv + d1.yz)) * 0.15;
	s += DecodeHDR(tex2D(tex, uv + d2.xy)) * 0.15;
    s += DecodeHDR(tex2D(tex, uv + d2.xz)) * 0.15;
	return s;
#endif
}