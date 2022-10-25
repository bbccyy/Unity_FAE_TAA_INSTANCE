// Upgrade NOTE: replaced 'defined FOG_COMBINED_WITH_WORLD_POS' with 'defined (FOG_COMBINED_WITH_WORLD_POS)'

Shader "Babeitime/Scene/RealisticWater"
{
	Properties
	{
		[HideInInspector]_Cube("Reflection Map", CUBE) = ""{}
		_ShoreBlendDistance("Shore Blend Distance", Range( 0 , 20)) = 0.02
		[NoScaleOffset][Normal]_WaterNormal("Water Normal", 2D) = "bump" {}
		_NormalPower("Normal Power", Range( 0 , 1)) = 0
		_LargerWavesNormalPower("Larger Waves Normal Power", Range( 0 , 1)) = 1
		_Gloss("Gloss", Range( 0 , 1)) = 1
		_SpecularPower("Specular Power", Float) = 0.88
		_WaterTiling("Water Tiling", Range( 0.01 , 30)) = 0
		[Toggle]_InvertCoordinates("Invert Coordinates", Float) = 0
		_WaterSpeed("Water Speed", Range( 0.01 , 20)) = 0
		[HDR]_WaterTint("Water Tint", Color) = (0.5235849,0.8924802,1,1)
		[HDR]_ScatteringTint("Scattering Tint", Color) = (1,1,1,0)
		_Density("Density", Range( 0.1 , 1.5)) = 0.01
		_WaterEmission("Water Emission", Range( 0 , 2)) = 0.2
		_ScatteringIntensity("Scattering Intensity", Range( 0 , 6)) = 0.45
		_ScatteringOffset("Scattering Offset", Range( -6 , 6)) = -1
		[NoScaleOffset]_WaterHeight("Water Height", 2D) = "white" {}
		_ReflectionFresnel("Reflection Fresnel", Range( 1 , 10)) = 0
		[NoScaleOffset]_Foam("Foam", 2D) = "white" {}
		_FoamTiling("Foam Tiling", Range( 0.01 , 20)) = 2
		_FoamSpeed("Foam Speed", Range( 0 , 20)) = 2
		_FoamDistance("Foam Distance", Range( 0 , 6)) = 1.5
		_FoamIntensity("Foam Intensity", Range( 0 , 2)) = 0
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "AlphaTest+150" "IgnoreProjector" = "True" "ForceNoShadowCasting" = "True" }
		Cull Back
		ZWrite On
		Blend SrcAlpha OneMinusSrcAlpha
		
		HLSLINCLUDE
		#pragma target 3.0
        #pragma multi_compile_instancing
		#include "HLSLSupport.cginc"
        #define UNITY_INSTANCED_LOD_FADE
        #define UNITY_INSTANCED_SH
        #define UNITY_INSTANCED_LIGHTMAPSTS
        #include "UnityShaderVariables.cginc"
        #include "UnityShaderUtilities.cginc"
        ENDHLSL
	// ------------------------------------------------------------
	// Surface shader code generated out of a HLSLPROGRAM block:
	

	// ---- forward rendering base pass:
	Pass {
		Name "FORWARD"
		Tags { "LightMode" = "UniversalForward" }

HLSLPROGRAM
// compile directives
#pragma vertex vert_surf
#pragma fragment frag_surf
#pragma multi_compile_fog
#pragma multi_compile_fwdbase

// -------- variant for: <when no other keywords are defined>
// Surface shader code generated based on:
// vertex modifier: 'vertexDataFunc'
// writes to per-pixel normal: YES
// writes to emission: no
// writes to occlusion: no
// needs world space reflection vector: YES
// needs world space normal vector: YES
// needs screen space position: YES
// needs world space position: YES
// needs view direction: no
// needs world space view direction: no
// needs world space position for lighting: YES
// needs world space view direction for lighting: YES
// needs world space view direction for lightmaps: no
// needs vertex color: no
// needs VFACE: no
// passes tangent-to-world matrix to pixel shader: YES
// reads from normal: no
// 0 texcoords actually used
#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
#define WorldNormalVector(data,normal) fixed3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))

// Original surface shader snippet:
#line 36 ""
#ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
#endif
/* UNITY: Original start of shader */
		#include "UnityPBSLighting.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityCG.cginc"
		#include "Tessellation.cginc"
		//#pragma target 3.0
		//#pragma surface surf StandardCustomLighting keepalpha vertex:vertexDataFunc 
		struct Input
		{
			float3 worldPos;
			float4 screenPos;
			float3 worldNormal;
			INTERNAL_DATA
			float3 worldRefl;
		};

		struct SurfaceOutputCustomLightingCustom
		{
			half3 Albedo;
			half3 Normal;
			half3 Emission;
			half Metallic;
			half Smoothness;
			half Occlusion;
			half Alpha;
			Input SurfInput;
			UnityGIInput GIData;
		};

		uniform sampler2D _WaterHeight;
		uniform float _WaterSpeed;
		uniform float _InvertCoordinates;
		uniform float _WaterTiling;
		uniform float _LargerWavesNormalPower;
		uniform sampler2D _CameraDepthTexture;
		uniform float _ShoreBlendDistance;
		uniform sampler2D _WaterNormal;
		uniform float _NormalPower;
		uniform float _Gloss;
		uniform samplerCUBE _Cube;
		uniform float _ReflectionFresnel;
		uniform float _ScatteringOffset;
		uniform float4 _ScatteringTint;
		uniform float _ScatteringIntensity;
		uniform float _WaterEmission;
		uniform sampler2D _Foam;
		uniform float _FoamSpeed;
		uniform float _FoamTiling;
		uniform float _FoamDistance;
		uniform float _FoamIntensity;
		uniform float _Density;
		uniform float4 _WaterTint;
		uniform sampler2D _GrabTexture;
		uniform float _SpecularPower;

		inline float4 ASE_ComputeGrabScreenPos( float4 pos )
		{
			#if UNITY_UV_STARTS_AT_TOP
			float scale = -1.0;
			#else
			float scale = 1.0;
			#endif
			float4 o = pos;
			o.y = pos.w * 0.5f;
			o.y = ( pos.y - o.y ) * _ProjectionParams.x * scale + o.y;
			return o;
		}

		void vertexDataFunc( inout appdata_full v )
		{
			float temp_output_8_0_g61 = _WaterSpeed;
			float2 temp_cast_0 = (temp_output_8_0_g61).xx;
			float3 ase_worldPos = mul( unity_ObjectToWorld, v.vertex );
			float2 appendResult2_g59 = (float2(ase_worldPos.x , ase_worldPos.z));
			float2 ifLocalVar21_g59 = 0;
			if( lerp(0.0,1.0,_InvertCoordinates) <= 0.0 )
				ifLocalVar21_g59 = appendResult2_g59;
			else
				ifLocalVar21_g59 = ( 1.0 - appendResult2_g59 );
			float2 temp_output_7_0_g59 = ( ifLocalVar21_g59 * 0.0066 * _WaterTiling );
			float2 panner1_g61 = ( 0.015 * _Time.y * temp_cast_0 + temp_output_7_0_g59);
			float2 temp_output_568_0 = panner1_g61;
			float2 temp_cast_1 = (-temp_output_8_0_g61).xx;
			float2 panner2_g61 = ( 0.015 * _Time.y * temp_cast_1 + ( ( temp_output_7_0_g59 * 0.77 ) + float2( 0.33,0.66 ) ));
			float2 temp_output_568_9 = panner2_g61;
			float lerpResult496 = lerp( tex2Dlod( _WaterHeight, float4( temp_output_568_0, 0, 0.0) ).r , tex2Dlod( _WaterHeight, float4( temp_output_568_9, 0, 0.0) ).r , 0.5);
			float2 temp_output_486_0 = ( temp_output_568_0 * 0.15 );
			float2 temp_output_487_0 = ( temp_output_568_9 * 0.15 );
			float lerpResult559 = lerp( tex2Dlod( _WaterHeight, float4( temp_output_486_0, 0, 0.0) ).r , tex2Dlod( _WaterHeight, float4( temp_output_487_0, 0, 0.0) ).r , 0.5);
			float temp_output_498_0 = saturate( ( lerpResult496 + ( lerpResult559 * _LargerWavesNormalPower ) ) );
			float3 ase_worldNormal = UnityObjectToWorldNormal( v.normal );
			float3 ase_normWorldNormal = normalize( ase_worldNormal );
		}

		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			#ifdef UNITY_PASS_FORWARDBASE
			float ase_lightAtten = data.atten;
			if( _LightColor0.a == 0)
			ase_lightAtten = 0;
			#else
			float3 ase_lightAttenRGB = gi.light.color / ( ( _LightColor0.rgb ) + 0.000001 );
			float ase_lightAtten = max( max( ase_lightAttenRGB.r, ase_lightAttenRGB.g ), ase_lightAttenRGB.b );
			#endif
			#if defined(HANDLE_SHADOWS_BLENDING_IN_GI)
			half bakedAtten = UnitySampleBakedOcclusion(data.lightmapUV.xy, data.worldPos);
			float zDist = dot(_WorldSpaceCameraPos - data.worldPos, UNITY_MATRIX_V[2].xyz);
			float fadeDist = UnityComputeShadowFadeDistance(data.worldPos, zDist);
			ase_lightAtten = UnityMixRealtimeAndBakedShadows(data.atten, bakedAtten, UnityComputeShadowFade(fadeDist));
			#endif
			float4 ase_screenPos = float4( i.screenPos.xyz , i.screenPos.w + 0.00000000001 );
			float4 ase_screenPosNorm = ase_screenPos / ase_screenPos.w;
			ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
			float screenDepth100 = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture,UNITY_PROJ_COORD( ase_screenPos ))));
			float distanceDepth100 = saturate( abs( ( screenDepth100 - LinearEyeDepth( ase_screenPosNorm.z ) ) / ( _ShoreBlendDistance ) ) );
			float temp_output_8_0_g61 = _WaterSpeed;
			float2 temp_cast_0 = (temp_output_8_0_g61).xx;
			float3 ase_worldPos = i.worldPos;
			float2 appendResult2_g59 = (float2(ase_worldPos.x , ase_worldPos.z));
			float2 ifLocalVar21_g59 = 0;
			if( lerp(0.0,1.0,_InvertCoordinates) <= 0.0 )
				ifLocalVar21_g59 = appendResult2_g59;
			else
				ifLocalVar21_g59 = ( 1.0 - appendResult2_g59 );
			float2 temp_output_7_0_g59 = ( ifLocalVar21_g59 * 0.0066 * _WaterTiling );
			float2 panner1_g61 = ( 0.015 * _Time.y * temp_cast_0 + temp_output_7_0_g59);
			float2 temp_output_568_0 = panner1_g61;
			float2 temp_cast_1 = (-temp_output_8_0_g61).xx;
			float2 panner2_g61 = ( 0.015 * _Time.y * temp_cast_1 + ( ( temp_output_7_0_g59 * 0.77 ) + float2( 0.33,0.66 ) ));
			float2 temp_output_568_9 = panner2_g61;
			float3 lerpResult224 = lerp( UnpackNormal( tex2D( _WaterNormal, temp_output_568_0 ) ) , UnpackNormal( tex2D( _WaterNormal, temp_output_568_9 ) ) , 0.5);
			float2 temp_output_486_0 = ( temp_output_568_0 * 0.15 );
			float2 temp_output_487_0 = ( temp_output_568_9 * 0.15 );
			float3 lerpResult489 = lerp( UnpackNormal( tex2D( _WaterNormal, temp_output_486_0 ) ) , UnpackNormal( tex2D( _WaterNormal, temp_output_487_0 ) ) , 0.5);
			float3 lerpResult283 = lerp( float3(0,0,1) , ( lerpResult224 + ( lerpResult489 * _LargerWavesNormalPower ) ) , _NormalPower);
			float3 indirectNormal261 = WorldNormalVector( i , lerpResult283 );
			Unity_GlossyEnvironmentData g261 = UnityGlossyEnvironmentSetup( _Gloss, data.worldViewDir, indirectNormal261, float3(0,0,0));
			float3 indirectSpecular261 = UnityGI_IndirectSpecular( data, 1.0, indirectNormal261, g261 );
			float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( ase_screenPos );
			float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
			float2 appendResult525 = (float2(ase_grabScreenPosNorm.r , ase_grabScreenPosNorm.g));
			float3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float fresnelNdotV256 = dot( normalize( normalize( (WorldNormalVector( i , lerpResult283 )) ) ), ase_worldViewDir );
			float fresnelNode256 = ( 0.0 + 1.0 * pow( 1.0 - fresnelNdotV256, _ReflectionFresnel ) );
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			float3 ase_worldlightDir = 0;
			#else //aseld
			float3 ase_worldlightDir = Unity_SafeNormalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			float3 normalizeResult4_g62 = normalize( ( ase_worldViewDir + ase_worldlightDir ) );
			float dotResult410 = dot( normalizeResult4_g62 , ase_worldlightDir );
			float dotResult409 = dot( ase_worldlightDir , normalize( (WorldNormalVector( i , lerpResult283 )) ) );
			float temp_output_424_0 = saturate( (-1.66 + (saturate( ( 1.0 - dotResult409 ) ) - 0.0) * (1.0 - -1.66) / (1.0 - 0.0)) );
			float4 transform412 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
			float4 temp_output_466_0 = ( _ScatteringTint * 0.33 );
			float lerpResult496 = lerp( tex2D( _WaterHeight, temp_output_568_0 ).r , tex2D( _WaterHeight, temp_output_568_9 ).r , 0.5);
			float lerpResult559 = lerp( tex2D( _WaterHeight, temp_output_486_0 ).r , tex2D( _WaterHeight, temp_output_487_0 ).r , 0.5);
			float temp_output_498_0 = saturate( ( lerpResult496 + ( lerpResult559 * _LargerWavesNormalPower ) ) );
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aselc
			float4 ase_lightColor = 0;
			#else //aselc
			float4 ase_lightColor = _LightColor0;
			#endif //aselc
			float temp_output_8_0_g64 = _FoamSpeed;
			float2 temp_cast_3 = (temp_output_8_0_g64).xx;
			float2 appendResult2_g63 = (float2(ase_worldPos.x , ase_worldPos.z));
			float2 ifLocalVar21_g63 = 0;
			if( 0.0 <= 0.0 )
				ifLocalVar21_g63 = appendResult2_g63;
			else
				ifLocalVar21_g63 = ( 1.0 - appendResult2_g63 );
			float2 temp_output_7_0_g63 = ( ifLocalVar21_g63 * 0.0066 * ( _FoamTiling * 10.0 ) );
			float2 panner1_g64 = ( 0.015 * _Time.y * temp_cast_3 + temp_output_7_0_g63);
			float2 temp_cast_4 = (-temp_output_8_0_g64).xx;
			float2 panner2_g64 = ( 0.015 * _Time.y * temp_cast_4 + ( ( temp_output_7_0_g63 * 0.77 ) + float2( 0.33,0.66 ) ));
			float lerpResult74 = lerp( tex2D( _Foam, panner1_g64 ).r , tex2D( _Foam, panner2_g64 ).r , 0.5);
			float screenDepth75 = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture,UNITY_PROJ_COORD( ase_screenPos ))));
			float distanceDepth75 = saturate( abs( ( screenDepth75 - LinearEyeDepth( ase_screenPosNorm.z ) ) / ( _FoamDistance ) ) );
			float4 temp_cast_5 = (( lerpResult74 * ( 1.0 - distanceDepth75 ) * _FoamIntensity )).xxxx;
			float eyeDepth14_g65 = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture,UNITY_PROJ_COORD( ase_screenPos ))));
			float4 ase_vertex4Pos = mul( unity_WorldToObject, float4( i.worldPos , 1 ) );
			float3 ase_viewPos = UnityObjectToViewPos( ase_vertex4Pos );
			float ase_screenDepth = -ase_viewPos.z;
			float temp_output_2_0_g65 = ( ( eyeDepth14_g65 - ase_screenDepth ) * _Density );
			float4 appendResult3_g65 = (float4(temp_output_2_0_g65 , temp_output_2_0_g65 , temp_output_2_0_g65 , temp_output_2_0_g65));
			float4 temp_cast_6 = (-0.1).xxxx;
			float4 temp_cast_7 = (1.0).xxxx;
			float4 temp_cast_8 = (0.0).xxxx;
			float4 temp_cast_9 = (4.0).xxxx;
			float screenDepth515 = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture,UNITY_PROJ_COORD( ase_screenPos ))));
			float distanceDepth515 = saturate( abs( ( screenDepth515 - LinearEyeDepth( ase_screenPosNorm.z ) ) / ( 3.0 ) ) );
			float clampResult562 = clamp( distanceDepth515 , 0.6 , 1.0 );
			float cameraDepthFade555 = (( ase_screenDepth -_ProjectionParams.y - 0.0 ) / 66.0);
			float clampResult552 = clamp( ( 1.0 - cameraDepthFade555 ) , 0.3 , 1.0 );
			float temp_output_548_0 = clampResult552;
			float4 screenColor538 = tex2Dproj( _GrabTexture, UNITY_PROJ_COORD( ( ( float4( ( (lerpResult283).xy * clampResult562 ), 0.0 , 0.0 ) + ase_grabScreenPosNorm ) + float4( ( float2( -0.1,-0.1 ) * temp_output_548_0 ), 0.0 , 0.0 ) ) ) );
			float4 screenColor40 = tex2Dproj( _GrabTexture, UNITY_PROJ_COORD( ( float4( ( (lerpResult283).xy * clampResult562 ), 0.0 , 0.0 ) + ase_grabScreenPosNorm ) ) );
			float4 screenColor539 = tex2Dproj( _GrabTexture, UNITY_PROJ_COORD( ( ( float4( ( (lerpResult283).xy * clampResult562 ), 0.0 , 0.0 ) + ase_grabScreenPosNorm ) + float4( ( float2( 0.1,0.1 ) * temp_output_548_0 ), 0.0 , 0.0 ) ) ) );
			float3 appendResult547 = (float3(screenColor538.r , screenColor40.g , screenColor539.b));
			float4 blendOpSrc97 = temp_cast_5;
			float4 blendOpDest97 = ( pow( saturate( (temp_cast_7 + (appendResult3_g65 - temp_cast_6) * (temp_cast_8 - temp_cast_7) / (( _WaterTint * 7.0 ) - temp_cast_6)) ) , temp_cast_9 ) * float4( appendResult547 , 0.0 ) );
			float4 blendOpSrc467 = ( ( ( saturate( (-0.2 + (saturate( ( 1.0 - dotResult410 ) ) - 0.0) * (1.0 - -0.2) / (1.0 - 0.0)) ) * temp_output_424_0 * saturate( ( ase_worldPos.y - ( transform412.y + _ScatteringOffset ) ) ) * ( temp_output_466_0 * _ScatteringIntensity ) * saturate( temp_output_498_0 ) ) + ( temp_output_466_0 * _WaterEmission ) ) * ase_lightColor * ase_lightAtten );
			float4 blendOpDest467 = ( saturate( ( 1.0 - ( 1.0 - blendOpSrc97 ) * ( 1.0 - blendOpDest97 ) ) ));
			float4 blendOpSrc138 = ( float4( indirectSpecular261 , 0.0 ) * saturate( fresnelNode256 ) * ase_lightAtten );
			float4 blendOpDest138 = ( ( saturate( ( 1.0 - ( 1.0 - blendOpSrc467 ) * ( 1.0 - blendOpDest467 ) ) )) * ase_lightColor * ase_lightAtten );
			float dotResult389 = dot( ase_worldlightDir , normalize( WorldReflectionVector( i , lerpResult283 ) ) );
			float clampResult399 = clamp( _Gloss , 0.05 , 1.0 );
			c.rgb = ( ( saturate( ( 1.0 - ( 1.0 - blendOpSrc138 ) * ( 1.0 - blendOpDest138 ) ) )) + ( pow( saturate( dotResult389 ) , exp2( (1.0 + (_Gloss - 0.0) * (11.0 - 1.0) / (1.0 - 0.0)) ) ) * _SpecularPower * ase_lightColor * ase_lightAtten * clampResult399 ) ).rgb;
			c.a = distanceDepth100;
			return c;
