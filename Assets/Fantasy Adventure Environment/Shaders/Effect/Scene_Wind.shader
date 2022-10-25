Shader "sg3/Scene/Scene_Wind"
{
	Properties 
	{
		_MainColor ("Main Color", Color) = (1,1,1,1)
		_MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
		_Wind("Wind params",Vector) = (0,0,0,0.25)
		_WindEdgeFlutter("Wind edge fultter factor", float) = 0.5
		_WindEdgeFlutterFreqScale("Wind edge fultter freq scale",float) = 0.5
	}
	
	SubShader
	{
		Tags {"RenderPipeline"="UniversalPipeline"  "Queue"="Geometry" "RenderType"="Opaque" "LightMode"="UniversalForward" }
		
		Pass
		{
			LOD 100
			//Blend SrcAlpha OneMinusSrcAlpha
			Cull Off 
			ColorMask RGB // add for Alpha Glow
		
			HLSLPROGRAM
				#pragma multi_compile_fog
				#pragma vertex vert
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest
				#include "UnityCG.cginc"
				//#include "TerrainEngine.cginc"
				#define STAGE_WIND
				#include "SceneWind.cginc"
			ENDHLSL 
		}
	}
	
	FallBack "Babeltime/Diffuse"
}
