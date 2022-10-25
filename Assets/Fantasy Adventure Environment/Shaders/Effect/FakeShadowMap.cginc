#include "UnityCG.cginc"

	float4 _ShadowPlane, _ShadowProjDir, _ShadowFadeParams;
    float _ShadowInvLen;

    struct v2f 
            {
             	float4 	  pos      : SV_POSITION;
            	float3   shadowPlane : TEXCOORD0;
            	float3   shadowMap : TEXCOORD1;
            };

    v2f vert(appdata_base v)
    {
    	v2f o;
    	float4 ShadowDir = normalize(_ShadowProjDir);
    	float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
    	float4 SPlane = _ShadowPlane;//mul(unity_ObjectToWorld, _ShadowPlane);
    	o.shadowMap = worldPos - (((dot(SPlane.xyz, worldPos) - SPlane.w) / dot(SPlane.xyz, ShadowDir.xyz)) * ShadowDir.xyz);
    	float4 worldPos1 = float4(o.shadowMap, 1.0);
    	float3 ShadowPlane;
    	ShadowPlane.x = unity_ObjectToWorld[0].w;
    	ShadowPlane.y = _ShadowPlane.w;
    	ShadowPlane.z = unity_ObjectToWorld[2].w;
    	o.shadowPlane = ShadowPlane;
    	o.pos = mul(UNITY_MATRIX_VP, worldPos1);
    	return o;
    }
    float4 frag(v2f i) : SV_Target
    {
    	float3 posToPlane = i.shadowPlane - i.shadowMap;
    	fixed3 col = fixed3(0.0, 0.0, 0.0);
    	float w = pow((1.0 - clamp(((sqrt(dot(posToPlane, posToPlane)) * _ShadowInvLen) - _ShadowFadeParams.x), 0.0, 1.0)), _ShadowFadeParams.y) * _ShadowFadeParams.z;
		return fixed4(col, w);
    }