//return half4(_LightColor0);
		}

		inline void LightingStandardCustomLighting_GI( inout SurfaceOutputCustomLightingCustom s, UnityGIInput data, inout UnityGI gi )
		{
			s.GIData = data;
		}

		void surf( Input i , inout SurfaceOutputCustomLightingCustom o )
		{
			o.SurfInput = i;
			o.Normal = float3(0,0,1);
		}

		

// vertex-to-fragment interpolation data
// no lightmaps:
#ifndef LIGHTMAP_ON
// half-precision fragment shader registers:
#ifdef UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS
#define FOG_COMBINED_WITH_TSPACE
struct v2f_surf {
  UNITY_POSITION(pos);
  float4 tSpace0 : TEXCOORD0;
  float4 tSpace1 : TEXCOORD1;
  float4 tSpace2 : TEXCOORD2;
  float4 screenPos : TEXCOORD3;
  #if UNITY_SHOULD_SAMPLE_SH
  half3 sh : TEXCOORD4; // SH
  #endif
  UNITY_LIGHTING_COORDS(5,6)
  #if SHADER_TARGET >= 30
  float4 lmap : TEXCOORD7;
  #endif
  UNITY_VERTEX_INPUT_INSTANCE_ID
  UNITY_VERTEX_OUTPUT_STEREO
};
#endif
// high-precision fragment shader registers:
#ifndef UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS
struct v2f_surf {
  UNITY_POSITION(pos);
  float4 tSpace0 : TEXCOORD0;
  float4 tSpace1 : TEXCOORD1;
  float4 tSpace2 : TEXCOORD2;
  float4 screenPos : TEXCOORD3;
  #if UNITY_SHOULD_SAMPLE_SH
  half3 sh : TEXCOORD4; // SH
  #endif
  UNITY_FOG_COORDS(5)
  UNITY_SHADOW_COORDS(6)
  #if SHADER_TARGET >= 30
  float4 lmap : TEXCOORD7;
  #endif
  UNITY_VERTEX_INPUT_INSTANCE_ID
  UNITY_VERTEX_OUTPUT_STEREO
};
#endif
#endif
// with lightmaps:
#ifdef LIGHTMAP_ON
// half-precision fragment shader registers:
#ifdef UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS
#define FOG_COMBINED_WITH_TSPACE
struct v2f_surf {
  UNITY_POSITION(pos);
  float4 tSpace0 : TEXCOORD0;
  float4 tSpace1 : TEXCOORD1;
  float4 tSpace2 : TEXCOORD2;
  float4 screenPos : TEXCOORD3;
  float4 lmap : TEXCOORD4;
  UNITY_LIGHTING_COORDS(5,6)
  UNITY_VERTEX_INPUT_INSTANCE_ID
  UNITY_VERTEX_OUTPUT_STEREO
};
#endif
// high-precision fragment shader registers:
#ifndef UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS
struct v2f_surf {
  UNITY_POSITION(pos);
  float4 tSpace0 : TEXCOORD0;
  float4 tSpace1 : TEXCOORD1;
  float4 tSpace2 : TEXCOORD2;
  float4 screenPos : TEXCOORD3;
  float4 lmap : TEXCOORD4;
  UNITY_FOG_COORDS(5)
  UNITY_SHADOW_COORDS(6)
  UNITY_VERTEX_INPUT_INSTANCE_ID
  UNITY_VERTEX_OUTPUT_STEREO
};
#endif
#endif

