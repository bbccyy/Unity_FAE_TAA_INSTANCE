Shader "sg3/Scene/Unlit"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}

	HLSLINCLUDE
	#define FOG_DISTANCE
	ENDHLSL

	SubShader
	{
		Tags {"RenderPipeline"="UniversalPipeline"  "RenderType"="Opaque" }
		LOD 100

		Pass
		{	
			Tags{"LightMode" = "UniversalForward"}

			Lighting Off

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog

			#define UNLIT_BACKGROUND
			#define FORWARD_BASE_PASS

			#include "SceneBase.cginc"

		
			ENDHLSL
		}
	}
}
