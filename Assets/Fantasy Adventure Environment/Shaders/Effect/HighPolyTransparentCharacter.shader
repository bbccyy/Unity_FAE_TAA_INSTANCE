Shader "sg3/Character/HighPolyCharacter_Transparent"
{
    Properties 
    {
         //_BloomFactor ("Bloom Factor", Float) = 1
         _MainTex ("Main Tex (RGB)", 2D) = "white" { }
         _NormalTex ("Normalmap", 2D) = "bump" {}
		 _BumpScale("BumpScale", float) = 1
         _MaskTex ("MaskTex", 2D) = "white" { }
         _innerRim("内边缘光", float) = 1.0
		 _RimColor("边缘光颜色", color) = (0.5, 0.5, 0.5, 1.0)
		 _RimPower("边缘光范围", float) = 15.0
		 _rimMultiplier("边缘光强度", float) = 1.0
         _SpecCol ("高光颜色", Color) = (1,1,1,1)
         _SpecPower ("高光范围", Range(0.1,1000)) = 10
         _SpecMultiplier ("高光强度", Range(0, 10)) = 1
		 _SkinMaskTex ("SkinMaskTex", 2D) = "white" { }
		 _SkinSpecCol ("皮肤高光颜色", Color) = (1,1,1,1)
         _SkinSpecPower ("皮肤高光范围", Range(0.1,1000)) = 10
         _SkinSpecMultiplier ("皮肤高光强度", Range(0, 10)) = 1
		 _HighScaleX ("Scale X", Range(-1, 1)) = 0
		 _HighScaleY ("Scale Y", Range(-1, 1)) = 0
		 _HighScaleZ ("Scale Z", Range(-1, 1)) = 0
         _NoiseTex ("流光(RGB)", 2D) = "white" {}
         _Scroll2X ("流光速度 X轴", Float) = 1
	 	 _Scroll2Y ("流光速度 Y轴", Float) = 0
//	 	 _TimeOnDuration ("持续时间", Float) = 1
//	 	 _TimeOffDuration ("间隔时间", Float) = 1
	 	 _NoiseColor ("流光颜色", Color) = (1,1,1,1)
	 	 _MMultiplier ("流光强度", Float) = 2

//         _OutlineWidth ("Outline Width", Range(0,1)) = 0.2
//         _OutlineColor ("Outline Color", Color) = (0,0,0,1)
//         _MaxOutlineZOffset ("Max Outline Z Offset", Range(0,100)) = 1

         _LightTex ("轮廓光 (RGB)", 2D) = "white" {}
         _LightColor("轮廓光颜色", color) = (0.5, 0.5, 0.5, 1.0)
		 _LightMultiplier("轮廓光强度", float) = 1.0
         _ReflectTex ("反射光(RGB)", 2D) = "white" {}
 		 _ReflectColor ("反射光颜色", Color) = (1,1,1,1)
 		 _ReflectPower ("反射光范围", Range(0.1,5)) = 1
 		 _ReflectionMultiplier ("反射光强度", Float) = 2
 		 _shadowColor("自阴影颜色", Color) = (0.0, 0.0, 0.0, 0.0)

         _Offset ("高度偏移", Float) = 0.8
 		 _HeightColor ("高度颜色", Color) = (0.5,0.5,0.5,1)
 		 _HeightLightCompensation ("高度增益", Float) = 1

        [HideInInspector]  _Opaqueness ("Opaqueness", Range(0,1)) = 1
        [HideInInspector]  _VertexAlphaFactor ("Alpha From Vertex Factor (0: not use)", Range(0,1)) = 0
		[HideInInspector]_Cutoff ("Alpha Cutoff", Range(0,1)) = 0.1
		[HideInInspector]_Color("Color Tint", Color) = (1,1,1,1)  
    }

    SubShader 
    {      
        Tags {"RenderPipeline"="UniversalPipeline"  "RenderType"="Transparent" "Queue" = "AlphaTest" "Ignoreprojector" = "true"}
		
        LOD 200

        Pass 
        {
            Name "FORWARD"
            Tags { "LightMode" = "UniversalForward"}
			Blend SrcAlpha  OneMinusSrcAlpha
//            Cull Back
            //ZTest LEqual        
			//ZWrite Off  
			//AlphaToMask On
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
//            #pragma fragmentoption ARB_precision_hint_fastest 

			#define HIGHPOLY_CHARACTER
			#define TRANSPARENT
			#include "Character.cginc"


            ENDHLSL
        }
    }
    Fallback "Legacy Shaders/Transparent/Cutout/VertexLit"

}
