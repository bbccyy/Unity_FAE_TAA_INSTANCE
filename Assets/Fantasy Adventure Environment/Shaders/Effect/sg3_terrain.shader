Shader "sg3/Scene/Diffuse/sg3Terrain" {
Properties {
	_Splat0 ("Layer 1", 2D) = "white" {}
	_Splat1 ("Layer 2", 2D) = "white" {}
	_Splat2 ("Layer 3", 2D) = "white" {}
	_Splat3 ("Layer 4", 2D) = "white" {}
	_Control ("Control (RGBA)", 2D) = "white" {}
}
                
	SubShader {
		Tags {"Queue" = "Geometry-99" "SplatCount" = "4" "RenderType" = "Opaque"}

	CGPROGRAM
	#pragma surface surf Lambert vertex:SplatmapVert finalcolor:SplatmapFinalColor finalprepass:SplatmapFinalPrepass finalgbuffer:SplatmapFinalGBuffer noinstancing
	#pragma exclude_renderers xbox360 ps3 flash
	#pragma multi_compile_fog
	#pragma target 3.0
	//#include "TerrainSplatmapCommon.cginc"
	//#include "Common.cginc"
	struct Input
	{
		float2 uv_Splat0 : TEXCOORD0;
		float2 uv_Splat1 : TEXCOORD1;
		float2 uv_Splat2 : TEXCOORD2;
		float2 uv_Splat3 : TEXCOORD3;
		float2 tc_Control : TEXCOORD4;  // Not prefixing '_Contorl' with 'uv' allows a tighter packing of interpolators, which is necessary to support directional lightmap.
		UNITY_FOG_COORDS(5)
	};
	sampler2D _Control;
	float4 _Control_ST;
	sampler2D _Splat0,_Splat1,_Splat2,_Splat3;

	void SplatmapVert(inout appdata_full v, out Input data)
	{
		UNITY_INITIALIZE_OUTPUT(Input, data);
		data.tc_Control = TRANSFORM_TEX(v.texcoord, _Control);  // Need to manually transform uv here, as we choose not to use 'uv' prefix for this texcoord.
		float4 pos = UnityObjectToClipPos(v.vertex);
		UNITY_TRANSFER_FOG(data, pos);
	}
	  
	void SplatmapMix(Input IN, out half4 splat_control, out half weight, out fixed4 mixedDiffuse, inout fixed3 mixedNormal)
	{
		splat_control = tex2D(_Control, IN.tc_Control);
		weight = dot(splat_control, half4(1,1,1,1));

		#if !defined(SHADER_API_MOBILE) && defined(TERRAIN_SPLAT_ADDPASS)
			clip(weight == 0.0f ? -1 : 1);
		#endif

		// Normalize weights before lighting and restore weights in final modifier functions so that the overal
		// lighting result can be correctly weighted.
		splat_control /= (weight + 1e-3f);

		mixedDiffuse = 0.0f;

			mixedDiffuse += splat_control.r * tex2D(_Splat0, IN.uv_Splat0);
			mixedDiffuse += splat_control.g * tex2D(_Splat1, IN.uv_Splat1);
			mixedDiffuse += splat_control.b * tex2D(_Splat2, IN.uv_Splat2);
			mixedDiffuse += splat_control.a * tex2D(_Splat3, IN.uv_Splat3);


	}

	#ifndef TERRAIN_SURFACE_OUTPUT
		#define TERRAIN_SURFACE_OUTPUT SurfaceOutput
	#endif

	void SplatmapFinalColor(Input IN, TERRAIN_SURFACE_OUTPUT o, inout fixed4 color)
	{
		color *= o.Alpha;
		#ifdef TERRAIN_SPLAT_ADDPASS
			UNITY_APPLY_FOG_COLOR(IN.fogCoord, color, fixed4(0,0,0,0));
		#else
			UNITY_APPLY_FOG(IN.fogCoord, color);
		#endif
	}

	void SplatmapFinalPrepass(Input IN, TERRAIN_SURFACE_OUTPUT o, inout fixed4 normalSpec)
	{
		normalSpec *= o.Alpha;
	}

	void SplatmapFinalGBuffer(Input IN, TERRAIN_SURFACE_OUTPUT o, inout half4 outGBuffer0, inout half4 outGBuffer1, inout half4 outGBuffer2, inout half4 emission)
	{
		UnityStandardDataApplyWeightToGbuffer(outGBuffer0, outGBuffer1, outGBuffer2, o.Alpha);
		emission *= o.Alpha;
	}

		void surf (Input IN, inout SurfaceOutput o) {
			half4 splat_control;
			half weight;
			fixed4 mixedDiffuse;
			SplatmapMix(IN, splat_control, weight, mixedDiffuse, o.Normal);
			o.Albedo = mixedDiffuse.rgb;
			o.Alpha = weight;
		}
		ENDCG 
	}
	Fallback "Diffuse"
}
