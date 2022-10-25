#ifndef UNITY_CG_INCLUDED
#define UNITY_CG_INCLUDED

//把UnityCG.cginc的输入老结构移过来减少修改
struct appdata_full {
    float4 vertex : POSITION;
    float4 tangent : TANGENT;
    float3 normal : NORMAL;
    float4 texcoord : TEXCOORD0;
    float4 texcoord1 : TEXCOORD1;
    float4 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
    half4 color : COLOR;
    
    #if UNITY_ANY_INSTANCING_ENABLED
    uint instanceID : INSTANCEID_SEMANTIC; //user can get instanceID by UNITY_GET_INSTANCE_ID(Attributes)
    #endif 
};

inline float3 UnityWorldSpaceLightDir( in float3 worldPos )
{
    return _MainLightPosition.xyz;
}
    
inline float3 UnityWorldSpaceViewDir( in float3 worldPos )
{
    return _MainLightPosition.xyz - worldPos;
}

#endif