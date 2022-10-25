Shader "sg3/Fx/shatterfireAdd"
{
	Properties {
		_MainTex ("MainTex", 2D) = "white" {}
		_Mask ("Noise", 2D) = "white" {}
        _NoiseTex ("NoiseTex", 2D) = "white" {}
        _ScrollX ("USpeed", Float ) = 0.5
        _ScrollY ("VSpeed", Float ) = 0.5
        _TurbulenceAmt ("TurbulenceAmt", Range(0, 1)) = 0.7863248
		_Intensity ("Intensity", Range(0, 2)) = 1
		_Transparency("Transparency", Range(0, 1)) = 0
    }
    SubShader {
        Tags {"RenderPipeline"="UniversalPipeline" "IgnoreProjector"="True" "Queue"="Transparent" "RenderType"="Transparent" "PreviewType"="Plane"}


        Pass {
            Name "FORWARD"
//            Tags {"LightMode"="ForwardBase"}
			Blend One One
            Cull Off
            ZWrite Off
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
//            #pragma multi_compile_particles
          	#pragma exclude_renderers xboxone ps4 psp2 n3ds wiiu

          	#define SHATTER_TURBULENCE
			#define PARTICLE_TRANSPARENT_ADD	//add by mengzhijiang

          	#include "Particle.hlsl"

            ENDHLSL
        }
    }
}