// vertex shader
v2f_surf vert_surf (appdata_full v) {
  UNITY_SETUP_INSTANCE_ID(v);
  v2f_surf o;
  UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
  UNITY_TRANSFER_INSTANCE_ID(v,o);
  UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
  vertexDataFunc (v);
  o.pos = UnityObjectToClipPos(v.vertex);
  float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
  float3 worldNormal = UnityObjectToWorldNormal(v.normal);
  fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
  fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
  fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
  o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
  o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
  o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
  o.screenPos = ComputeScreenPos (o.pos);
  #ifdef DYNAMICLIGHTMAP_ON
  o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
  #endif
  #ifdef LIGHTMAP_ON
  o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
  #endif

  // SH/ambient and vertex lights
  #ifndef LIGHTMAP_ON
    #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
      o.sh = 0;
      // Approximated illumination from non-important point lights
      #ifdef VERTEXLIGHT_ON
        o.sh += Shade4PointLights (
          unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
          unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
          unity_4LightAtten0, worldPos, worldNormal);
      #endif
      o.sh = ShadeSHPerVertex (worldNormal, o.sh);
    #endif
  #endif // !LIGHTMAP_ON

  UNITY_TRANSFER_LIGHTING(o,v.texcoord1.xy); // pass shadow and, possibly, light cookie coordinates to pixel shader
  #ifdef FOG_COMBINED_WITH_TSPACE
    UNITY_TRANSFER_FOG_COMBINED_WITH_TSPACE(o,o.pos); // pass fog coordinates to pixel shader
  #elif defined (FOG_COMBINED_WITH_WORLD_POS)
    UNITY_TRANSFER_FOG_COMBINED_WITH_WORLD_POS(o,o.pos); // pass fog coordinates to pixel shader
  #else
    UNITY_TRANSFER_FOG(o,o.pos); // pass fog coordinates to pixel shader
  #endif
  return o;
}

