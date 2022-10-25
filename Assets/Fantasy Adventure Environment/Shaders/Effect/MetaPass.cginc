#if !defined(SG3_MetaPass_INCLUDED)
#define SG3_MetaPass_INCLUDED

#include "SceneBase.cginc"
#include "UnityMetaPass.cginc"

float4 _EmissionMap_ST;


struct metav2f {
	float4 pos : SV_POSITION;
	float4 uv : TEXCOORD0;
};

// vertex shader
v2f metavert (appdata_full v) {
  	v2f o;
  	UNITY_INITIALIZE_OUTPUT(v2f, o);

  	o.pos = UnityMetaVertexPosition(v.vertex, v.texcoord1.xy, v.texcoord2.xy, unity_LightmapST, unity_DynamicLightmapST);
  	o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
  	o.uv.zw = TRANSFORM_TEX(v.texcoord, _EmissionMap);
	o.normal = UnityObjectToWorldNormal(v.normal);

	#if defined(BINORMAL_PER_FRAGMENT)
		o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
	#else
		o.tangent = UnityObjectToWorldDir(v.tangent.xyz);
		o.binormal = CreateBinormal(o.normal, o.tangent, v.tangent.w);
	#endif
	return o;
}

//fragment shader
fixed4 metafrag (v2f i) : SV_Target {
	UnityMetaInput surfaceData;

  	surfaceData.Emission = GetEmission(i);
  	InitializeFragmentNormal(i);
  	float oneMinusReflectivity;
  	surfaceData.Albedo = MyDiffuseAndSpecularFromMetallic(GetAlbedo(i), GetMetallic(i), surfaceData.SpecularColor, oneMinusReflectivity);
  	float smoothness = _Shininess;
  	float roughness = (1 - smoothness) * (1 - smoothness) * 0.5; 
  	surfaceData.Albedo += surfaceData.SpecularColor * roughness;
 	return UnityMetaFragment(surfaceData);
}

#endif