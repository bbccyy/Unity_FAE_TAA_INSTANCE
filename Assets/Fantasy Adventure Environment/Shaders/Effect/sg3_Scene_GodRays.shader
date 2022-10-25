Shader "sg3/Scene/Transparent/GodRays"
{
	Properties
	{
		_MainTex ("Base texture", 2D) = "white" {}
		_FadeOutDistNear ("Near fadeout dist", float) = 10	
		_FadeOutDistFar ("Far fadeout dist", float) = 10000	
		_MMultiplier("Multiplier", float) = 1
		_ContractionAmount("Near contraction amount", float) = 5
	}
	SubShader
	{
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
		LOD 100

		Pass
		{
			Blend One One
			Cull Off Lighting Off ZWrite Off Fog { Color (0,0,0,0) }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#define _RAYS 

			#include "EnvironmentScroll.cginc"
			
			ENDCG
		}
	}
}