// fragment shader
fixed4 frag_surf (v2f_surf IN) : SV_Target {
  UNITY_SETUP_INSTANCE_ID(IN);
  // prepare and unpack data
  Input surfIN;
  #ifdef FOG_COMBINED_WITH_TSPACE
    UNITY_EXTRACT_FOG_FROM_TSPACE(IN);
  #elif defined (FOG_COMBINED_WITH_WORLD_POS)
    UNITY_EXTRACT_FOG_FROM_WORLD_POS(IN);
  #else
    UNITY_EXTRACT_FOG(IN);
  #endif
  #ifdef FOG_COMBINED_WITH_TSPACE
    UNITY_RECONSTRUCT_TBN(IN);
  #else
    UNITY_EXTRACT_TBN(IN);
  #endif
  UNITY_INITIALIZE_OUTPUT(Input,surfIN);
  surfIN.worldPos.x = 1.0;
  surfIN.screenPos.x = 1.0;
  surfIN.worldNormal.x = 1.0;
  surfIN.worldRefl.x = 1.0;
  float3 worldPos = float3(IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w);
  #ifndef USING_DIRECTIONAL_LIGHT
    fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
  #else
    fixed3 lightDir = _WorldSpaceLightPos0.xyz;
  #endif
  float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
  surfIN.worldRefl = -worldViewDir;
  surfIN.worldNormal = 0.0;
  surfIN.internalSurfaceTtoW0 = _unity_tbn_0;
  surfIN.internalSurfaceTtoW1 = _unity_tbn_1;
  surfIN.internalSurfaceTtoW2 = _unity_tbn_2;
  surfIN.screenPos = IN.screenPos;
  surfIN.worldPos = worldPos;
  #ifdef UNITY_COMPILER_HLSL
  SurfaceOutputCustomLightingCustom o = (SurfaceOutputCustomLightingCustom)0;
  #else
  SurfaceOutputCustomLightingCustom o;
  #endif
  o.Albedo = 0.0;
  o.Emission = 0.0;
  o.Alpha = 0.0;
  o.Occlusion = 1.0;
  fixed3 normalWorldVertex = fixed3(0,0,1);
  o.Normal = fixed3(0,0,1);

  // call surface function
  surf (surfIN, o);

  // compute lighting & shadowing factor
  UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
  fixed4 c = 0;
  float3 worldN;
  worldN.x = dot(_unity_tbn_0, o.Normal);
  worldN.y = dot(_unity_tbn_1, o.Normal);
  worldN.z = dot(_unity_tbn_2, o.Normal);
  worldN = normalize(worldN);
  o.Normal = worldN;

  // Setup lighting environment
  UnityGI gi;
  UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
  gi.indirect.diffuse = 0;
  gi.indirect.specular = 0;
  gi.light.color = _LightColor0.rgb;
  gi.light.dir = lightDir;
  // Call GI (lightmaps/SH/reflections) lighting function
  UnityGIInput giInput;
  UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
  giInput.light = gi.light;
  giInput.worldPos = worldPos;
  giInput.worldViewDir = worldViewDir;
  giInput.atten = atten;
  #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
    giInput.lightmapUV = IN.lmap;
  #else
    giInput.lightmapUV = 0.0;
  #endif
  #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
    giInput.ambient = IN.sh;
  #else
    giInput.ambient.rgb = 0.0;
  #endif
  giInput.probeHDR[0] = unity_SpecCube0_HDR;
  giInput.probeHDR[1] = unity_SpecCube1_HDR;
  #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
    giInput.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
  #endif
  #ifdef UNITY_SPECCUBE_BOX_PROJECTION
    giInput.boxMax[0] = unity_SpecCube0_BoxMax;
    giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
    giInput.boxMax[1] = unity_SpecCube1_BoxMax;
    giInput.boxMin[1] = unity_SpecCube1_BoxMin;
    giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
  #endif
  LightingStandardCustomLighting_GI(o, giInput, gi);

  // realtime lighting: call lighting function
  c += LightingStandardCustomLighting (o, worldViewDir, gi);
  UNITY_APPLY_FOG(_unity_fogCoord, c); // apply fog
  return c;
}

