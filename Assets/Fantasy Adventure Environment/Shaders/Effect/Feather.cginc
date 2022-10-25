#if !defined(SG3_FEATHER_INCLUDED)
#define SG3_FEATHER_INCLUDED


	#include "UnityCG.cginc"

	//sampler2D _MainTex, _SubTex;
	//float4 _MainTex_ST, _SubTex_ST, _Wind, _Gravity;
	float4 _Gravity;
	float _Spacing, _Tming;

	struct v2f {
        float4 pos : SV_POSITION;
        float4 uv  : TEXCOORD0;
    };

	v2f vert(appdata_base v)
	{
		v2f o;
		UNITY_INITIALIZE_OUTPUT(v2f, o);
		//float3 forceDir;
		//forceDir.x = sin(_Time.y * 1.5 * _Wind.x + v.vertex.x * 0.5 * _Wind.z) * _Wind.w;
		//forceDir.y = cos(_Time.y * 0.5 * _Wind.x + v.vertex.y * 0.4 * _Wind.y) * _Wind.w;
		//forceDir.z = sin(_Time.y * 0.7 * _Wind.x + v.vertex.y * 0.3 * _Wind.y) * _Wind.w;

		passVertData data = ForceDir(v);
		//float3 normal = v.normal + (forceDir + _Gravity.xyz) * FORCE;
		float3 normal = v.normal + (data.forceDir + _Gravity.xyz) * FORCE;
		float3 vertex = v.vertex.xyz + normalize(normal) * NORMALOFFSET * (_Spacing / 5.0);
		o.pos = UnityObjectToClipPos(float4(vertex, 1.0));
		//o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
		//o.uv.zw = TRANSFORM_TEX(v.texcoord, _SubTex);
		o.uv.xy = data.uv.xy;
		o.uv.zw = data.uv.zw;
		return o;
	}

	fixed4 frag(v2f i): SV_Target
	{
		fixed4 col = tex2D(_MainTex, i.uv.xy);
		fixed4 subTex = tex2D(_SubTex, i.uv.zw);
		col.a = (saturate(subTex * 2.0 - SCALE) * _Tming).x;
		return col;
	}


#endif