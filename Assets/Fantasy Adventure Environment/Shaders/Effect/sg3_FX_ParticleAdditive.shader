Shader "sg3/Fx/ParticleAdditive"
{
	Properties
	{
		_TintColor("Tint Color", Color) = (0.5, 0.5, 0.5, 0.5) 
		[Space]
		[Toggle(ENABLE_SCROLL)] _enable_scroll("Enable Scroll", Int) = 0
		_MainTex ("Texture", 2D) = "white" {}
		_ScrollX("ScrollX Speed X", Float) = 0
		_ScrollY("ScrollY Speed Y", Float) = 0
		_Mask ("Mask", 2D) = "white"{}
		_Scroll2X("Scroll2X Speed X", Float) = 0
		_Scroll2Y("Scroll2Y Speed Y", Float) = 0
		_ColorPower("Color Power", Float) = 2
		_InvFade("Soft Particles Factor", Range(0.01, 3.0)) = 1.0
		_Intensity ("Intensity", Range(0, 2)) = 1
		_Transparency("Transparency", Range(0, 1)) = 0
	}
	SubShader
	{
		Tags {"RenderPipeline"="UniversalPipeline" "Queue" = "Transparent" "RenderType"="Transparent" "IgnoreProjector" = "True" "PreviewType" = "Plane"}
		

		Pass
		{
			Blend SrcAlpha One
			ZWrite Off
			Cull Off
			Lighting Off
			ColorMask RGB


			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			#pragma multi_compile_particles

			#pragma shader_feature ENABLE_SCROLL
			#pragma exclude_renderers xboxone ps4 psp2 n3ds wiiu

			#define PARTICLE_TRANSPARENT_ADD	//add by mengzhijiang
			#include "Particle.hlsl"

			ENDHLSL
		}
	}
	CustomEditor "ParticleGUI"
}