ENDHLSL

}

	// ---- meta information extraction pass:
	Pass {
		Name "Meta"
		Tags { "LightMode" = "Meta" }
		Cull Off

HLSLPROGRAM
// compile directives
#pragma vertex vert_surf
#pragma fragment frag_surf
#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
#pragma shader_feature EDITOR_VISUALIZATION

// -------- variant for: <when no other keywords are defined>
// Surface shader code generated based on:
// vertex modifier: 'vertexDataFunc'
// writes to per-pixel normal: YES
// writes to emission: no
// writes to occlusion: no
// needs world space reflection vector: no
// needs world space normal vector: no
// needs screen space position: no
// needs world space position: no
// needs view direction: no
// needs world space view direction: no
// needs world space position for lighting: YES
// needs world space view direction for lighting: YES
// needs world space view direction for lightmaps: no
// needs vertex color: no
// needs VFACE: no
// passes tangent-to-world matrix to pixel shader: YES
// reads from normal: no
// 0 texcoords actually used
#include "UnityCG.cginc"
#include "Lighting.cginc"

#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
#define WorldNormalVector(data,normal) fixed3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))

// Original surface shader snippet:
#line 36 ""
#ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
#endif
/* UNITY: Original start of shader */
		#include "UnityPBSLighting.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityCG.cginc"
		#include "Tessellation.cginc"
		//#pragma target 3.0
		//#pragma surface surf StandardCustomLighting keepalpha vertex:vertexDataFunc 
		struct Input
		{
			float3 worldPos;
			float4 screenPos;
			float3 worldNormal;
			INTERNAL_DATA
			float3 worldRefl;
		};

		struct SurfaceOutputCustomLightingCustom
		{
			half3 Albedo;
			half3 Normal;
			half3 Emission;
			half Metallic;
			half Smoothness;
			half Occlusion;
			half Alpha;
			Input SurfInput;
			UnityGIInput GIData;
		};

		uniform sampler2D _WaterHeight;
		uniform float _WaterSpeed;
		uniform float _InvertCoordinates;
		uniform float _WaterTiling;
		uniform float _LargerWavesNormalPower;
		uniform sampler2D _CameraDepthTexture;
		uniform float _ShoreBlendDistance;
		uniform sampler2D _WaterNormal;
		uniform float _NormalPower;
		uniform float _Gloss;
		uniform samplerCUBE _Cube;
		uniform float _ReflectionFresnel;
		uniform float _ScatteringOffset;
		uniform float4 _ScatteringTint;
		uniform float _ScatteringIntensity;
		uniform float _WaterEmission;
		uniform sampler2D _Foam;
		uniform float _FoamSpeed;
		uniform float _FoamTiling;
		uniform float _FoamDistance;
		uniform float _FoamIntensity;
		uniform float _Density;
		uniform float4 _WaterTint;
		uniform sampler2D _GrabTexture;
		uniform float _SpecularPower;

		inline float4 ASE_ComputeGrabScreenPos( float4 pos )
		{
			#if UNITY_UV_STARTS_AT_TOP
			float scale = -1.0;
			#else
			float scale = 1.0;
			#endif
			float4 o = pos;
			o.y = pos.w * 0.5f;
			o.y = ( pos.y - o.y ) * _ProjectionParams.x * scale + o.y;
			return o;
		}

		void vertexDataFunc( inout appdata_full v )
		{
			float temp_output_8_0_g61 = _WaterSpeed;
			float2 temp_cast_0 = (temp_output_8_0_g61).xx;
			float3 ase_worldPos = mul( unity_ObjectToWorld, v.vertex );
			float2 appendResult2_g59 = (float2(ase_worldPos.x , ase_worldPos.z));
			float2 ifLocalVar21_g59 = 0;
			if( lerp(0.0,1.0,_InvertCoordinates) <= 0.0 )
				ifLocalVar21_g59 = appendResult2_g59;
			else
				ifLocalVar21_g59 = ( 1.0 - appendResult2_g59 );
			float2 temp_output_7_0_g59 = ( ifLocalVar21_g59 * 0.0066 * _WaterTiling );
			float2 panner1_g61 = ( 0.015 * _Time.y * temp_cast_0 + temp_output_7_0_g59);
			float2 temp_output_568_0 = panner1_g61;
			float2 temp_cast_1 = (-temp_output_8_0_g61).xx;
			float2 panner2_g61 = ( 0.015 * _Time.y * temp_cast_1 + ( ( temp_output_7_0_g59 * 0.77 ) + float2( 0.33,0.66 ) ));
			float2 temp_output_568_9 = panner2_g61;
			float lerpResult496 = lerp( tex2Dlod( _WaterHeight, float4( temp_output_568_0, 0, 0.0) ).r , tex2Dlod( _WaterHeight, float4( temp_output_568_9, 0, 0.0) ).r , 0.5);
			float2 temp_output_486_0 = ( temp_output_568_0 * 0.15 );
			float2 temp_output_487_0 = ( temp_output_568_9 * 0.15 );
			float lerpResult559 = lerp( tex2Dlod( _WaterHeight, float4( temp_output_486_0, 0, 0.0) ).r , tex2Dlod( _WaterHeight, float4( temp_output_487_0, 0, 0.0) ).r , 0.5);
			float temp_output_498_0 = saturate( ( lerpResult496 + ( lerpResult559 * _LargerWavesNormalPower ) ) );
			float3 ase_worldNormal = UnityObjectToWorldNormal( v.normal );
			float3 ase_normWorldNormal = normalize( ase_worldNormal );
		}

		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			#ifdef UNITY_PASS_FORWARDBASE
			float ase_lightAtten = data.atten;
			if( _LightColor0.a == 0)
			ase_lightAtten = 0;
			#else
			float3 ase_lightAttenRGB = gi.light.color / ( ( _LightColor0.rgb ) + 0.000001 );
			float ase_lightAtten = max( max( ase_lightAttenRGB.r, ase_lightAttenRGB.g ), ase_lightAttenRGB.b );
			#endif
			#if defined(HANDLE_SHADOWS_BLENDING_IN_GI)
			half bakedAtten = UnitySampleBakedOcclusion(data.lightmapUV.xy, data.worldPos);
			float zDist = dot(_WorldSpaceCameraPos - data.worldPos, UNITY_MATRIX_V[2].xyz);
			float fadeDist = UnityComputeShadowFadeDistance(data.worldPos, zDist);
			ase_lightAtten = UnityMixRealtimeAndBakedShadows(data.atten, bakedAtten, UnityComputeShadowFade(fadeDist));
			#endif
			float4 ase_screenPos = float4( i.screenPos.xyz , i.screenPos.w + 0.00000000001 );
			float4 ase_screenPosNorm = ase_screenPos / ase_screenPos.w;
			ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
			float screenDepth100 = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture,UNITY_PROJ_COORD( ase_screenPos ))));
			float distanceDepth100 = saturate( abs( ( screenDepth100 - LinearEyeDepth( ase_screenPosNorm.z ) ) / ( _ShoreBlendDistance ) ) );
			float temp_output_8_0_g61 = _WaterSpeed;
			float2 temp_cast_0 = (temp_output_8_0_g61).xx;
			float3 ase_worldPos = i.worldPos;
			float2 appendResult2_g59 = (float2(ase_worldPos.x , ase_worldPos.z));
			float2 ifLocalVar21_g59 = 0;
			if( lerp(0.0,1.0,_InvertCoordinates) <= 0.0 )
				ifLocalVar21_g59 = appendResult2_g59;
			else
				ifLocalVar21_g59 = ( 1.0 - appendResult2_g59 );
			float2 temp_output_7_0_g59 = ( ifLocalVar21_g59 * 0.0066 * _WaterTiling );
			float2 panner1_g61 = ( 0.015 * _Time.y * temp_cast_0 + temp_output_7_0_g59);
			float2 temp_output_568_0 = panner1_g61;
			float2 temp_cast_1 = (-temp_output_8_0_g61).xx;
			float2 panner2_g61 = ( 0.015 * _Time.y * temp_cast_1 + ( ( temp_output_7_0_g59 * 0.77 ) + float2( 0.33,0.66 ) ));
			float2 temp_output_568_9 = panner2_g61;
			float3 lerpResult224 = lerp( UnpackNormal( tex2D( _WaterNormal, temp_output_568_0 ) ) , UnpackNormal( tex2D( _WaterNormal, temp_output_568_9 ) ) , 0.5);
			float2 temp_output_486_0 = ( temp_output_568_0 * 0.15 );
			float2 temp_output_487_0 = ( temp_output_568_9 * 0.15 );
			float3 lerpResult489 = lerp( UnpackNormal( tex2D( _WaterNormal, temp_output_486_0 ) ) , UnpackNormal( tex2D( _WaterNormal, temp_output_487_0 ) ) , 0.5);
			float3 lerpResult283 = lerp( float3(0,0,1) , ( lerpResult224 + ( lerpResult489 * _LargerWavesNormalPower ) ) , _NormalPower);
			float3 indirectNormal261 = WorldNormalVector( i , lerpResult283 );
			Unity_GlossyEnvironmentData g261 = UnityGlossyEnvironmentSetup( _Gloss, data.worldViewDir, indirectNormal261, float3(0,0,0));
			float3 indirectSpecular261 = UnityGI_IndirectSpecular( data, 1.0, indirectNormal261, g261 );
			float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( ase_screenPos );
			float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
			float2 appendResult525 = (float2(ase_grabScreenPosNorm.r , ase_grabScreenPosNorm.g));
			float3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float fresnelNdotV256 = dot( normalize( normalize( (WorldNormalVector( i , lerpResult283 )) ) ), ase_worldViewDir );
			float fresnelNode256 = ( 0.0 + 1.0 * pow( 1.0 - fresnelNdotV256, _ReflectionFresnel ) );
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			float3 ase_worldlightDir = 0;
			#else //aseld
			float3 ase_worldlightDir = Unity_SafeNormalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			float3 normalizeResult4_g62 = normalize( ( ase_worldViewDir + ase_worldlightDir ) );
			float dotResult410 = dot( normalizeResult4_g62 , ase_worldlightDir );
			float dotResult409 = dot( ase_worldlightDir , normalize( (WorldNormalVector( i , lerpResult283 )) ) );
			float temp_output_424_0 = saturate( (-1.66 + (saturate( ( 1.0 - dotResult409 ) ) - 0.0) * (1.0 - -1.66) / (1.0 - 0.0)) );
			float4 transform412 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
			float4 temp_output_466_0 = ( _ScatteringTint * 0.33 );
			float lerpResult496 = lerp( tex2D( _WaterHeight, temp_output_568_0 ).r , tex2D( _WaterHeight, temp_output_568_9 ).r , 0.5);
			float lerpResult559 = lerp( tex2D( _WaterHeight, temp_output_486_0 ).r , tex2D( _WaterHeight, temp_output_487_0 ).r , 0.5);
			float temp_output_498_0 = saturate( ( lerpResult496 + ( lerpResult559 * _LargerWavesNormalPower ) ) );
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aselc
			float4 ase_lightColor = 0;
			#else //aselc
			float4 ase_lightColor = _LightColor0;
			#endif //aselc
			float temp_output_8_0_g64 = _FoamSpeed;
			float2 temp_cast_3 = (temp_output_8_0_g64).xx;
			float2 appendResult2_g63 = (float2(ase_worldPos.x , ase_worldPos.z));
			float2 ifLocalVar21_g63 = 0;
			if( 0.0 <= 0.0 )
				ifLocalVar21_g63 = appendResult2_g63;
			else
				ifLocalVar21_g63 = ( 1.0 - appendResult2_g63 );
			float2 temp_output_7_0_g63 = ( ifLocalVar21_g63 * 0.0066 * ( _FoamTiling * 10.0 ) );
			float2 panner1_g64 = ( 0.015 * _Time.y * temp_cast_3 + temp_output_7_0_g63);
			float2 temp_cast_4 = (-temp_output_8_0_g64).xx;
			float2 panner2_g64 = ( 0.015 * _Time.y * temp_cast_4 + ( ( temp_output_7_0_g63 * 0.77 ) + float2( 0.33,0.66 ) ));
			float lerpResult74 = lerp( tex2D( _Foam, panner1_g64 ).r , tex2D( _Foam, panner2_g64 ).r , 0.5);
			float screenDepth75 = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture,UNITY_PROJ_COORD( ase_screenPos ))));
			float distanceDepth75 = saturate( abs( ( screenDepth75 - LinearEyeDepth( ase_screenPosNorm.z ) ) / ( _FoamDistance ) ) );
			float4 temp_cast_5 = (( lerpResult74 * ( 1.0 - distanceDepth75 ) * _FoamIntensity )).xxxx;
			float eyeDepth14_g65 = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture,UNITY_PROJ_COORD( ase_screenPos ))));
			float4 ase_vertex4Pos = mul( unity_WorldToObject, float4( i.worldPos , 1 ) );
			float3 ase_viewPos = UnityObjectToViewPos( ase_vertex4Pos );
			float ase_screenDepth = -ase_viewPos.z;
			float temp_output_2_0_g65 = ( ( eyeDepth14_g65 - ase_screenDepth ) * _Density );
			float4 appendResult3_g65 = (float4(temp_output_2_0_g65 , temp_output_2_0_g65 , temp_output_2_0_g65 , temp_output_2_0_g65));
			float4 temp_cast_6 = (-0.1).xxxx;
			float4 temp_cast_7 = (1.0).xxxx;
			float4 temp_cast_8 = (0.0).xxxx;
			float4 temp_cast_9 = (4.0).xxxx;
			float screenDepth515 = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture,UNITY_PROJ_COORD( ase_screenPos ))));
			float distanceDepth515 = saturate( abs( ( screenDepth515 - LinearEyeDepth( ase_screenPosNorm.z ) ) / ( 3.0 ) ) );
			float clampResult562 = clamp( distanceDepth515 , 0.6 , 1.0 );
			float cameraDepthFade555 = (( ase_screenDepth -_ProjectionParams.y - 0.0 ) / 66.0);
			float clampResult552 = clamp( ( 1.0 - cameraDepthFade555 ) , 0.3 , 1.0 );
			float temp_output_548_0 = clampResult552;
			float4 screenColor538 = tex2Dproj( _GrabTexture, UNITY_PROJ_COORD( ( ( float4( ( (lerpResult283).xy * clampResult562 ), 0.0 , 0.0 ) + ase_grabScreenPosNorm ) + float4( ( float2( -0.1,-0.1 ) * temp_output_548_0 ), 0.0 , 0.0 ) ) ) );
			float4 screenColor40 = tex2Dproj( _GrabTexture, UNITY_PROJ_COORD( ( float4( ( (lerpResult283).xy * clampResult562 ), 0.0 , 0.0 ) + ase_grabScreenPosNorm ) ) );
			float4 screenColor539 = tex2Dproj( _GrabTexture, UNITY_PROJ_COORD( ( ( float4( ( (lerpResult283).xy * clampResult562 ), 0.0 , 0.0 ) + ase_grabScreenPosNorm ) + float4( ( float2( 0.1,0.1 ) * temp_output_548_0 ), 0.0 , 0.0 ) ) ) );
			float3 appendResult547 = (float3(screenColor538.r , screenColor40.g , screenColor539.b));
			float4 blendOpSrc97 = temp_cast_5;
			float4 blendOpDest97 = ( pow( saturate( (temp_cast_7 + (appendResult3_g65 - temp_cast_6) * (temp_cast_8 - temp_cast_7) / (( _WaterTint * 7.0 ) - temp_cast_6)) ) , temp_cast_9 ) * float4( appendResult547 , 0.0 ) );
			float4 blendOpSrc467 = ( ( ( saturate( (-0.2 + (saturate( ( 1.0 - dotResult410 ) ) - 0.0) * (1.0 - -0.2) / (1.0 - 0.0)) ) * temp_output_424_0 * saturate( ( ase_worldPos.y - ( transform412.y + _ScatteringOffset ) ) ) * ( temp_output_466_0 * _ScatteringIntensity ) * saturate( temp_output_498_0 ) ) + ( temp_output_466_0 * _WaterEmission ) ) * ase_lightColor * ase_lightAtten );
			float4 blendOpDest467 = ( saturate( ( 1.0 - ( 1.0 - blendOpSrc97 ) * ( 1.0 - blendOpDest97 ) ) ));
			float4 blendOpSrc138 = ( float4( indirectSpecular261 , 0.0 ) * saturate( fresnelNode256 ) * ase_lightAtten );
			float4 blendOpDest138 = ( ( saturate( ( 1.0 - ( 1.0 - blendOpSrc467 ) * ( 1.0 - blendOpDest467 ) ) )) * ase_lightColor * ase_lightAtten );
			float dotResult389 = dot( ase_worldlightDir , normalize( WorldReflectionVector( i , lerpResult283 ) ) );
			float clampResult399 = clamp( _Gloss , 0.05 , 1.0 );
			c.rgb = ( ( saturate( ( 1.0 - ( 1.0 - blendOpSrc138 ) * ( 1.0 - blendOpDest138 ) ) )) + ( pow( saturate( dotResult389 ) , exp2( (1.0 + (_Gloss - 0.0) * (11.0 - 1.0) / (1.0 - 0.0)) ) ) * _SpecularPower * ase_lightColor * ase_lightAtten * clampResult399 ) ).rgb;
			c.a = distanceDepth100;
			return c;
		}

		inline void LightingStandardCustomLighting_GI( inout SurfaceOutputCustomLightingCustom s, UnityGIInput data, inout UnityGI gi )
		{
			s.GIData = data;
		}

		void surf( Input i , inout SurfaceOutputCustomLightingCustom o )
		{
			o.SurfInput = i;
			o.Normal = float3(0,0,1);
		}

		
