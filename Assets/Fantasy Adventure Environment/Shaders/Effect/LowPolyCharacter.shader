Shader "sg3/Character/LowPoly"
{
    Properties 
    {
         _Scale ("Scale Compared to Maya", Range(0,1)) = 0.01
         _BloomFactor ("Bloom Factor", Float) = 1
         _MainTex ("Main Tex (RGB)", 2D) = "white" { }
         _Contrast ("Contrast", Range(0,2)) = 1

         [Toggle(COMPLEX_OUTLINE_MAINTEXCOLOR_ENABLE)] _COMPLEX_OUTLINE_Enable("COMPLEX_OUTLINE", Int) = 0

         _OutlineWidth ("Outline Width", Range(0,1)) = 0.2
         _OutlineColor ("Outline Color", Color) = (0,0,0,1)
         _MaxOutlineZOffset ("Max Outline Z Offset", Range(0,100)) = 1

         [Toggle(SHADOW_ENABLE)] SHADOW_ENABLE("SHADOW_ENABLE", Int) = 0
         _shadowColor("ShadowColor", Color) = (0.0, 0.0, 0.0, 0.0)
         _ShadowPlane("ShadowPlane", Vector) = (1.0, 1.0, 1.0, 1.0)
         _ShadowProjDir("ShadowProjDir", Vector) = (1.0, 1.0, 1.0, 1.0)
         _ShadowFadeParams("ShadowFadeParams", Vector) = (1.0, 1.0, 1.0, 1.0)
         _ShadowInvLen("ShadowInvLen", float) = 1.0
    }

    SubShader 
    {      
        Tags {"RenderPipeline"="UniversalPipeline" "lightmode"="UniversalForward" "RenderType"="Opaque" "queue" = "Geometry" "ignoreprojector" = "true"}
        LOD 100

        Pass 
        {
            Name "COMPLEX"
            Tags { "lightmode"="ShadowCaster"}
          
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
//            #pragma multi_compile_fwdbase
            #pragma shader_feature SPECULAR_ENABLE
//            #pragma fragmentoption ARB_precision_hint_fastest 

 			#define LOWPOLY_CHARACTER
       		#include "Character.cginc"
     		
            ENDHLSL
        }

        // outline pass 
         Pass 
         {
             Name "COMPLEX"
             Tags { "LIGHTMODE"="UniversalForward" "QUEUE"="Geometry" "IGNOREPROJECTOR"="true" "RenderType"="Opaque" "Distortion"="None" "OutlineType"="Complex" "Reflected"="Reflected" }
             Cull Front
            
             HLSLPROGRAM

             #pragma vertex vert
             #pragma fragment frag
             #pragma shader_feature COMPLEX_OUTLINE_MAINTEXCOLOR_ENABLE
             #pragma shader_feature SIMPLE_OUTLINE_MAINTEXCOLOR_ENABLE
            
             #include "CharacterOutline.cginc"

             ENDHLSL
         }


    }
    fallback"Diffuse"
}
