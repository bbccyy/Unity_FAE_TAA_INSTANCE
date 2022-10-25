Shader "sg3/Fx/Particle"
{
	Properties
	{
		[HDR]_TintColor("Tint Color", Color) = (0.5, 0.5, 0.5, 0.5) 
		[Space]

		_VerticalBillboarding("VerticalBillboarding", Range(0, 1)) = 0
		_MainTex ("Texture", 2D) = "white" {}
		_ScrollX("ScrollX Speed X", Float) = 0
		_ScrollY("ScrollY Speed Y", Float) = 0
		_Mask ("Mask", 2D) = "white"{}
		_Scroll2X("Scroll2X Speed X", Float) = 0
		_Scroll2Y("Scroll2Y Speed Y", Float) = 0
		_HorizontalAmount ("Horizontal Amount", Float) = 4 
		_VerticalAmount ("Vertical Amount", Float) = 4 
		_Speed ("Speed", Range(1, 100)) = 30
		_Turbulence ("溶解",2D) = "white"{}
		_NoiseTex ("扰乱", 2D) = "white" {}

		_TurbulenceAmt ("TurbulenceAmt", Range(0, 1)) = 0
		_Cutout ("Cut Out",Range(0,1)) = 0
		_EdgeColor ("Edge Color",Color) = (1,1,1,1)
		_Edge ("Edge Width",Range(0,1)) = 0
		_SoftEdge ("Soft Edge",Range(0,0.5)) = 0

		_ColorPower("Color Power", Range(0, 4)) = 1
		_InvFade("Soft Particles Factor", Range(0.01, 3.0)) = 1.0
		_Intensity ("Intensity", Range(0, 2)) = 1
		_Transparency("Transparency", Range(0, 1)) = 0
		_Palstance("角速度", Float) = 0
		_MaskPalstance("遮罩角速度", Float) = 0
		[HideInInspector] _BlendMode("混合模式", Float) = 0
		[HideInInspector] _SrcBlend ("_SrcBlend", Float) = 1
		[HideInInspector] _DstBlend ("_DstBlend", Float) = 0
		[Toggle(ZWrite)] _ZWrite ("_ZWrite", Float) = 1
		[Enum(CullMode)] _CullMode("剔除模式", Float) = 0
		[HideInInspector] _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
		[Toggle(ZTest)] _ZTest ("总是显示", Float) = 0
		_ZOffset("前后偏移", Range(-10, 10)) = 0       // 用以做特效镜头方向偏移 by Allen, 20190916
	}
	SubShader
	{
	    Tags {"RenderPipeline"="UniversalPipeline"}
		//Tags { "Queue" = "Transparent" "RenderType"="Transparent" "IgnoreProjector" = "True" "PreviewType" = "Plane"}
		Pass
		{
			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]
			Cull [_CullMode]
			ZTest [_ZTest]
			Lighting Off
			ColorMask RGBA


			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			#pragma multi_compile_particles
			#pragma multi_compile_instancing

			#pragma shader_feature _ _RENDERING_UVANIMATION _RENDERING_UVROTATION _RENDERING_DISSOLVE _SEQUENCEANIMATION 
			#pragma shader_feature _TOGGLETURBULENCE _BILLBOARD _BILLBOARDY _TOGGLE_STOP_INNER_ALPHA
			#pragma shader_feature _ _USECUTOFF
			#pragma exclude_renderers xboxone ps4 psp2 n3ds wiiu
			#pragma fragmentoption ARB_precision_hint_fastest	

			#define PARTICLE_TRANSPARENT_ADD	//add by mengzhijiang
			#include "ParticleEF.hlsl"

			ENDHLSL
		}
	}
	CustomEditor "ParticleGUIEF"
}
