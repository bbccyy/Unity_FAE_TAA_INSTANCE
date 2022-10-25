Shader "sg3/Scene/Transparent/BlinkRays"
{
	Properties
	{
		_MainTex ("Base texture", 2D) = "white" {}
		//_MainTexAlpha ("Base Alpha (A)", 2D) = "white" {}
		_FadeOutDistNear ("Near fadeout dist", float) = 10	
		_FadeOutDistFar ("Far fadeout dist", float) = 10000	
		_MMultiplier("Color multiplier", float) = 1
		_Bias("Bias",float) = 0
		_TimeOnDuration("ON duration",float) = 0.5
		_TimeOffDuration("OFF duration",float) = 0.5
		_BlinkingTimeOffsScale("Blinking time offset scale (seconds)",float) = 5
		_SizeGrowStartDist("Size grow start dist",float) = 5
		_SizeGrowEndDist("Size grow end dist",float) = 50
		_MaxGrowSize("Max grow size",float) = 2.5
		_NoiseAmount("Noise amount (when zero, pulse wave is used)", Range(0,0.5)) = 0
		_Color("Color", Color) = (1,1,1,1)
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
			#define _BLINK_RAYS
			// make fog work
			//#pragma multi_compile_fog


			#include "EnvironmentScroll.cginc"
			
			ENDCG
		}
	}
}