#include "UnityMetaPass.cginc"

// vertex-to-fragment interpolation data
struct v2f_surf {
  UNITY_POSITION(pos);
  float4 tSpace0 : TEXCOORD0;
  float4 tSpace1 : TEXCOORD1;
  float4 tSpace2 : TEXCOORD2;
#ifdef EDITOR_VISUALIZATION
  float2 vizUV : TEXCOORD3;
  float4 lightCoord : TEXCOORD4;
#endif
  UNITY_VERTEX_INPUT_INSTANCE_ID
  UNITY_VERTEX_OUTPUT_STEREO
};

// vertex shader
v2f_surf vert_surf (appdata_full v) {
  UNITY_SETUP_INSTANCE_ID(v);
  v2f_surf o;
  UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
  UNITY_TRANSFER_INSTANCE_ID(v,o);
  UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
  vertexDataFunc (v);
  o.pos = UnityMetaVertexPosition(v.vertex, v.texcoord1.xy, v.texcoord2.xy, unity_LightmapST, unity_DynamicLightmapST);
#ifdef EDITOR_VISUALIZATION
  o.vizUV = 0;
  o.lightCoord = 0;
  if (unity_VisualizationMode == EDITORVIZ_TEXTURE)
    o.vizUV = UnityMetaVizUV(unity_EditorViz_UVIndex, v.texcoord.xy, v.texcoord1.xy, v.texcoord2.xy, unity_EditorViz_Texture_ST);
  else if (unity_VisualizationMode == EDITORVIZ_SHOWLIGHTMASK)
  {
    o.vizUV = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
    o.lightCoord = mul(unity_EditorViz_WorldToLight, mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1)));
  }
