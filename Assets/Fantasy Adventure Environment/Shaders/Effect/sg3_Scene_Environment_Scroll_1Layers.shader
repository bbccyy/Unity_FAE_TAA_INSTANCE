Shader "sg3/Scene/Environment Scroll 1 Layers Sine NoAlpha"
{
	Properties {
		_MainTex ("Base layer (RGB)", 2D) = "white" {}
		_ScrollX ("Base layer Scroll speed X", Float) = 1.0
		_ScrollY ("Base layer Scroll speed Y", Float) = 0.0
		_SineAmplX ("Base layer sine amplitude X",Float) = 0.5 
		_SineAmplY ("Base layer sine amplitude Y",Float) = 0.5
		_SineFreqX ("Base layer sine freq X",Float) = 10 
		_SineFreqY ("Base layer sine freq Y",Float) = 10
		_Color("Color", Color) = (1,1,1,1)
	
		_MMultiplier ("Layer Multiplier", Float) = 2.0
	}

	SubShader {
		Tags { "RenderType"="Opaque" }
		Lighting Off
		LOD 100		
	
		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest	
			#pragma multi_compile_fwdbase


			#include "EnvironmentScroll.cginc"

			ENDCG

		}
	}
	FallBack "Babeltime/Diffuse"
}