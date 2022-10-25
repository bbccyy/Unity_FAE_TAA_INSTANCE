Shader "Babeitime/Scene/Alpha Cutout"
{
    Properties 
    {
        [NoScaleOffset] _MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
        [NoScaleOffset] _AlphaTex("CutOut Tex",2D) = "white" {}
        _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5

    	_Pos("Wave base position",Vector) =(0,0,0,0)
		_Direction("Wave direction",Vector) =(0,0,0,0)
		_TimeScale("Wave TimeScale",Vector) = (0,0,0,0)
		_TimeDelay("Wave TimeDelay",Vector) = (0,0,0,0)

    }

    SubShader 
    {
        Tags
        { 
            "RenderPipeline"="UniversalPipeline"
            "Queue"="AlphaTest"
            "IgnoreProjector"="True"
            "RenderType"="TransparentCutout"
        }
        
        LOD 150
        
        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "UniversalForward" }
            ColorMask RGB
			Cull off
            ZWrite On
            ZTest Less
            Blend SrcAlpha OneMinusSrcAlpha
            
            HLSLPROGRAM
            // compile directives
            #pragma vertex vert_surf
            #pragma fragment frag_surf
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase
            //#define UNITY_PASS_FORWARDBASE
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariablesFunctions.hlsl"
			
            sampler2D _MainTex;
            sampler2D _AlphaTex;
    		half4 _Pos;
    		half4 _Direction;
    		half4 _TimeScale;
    		half4 _TimeDelay;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
                half4 color : COLOR;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };
            
            struct v2f_surf {
                float4 pos : SV_POSITION;
                float2 mainTex : TEXCOORD0;
                float fogCoord : TEXCOORD1;
                float3 normal: TEXCOORD2;
                float4 lmap : TEXCOORD3;
            };

            // vertex shader
            v2f_surf vert_surf (appdata v)
            {
                v2f_surf o = (v2f_surf)0;
                // 摆动
                //half dis = distance(v.vertex ,_Pos) ;
                //half dis = distance(v.texcoord.xy, _Pos.xy);
				

                half dis = abs(v.texcoord.y - _Pos.y);

                half time = (_Time.y + _TimeDelay) * _TimeScale;
                v.vertex.xyz += dis * (sin(time) * cos(time * 2 / 3) + 1) * _Direction.xyz * v.color.r;

                o.pos = TransformObjectToHClip(v.vertex);
                o.mainTex.xy = v.texcoord;
//                #ifndef LIGHTMAP_OFF
//                o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
//                #endif
                o.fogCoord = ComputeFogFactor(o.pos.z);

                VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(v.normal);
                o.normal = vertexNormalInput.normalWS;
                return o;
            }
            
            half4 _Color;
            half  _Cutoff;
            // fragment shader
            half4 frag_surf (v2f_surf IN) : SV_Target 
            {
                half3 lightDir = _MainLightPosition.xyz;
                half4 alpha = tex2D(_AlphaTex, IN.mainTex.xy);
                half4 source = tex2D(_MainTex, IN.mainTex.xy);
                half4 outClr = source;
//                #ifndef LIGHTMAP_OFF
////                half4 lightmap = UNITY_SAMPLE_TEX2D (unity_Lightmap, IN.lmap.xy);
////                half4 lightmap = SAMPLE_TEXTURE2D(unity_Lightmap, samplerunity_Lightmap, IN.lmap.xy)
//                half4 lightmap = tex2D(samplerunity_Lightmap, IN.lmap.xy)
//                half4 delmap = half4(DecodeLightmap(lightmap),1);
//                outClr = delmap * outClr;
//                #endif
                clip(alpha.r - _Cutoff);
                half4 lc = max(0, dot(normalize(IN.normal), _MainLightPosition.xyz)) * _MainLightColor;
                outClr = outClr * (lc * 0.5 + 0.5);
                outClr.a = alpha.r;
//                UNITY_APPLY_FOG(IN.fogCoord, outClr); // apply fog
                outClr.xyz = MixFog(outClr, IN.fogCoord);
                return outClr;
            }
            ENDHLSL
        }
        
        Pass
        {
            Name "ShadowCaster"
            Tags {"LightMode"="ShadowCaster"}
            Fog {Mode off}
            ZWrite On
            ZTest Less
            Cull off
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
//			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
//			#include "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariablesFunctions.hlsl"
            #include "../NiloURPSurfaceShaderInclude.hlsl"
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_AlphaTex);
            SAMPLER(sampler_AlphaTex);
//            sampler2D _MainTex;
//            sampler2D _AlphaTex;
            CBUFFER_START(UnityPerMaterial)
            half  _Cutoff;
    		half4 _Pos;
    		half4 _Direction;
    		half4 _TimeScale;
    		half4 _TimeDelay;
    		float4 _MainTex_ST;
            CBUFFER_END
            
            struct appdata {
                float4 vertex : POSITION;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
                float4 texcoord1 : TEXCOORD1;
                float4 texcoord2 : TEXCOORD2;
                float4 texcoord3 : TEXCOORD3;
                half4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            struct v2f { 
                float2 mainTex : TEXCOORD0;
                float3 vec : TEXCOORD1;
                float4 pos : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
//                V2F_SHADOW_CASTER;
            };

            v2f vert(appdata v)
            {
                // 摆动
                half dis = distance(v.vertex ,_Pos) ;
                half time = (_Time.y + _TimeDelay) * _TimeScale;
                v.vertex.xyz += dis * (sin(time) * cos(time * 2 / 3) + 1) * _Direction.xyz * v.color.r;
                
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                
                o.vec.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                
                float3 positionWS = v.vertex.xyz;
                float3 normalWS = v.normal;
            
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
            
            #if UNITY_REVERSED_Z
                positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
            #else
                positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
            #endif
            
                o.pos = positionCS;
    
                o.mainTex.xy = v.texcoord;
                return o;
                
                 


            }

            float4 frag(v2f IN) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID( IN );
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );
                half4 alpha = SAMPLE_TEXTURE2D(_AlphaTex,sampler_AlphaTex, IN.mainTex);
				clip( alpha.r - _Cutoff );

                return 0;
                
//				return UnityEncodeCubeShadowDepth ((length(i.vec) + unity_LightShadowBias.x) * _LightPositionRange.w);

//                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDHLSL
        }
    }
}