#endif
  float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
  float3 worldNormal = UnityObjectToWorldNormal(v.normal);
  fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
  fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
  fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
  o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
  o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
  o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
  return o;
}

// fragment shader
fixed4 frag_surf (v2f_surf IN) : SV_Target {
  UNITY_SETUP_INSTANCE_ID(IN);
  // prepare and unpack data
  Input surfIN;
  #ifdef FOG_COMBINED_WITH_TSPACE
    UNITY_EXTRACT_FOG_FROM_TSPACE(IN);
  #elif defined (FOG_COMBINED_WITH_WORLD_POS)
    UNITY_EXTRACT_FOG_FROM_WORLD_POS(IN);
  #else
    UNITY_EXTRACT_FOG(IN);
  #endif
  #ifdef FOG_COMBINED_WITH_TSPACE
    UNITY_RECONSTRUCT_TBN(IN);
  #else
    UNITY_EXTRACT_TBN(IN);
  #endif
  UNITY_INITIALIZE_OUTPUT(Input,surfIN);
  surfIN.worldPos.x = 1.0;
  surfIN.screenPos.x = 1.0;
  surfIN.worldNormal.x = 1.0;
  surfIN.worldRefl.x = 1.0;
  float3 worldPos = float3(IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w);
  #ifndef USING_DIRECTIONAL_LIGHT
    fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
  #else
    fixed3 lightDir = _WorldSpaceLightPos0.xyz;
  #endif
  #ifdef UNITY_COMPILER_HLSL
  SurfaceOutputCustomLightingCustom o = (SurfaceOutputCustomLightingCustom)0;
  #else
  SurfaceOutputCustomLightingCustom o;
  #endif
  o.Albedo = 0.0;
  o.Emission = 0.0;
  o.Alpha = 0.0;
  o.Occlusion = 1.0;
  fixed3 normalWorldVertex = fixed3(0,0,1);

  // call surface function
  surf (surfIN, o);
  UnityMetaInput metaIN;
  UNITY_INITIALIZE_OUTPUT(UnityMetaInput, metaIN);
  metaIN.Albedo = o.Albedo;
  metaIN.Emission = o.Emission;
#ifdef EDITOR_VISUALIZATION
  metaIN.VizUV = IN.vizUV;
  metaIN.LightCoord = IN.lightCoord;
#endif
  return UnityMetaFragment(metaIN);
}

ENDHLSL

}

	// ---- end of surface shader generated code

#LINE 264

	}
	Fallback "Diffuse"
}