Shader "sg3/Scene/Building"
{
	Properties
	{
		_MainCol("MainCol", Color) = (1, 1, 1, 1)
		_MainTex ("MainTexture", 2D) = "white" {}
		[NoScaleOffset]_NormalMap ("NormalMap", 2D) = "bump" {}
		_BumpScale("BumpScale", float) = 1
		[Gamma]_Metallic("光泽度", Range(0, 1)) = 0
		_SpecCol("SpecColor", Color) = (1, 1, 1, 1)
		_Shininess("反射率", Range(0.01, 10)) = 0.5
		_EmissionMap ("EmissionMap", 2D) = "white" {}
		_EmissionCol("EmissionCol", Color) = (0, 0, 0, 1)
		_LightMapMML("LightMML", float) = 1
		_CutOff("Cutoff", Range(0, 1)) = 0.5
		[HideInInspector] _SrcBlend ("_SrcBlend", Float) = 1
		[HideInInspector] _DstBlend ("_DstBlend", Float) = 0
		[HideInInspector] _ZWrite ("_ZWrite", Float) = 1
	}

	HLSLINCLUDE
	#define BINORMAL_PER_FRAGMENT
	#define FOG_DISTANCE
	ENDHLSL

	SubShader
	{
		Tags { "RenderPipeline"="UniversalPipeline" }
		//LOD 200
         
		Pass
		{ 
			Name "FORWARD"
			Tags{"LightMode" = "UniversalForward"}
			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			#pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT
			#pragma shader_feature _METALLIC_MAP
			#pragma shader_feature _ _SMOOTHNESS_METALLIC
			#pragma shader_feature _NORMAL_MAP
			#pragma shader_feature _EMISSION_MAP

			#pragma glsl_no_auto_normalization
			#pragma exclude_renderers xboxone ps4 psp2 n3ds wiiu

			#define FORWARD_BASE_PASS


			#include "SceneBase.cginc"
		
			
			ENDHLSL
		}

		

		Pass {
			Name"ShadowCaster"
			Tags{"LightMode" = "ShadowCaster"}

			HLSLPROGRAM
			#pragma target 3.0
			#pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT
			#pragma shader_feature _SEMITRANSPARENT_SHADOWS
			#pragma shader_feature _SMOOTHNESS_METALLIC
			#pragma multi_compile_shadowcaster
			#pragma multi_compile_instancing

			#pragma vertex ShadowVertex
			#pragma fragment ShadowFrag

			#pragma glsl_no_auto_normalization
			#pragma exclude_renderers xboxone ps4 psp2 n3ds wiiu

			#include "Building_Shadows.cginc"

			ENDHLSL
		}

		Pass {
			Name"Meta"
			Tags {"LightMode" = "Meta"}
			Cull Off

			HLSLPROGRAM
			#pragma shader_feature _EMISSION_MAP
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#pragma skip_variants INSTANCING_ON
			
			#pragma glsl_no_auto_normalization
			#pragma exclude_renderers xboxone ps4 psp2 n3ds wiiu

			#pragma vertex metavert
			#pragma fragment metafrag
								
			#define FORWARD_BASE_PASS
			#include "MetaPass.cginc"
			ENDHLSL
		}
	}
	CustomEditor "SceneBaseGUI"
}

