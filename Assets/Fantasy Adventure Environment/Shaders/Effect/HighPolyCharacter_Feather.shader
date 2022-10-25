Shader "sg3/Character/HighPolyCharacter_Feather"
{
    Properties 
    {
         _MainTex ("Main Tex (RGB)", 2D) = "white" { }
         _SubTex ("SubTex", 2D) = "white" { }
		 _Wind("Wind", Vector) = (8.0, 30.0, 77.0, 2.0)
		 _Gravity("Gravity", Vector) = (1.5, 0.0, -1.5, 0.0)
         _Spacing("Spacing", float) = 0.18
		 _Tming("Tming", float) = 1.1
    }

    SubShader 
    {      
        Tags {"RenderPipeline"="UniversalPipeline" "LightMode"="UniversalForward" "RenderType"="Transparent" "Queue" = "Transparent" "IgnoreProjector" = "true"}
        LOD 100
		Blend SrcAlpha OneMinusSrcAlpha
	
		HLSLINCLUDE
		#include "UnityCG.cginc"

		sampler2D _MainTex, _SubTex;
		float4 _MainTex_ST, _SubTex_ST, _Wind;

		struct passVertData{
			float3 forceDir;
			float4 uv;
		};
		
		passVertData ForceDir(appdata_base v)
		{
			passVertData data;
			data.forceDir.x = sin(_Time.y * 1.5 * _Wind.x + v.vertex.x * 0.5 * _Wind.z) * _Wind.w;
			data.forceDir.y = cos(_Time.y * 0.5 * _Wind.x + v.vertex.y * 0.4 * _Wind.y) * _Wind.w;
			data.forceDir.z = sin(_Time.y * 0.7 * _Wind.x + v.vertex.y * 0.3 * _Wind.y) * _Wind.w;
			data.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
			data.uv.zw = TRANSFORM_TEX(v.texcoord, _SubTex);
			return data;
		}
		
		ENDHLSL

        Pass 
        {
            HLSLPROGRAM
						
            #pragma vertex vert
            #pragma fragment frag
            //#pragma multi_compile_fwdbase
            #pragma fragmentoption ARB_precision_hint_fastest 

			#define FORCE 0.008
			#define NORMALOFFSET 0.2
			#define SCALE 0.3

			#include "Feather.cginc"
            ENDHLSL
        }

		Pass 
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            //#pragma multi_compile_fwdbase
            #pragma fragmentoption ARB_precision_hint_fastest 

			#define FORCE 0.064
			#define NORMALOFFSET 0.4
			#define SCALE 0.6

			#include "Feather.cginc"
            ENDHLSL
        }

		Pass 
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            //#pragma multi_compile_fwdbase
            #pragma fragmentoption ARB_precision_hint_fastest 
			
			#define FORCE 0.175616
			#define NORMALOFFSET 0.56
			#define SCALE 0.84

			#include "Feather.cginc"
            ENDHLSL
        }

		Pass 
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            //#pragma multi_compile_fwdbase
            #pragma fragmentoption ARB_precision_hint_fastest 
			
			#define FORCE 0.243184
			#define NORMALOFFSET 0.66
			#define SCALE 0.99

			#include "Feather.cginc"
            ENDHLSL
        }

		Pass 
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            //#pragma multi_compile_fwdbase
            #pragma fragmentoption ARB_precision_hint_fastest 

			#define FORCE 0.421875
			#define NORMALOFFSET 0.75
			#define SCALE 1.125

			#include "Feather.cginc"
            ENDHLSL
        }

		Pass 
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            //#pragma multi_compile_fwdbase
            #pragma fragmentoption ARB_precision_hint_fastest 

			#define FORCE 0.704969
			#define NORMALOFFSET 0.89
			#define SCALE 1.335

			#include "Feather.cginc"
            ENDHLSL
        }

		Pass 
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            //#pragma multi_compile_fwdbase
            #pragma fragmentoption ARB_precision_hint_fastest 
			
			#define FORCE 0.9126731
			#define NORMALOFFSET 0.97
			#define SCALE 1.455

			#include "Feather.cginc"
            ENDHLSL
        }
    }
    fallback "Render Pipeline/Liteline/Lit"
}
