Shader "sg3/Character/LowPoly1"
{
    Properties 
    {
         _Scale ("Scale Compared to Maya", Range(0,1)) = 0.01
         _BloomFactor ("Bloom Factor", Float) = 1
         _MainTex ("Main Tex (RGB)", 2D) = "white" { }
         _Contrast ("Contrast", Range(0,2)) = 1
		 [NoScaleOffset]_MaskTex ("MaskTex", 2D) = "white" { }
		 //[Toggle(SHADOW_ENABLE)] SPECULAR_ENABLE("SPECULAR_ENABLE", Int) = 0
		 _SpecCol("SpecColor", Color) = (1, 1, 1, 1)
		 _SpecPower ("高光范围", Range(0.1,1000)) = 10
		 [NoScaleOffset]_ReflectTex ("反射光(RGB)", 2D) = "white" {}
		 _ReflectColor ("反射光颜色", Color) = (1,1,1,1)
 		 _ReflectPower ("反射光范围", Range(1,64)) = 1
 		 _ReflectionMultiplier ("反射光强度", Float) = 2

		 _RimColor("边缘光颜色", color) = (0.5, 0.5, 0.5, 1.0)
		 _RimPower("边缘光范围", Range(0.1, 128)) = 15.0
		 _rimMultiplier("边缘光强度", Range(1, 20)) = 1.0
         [Toggle(COMPLEX_OUTLINE_MAINTEXCOLOR_ENABLE)] _COMPLEX_OUTLINE_Enable("COMPLEX_OUTLINE", Int) = 0

         _OutlineWidth ("Outline Width", Range(0,1)) = 0.2
         _OutlineColor ("Outline Color", Color) = (0,0,0,1)
         _MaxOutlineZOffset ("Max Outline Z Offset", Range(0,100)) = 1

        
         _shadowColor("ShadowColor", Color) = (0.0, 0.0, 0.0, 0.0)
         _ShadowPlane("ShadowPlane", Vector) = (0.0, 1.0, 0.0, 0.01)
         _ShadowProjDir("ShadowProjDir", Vector) = (1.0, 1.0, 1.0, 1.0)
         _ShadowFadeParams("ShadowFadeParams", Vector) = (2.0, 1.0, 0.5, 1.0)
         _ShadowInvLen("ShadowInvLen", float) = 1.0
    }

    SubShader 
    {      
        Tags {"RenderPipeline"="UniversalPipeline" "lightmode"="UniversalForward" "RenderType"="Opaque" "queue" = "Geometry" "ignoreprojector" = "true"}
        LOD 100

        Pass 
        {
            Name "COMPLEX"
            Tags { "lightmode"="UniversalForward"}
          
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
//            #pragma multi_compile_fwdbase
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

        Pass{
        	Name"shadow map"
        	Tags { "LIGHTMODE"="UniversalForward" "Queue"="Transparent" "RenderType"="Transparent"}
        	Blend SrcAlpha OneMinusSrcAlpha
        	stencil
        	{
        		Ref 0
        		Comp Equal
        		Pass IncrSat
        	}

        	HLSLPROGRAM

        	#pragma vertex vert
            #pragma fragment frag
//            #pragma shader_feature SHADOW_ENABLE

            #include "FakeShadowMap.cginc"

            ENDHLSL
        }
    }
    //fallback"Diffuse"
}
