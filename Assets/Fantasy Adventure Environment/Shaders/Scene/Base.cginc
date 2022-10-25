// In order to unify the lighting model(simple and different from standard Unity Lambert GI),
// and some util functions, remove some variants we don't need.
// The main difference our lighting compares to Unity's standard one is we make the shadows more dark.

#ifndef BabeltimeBaseInc
#define BabeltimeBaseInc

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

struct ill_data
{
    fixed alpha;
    fixed3 albedo;
    half atten;
    half3 worldNormal;
#ifdef LIGHTMAP_ON
    float4 lmap;
#endif
#ifndef LIGHTMAP_ON
    #if UNITY_SHOULD_SAMPLE_SH
        half3 vlight;
    #endif
    float3 worldPos;
#endif
};

inline fixed3 light_dir(float3 worldPos)
{
    #ifndef USING_DIRECTIONAL_LIGHT
        fixed3 ldir = normalize(UnityWorldSpaceLightDir(worldPos));
    #else
        fixed3 ldir = _WorldSpaceLightPos0.xyz;
    #endif
    return ldir;
}

inline half4 lambert(fixed3 albedo, fixed alpha, half3 ldir, fixed3 worldNormal, half atten)
{
    half4 c = 0;
    half ndotl = dot(worldNormal, ldir);
    fixed4 prev = fixed4(albedo.r, albedo.g, albedo.b, alpha);
    c += prev * _LightColor0 * (ndotl * atten);
    return c;
}

inline fixed4 illumination(ill_data data)
{
    fixed4 c = 0;
    #ifdef LIGHTMAP_ON
        #ifdef DIRLIGHTMAP_COMBINED
            // directional lightmaps
            fixed4 lmtex = UNITY_SAMPLE_TEX2D(unity_Lightmap, data.lmap.xy);
            #ifdef BABELTIME_BUMPED
                fixed4 lmIndTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_LightmapInd, unity_Lightmap, data.lmap.xy);
                half3 lm = DecodeDirectionalLightmap(DecodeLightmap(lmtex), lmIndTex, data.worldNormal);
            #else
                half3 lm = DecodeLightmap(lmtex);
            #endif
        #else
            // single lightmap
            fixed4 lmtex = UNITY_SAMPLE_TEX2D(unity_Lightmap, data.lmap.xy);
            fixed3 lm = DecodeLightmap(lmtex);
        #endif
        c.a = data.alpha;
        #ifdef SHADOWS_SCREEN
            c.rgb += data.albedo * max(min(lm, (data.atten * 2) * lmtex.rgb), lm * data.atten);
        #else
            c.rgb += data.albedo * lm;
        #endif
    #else
        #if UNITY_SHOULD_SAMPLE_SH
            c.rgb += data.albedo * data.vlight;
        #endif
        fixed3 ldir = light_dir(data.worldPos);
        c += lambert(data.albedo, data.alpha, ldir, data.worldNormal, data.atten);
    #endif

    return c;
}

struct blinn_data
{
    float3 worldPos;
    half3 worldNormal;
    half specular;
    fixed gloss;
    fixed3 albedo;
    fixed3 specColor;
};

inline fixed3 blinn_phong(blinn_data data)
{
    fixed3 ldir = light_dir(data.worldPos);
    fixed3 lcol = _LightColor0.rgb;
    fixed3 vdir = normalize(UnityWorldSpaceViewDir(data.worldPos));
    half3 h = normalize(ldir + vdir);
    fixed diff = max(0, dot(data.worldNormal, ldir));
    float nh = max(0, dot(data.worldNormal, h));
    float spec = pow(nh, data.specular * 128.0) * data.gloss;
    fixed3 c = data.albedo * lcol * diff + lcol * data.specColor * spec;
    return c;
}

#endif