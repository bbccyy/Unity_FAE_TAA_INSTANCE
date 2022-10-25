#if !defined(SG3_SCENEWIND_INCLUDED)
#define SG3_SCENEWIND_INCLUDED

//#include "Common.cginc"
#include "TerrainEngine.cginc"

float4 _MainColor;

#ifdef STAGE_WIND
	float _WindEdgeFlutter;
	float _WindEdgeFlutterFreqScale;
#endif

sampler2D _MainTex;
float4 _MainTex_ST;

float  _AlphaClipThreshold = 0.0f;

struct v2f 
{
  float4 pos : SV_POSITION;
  float2 uv : TEXCOORD0;
  float2 lmap : TEXCOORD1;
  UNITY_FOG_COORDS(2)
};

float4 aux_AnimateVertex2(float4 pos, float3 normal, float4 animParams,float4 wind,float2 time)
{	
	// animParams stored in color
	// animParams.x = branch phase
	// animParams.y = edge flutter factor
	// animParams.z = primary factor
	// animParams.w = secondary factor

	float fDetailAmp = 0.1f;
	float fBranchAmp = 0.3f;
	
	// Phases (object, vertex, branch)
	float fObjPhase = dot(unity_ObjectToWorld[3].xyz, 1);
	float fBranchPhase = fObjPhase + animParams.x;
	
	float fVtxPhase = dot(pos.xyz, animParams.y + fBranchPhase);
	
	// x is used for edges; y is used for branches
	float2 vWavesIn = time.yy  + float2(fVtxPhase, fBranchPhase );
	
	// 1.975, 0.793, 0.375, 0.193 are good frequencies
	float4 vWaves = (frac( vWavesIn.xxyy * float4(1.975, 0.793, 0.375, 0.193) ) * 2.0 - 1.0);
	
	vWaves = SmoothTriangleWave( vWaves );
	float2 vWavesSum = vWaves.xz + vWaves.yw;

	// Edge (xz) and branch bending (y)
	float3 bend = animParams.y * fDetailAmp * normal.xyz;
	bend.y = animParams.w * fBranchAmp;
	pos.xyz += ((vWavesSum.xyx * bend) + (wind.xyz * vWavesSum.y * animParams.w)) * wind.w; 
	// Primary bending
	// Displace position
	pos.xyz += animParams.z * wind.xyz;
	
	return pos;
}

v2f vert(appdata_full v) 
{
  v2f o = (v2f)0;
  
#ifdef STAGE_WIND
	float4	wind;
	float	bendingFact	= v.color.a;
	
	wind.xyz	= mul((float3x3)unity_WorldToObject, _Wind.xyz);
	wind.w		= _Wind.w  * bendingFact;
	
	float4	windParams	= float4(0,_WindEdgeFlutter,bendingFact.xx);
	float2  windTime 		= _Time.y * float2(_WindEdgeFlutterFreqScale,1);
	float4	mdlPos			= aux_AnimateVertex2(v.vertex, v.normal, windParams, wind, windTime);
	o.pos = UnityObjectToClipPos(mdlPos);
#else	
	o.pos = UnityObjectToClipPos(v.vertex);
#endif  
  
  o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
  o.lmap = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
  
  UNITY_TRANSFER_FOG(o,o.pos);
  return o;
}

half4 frag(v2f i) : SV_Target 
{
	half4 c;
  	half4 main_color = tex2D(_MainTex, i.uv);
  	c.rgb = main_color.rgb;
	c.a = main_color.a;

	#ifdef STAGE_ALPHA_CLIP
	clip(c.a - _AlphaClipThreshold);
	#endif

	#if defined(LIGHTMAP_ON)
		half3 clLightmap = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lmap));
  		main_color.rgb *= clLightmap;
	#endif
  
  	c.rgb = main_color.rgb * _MainColor.rgb;
  
  	UNITY_APPLY_FOG(i.fogCoord, c);
  
	//c.rgb = EncodeColor(c.rgb);
  
  return c;
}

#endif