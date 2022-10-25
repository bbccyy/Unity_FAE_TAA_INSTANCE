Shader "Babeitime/Scene/Alpha Cutout Blended"
{
    Properties 
    {
        [NoScaleOffset] _MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
        [NoScaleOffset] _AlphaTex("CutOut Tex",2D) = "white" {}
        //_Hue ("Hue", Range(0,359)) = 0
        //_Saturation ("Saturation", Range(0,3.0)) = 1.0
        //_Value ("Value", Range(0,3.0)) = 1.0
        _Blend ("Blend", Range(0,1.0)) = 1.0

    	_Pos("Wave base position",Vector) =(0,0,0,0)
		_Direction("Wave direction",Vector) =(0,0,0,0)
		_TimeScale("Wave TimeScale",Vector) = (0,0,0,0)
		_TimeDelay("Wave TimeDelay",Vector) = (0,0,0,0)
    }

    SubShader 
    {
        Tags { "RenderPipeline"="UniversalPipeline"
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
        }

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
            //#pragma shader_feature __ APPLYHSV
            #pragma shader_feature LIGHTMAP_OFF
            //#define UNITY_PASS_FORWARDBASE
            //#include "HSV.cginc"
            #include "Base.cginc"
            //#define APPLYHSV
            sampler2D _MainTex;
            sampler2D _AlphaTex;
    		fixed4 _Pos;
    		fixed4 _Direction;
    		fixed4 _TimeScale;
    		fixed4 _TimeDelay;

            // no lightmaps:
            #ifdef LIGHTMAP_OFF
            struct v2f_surf {
                float4 pos : SV_POSITION;
                float2 mainTex : TEXCOORD0;
                //UNITY_FOG_COORDS(1)
                #if SHADER_TARGET >= 30
                float4 lmap : TEXCOORD2;
                #endif
            };
            #endif
            // with lightmaps:
            #ifndef LIGHTMAP_OFF
            struct v2f_surf {
                float4 pos : SV_POSITION;
                float2 mainTex : TEXCOORD0; // _MainTex
                //UNITY_FOG_COORDS(1)
                float4 lmap : TEXCOORD2;
            };
            #endif
            

            // vertex shader
            v2f_surf vert_surf (appdata_full v)
            {
                v2f_surf o = (v2f_surf)0;
                // 摆动
                //half dis = distance(v.vertex ,_Pos) ;
				half dis = abs(v.texcoord.y - _Pos.y);
                half time = (_Time.y + _TimeDelay) * _TimeScale;
                v.vertex.xyz += dis * (sin(time) * cos(time * 2 / 3) + 1) * _Direction.xyz * v.color.r;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.mainTex.xy = v.texcoord;
                #ifndef LIGHTMAP_OFF
                o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                #endif
                //UNITY_TRANSFER_FOG(o,o.pos); // pass fog coordinates to pixel shader
                return o;
            }

            fixed _Cutoff;
            half _Hue;
            half _Saturation;
            half _Value;
            half _Blend;
            // fragment shader
            fixed4 frag_surf (v2f_surf IN) : SV_Target 
            {
                fixed3 lightDir = _WorldSpaceLightPos0.xyz;
                fixed4 alpha = tex2D(_AlphaTex, IN.mainTex.xy);
                fixed4 source = tex2D(_MainTex, IN.mainTex.xy);
                fixed4 outClr = source;
                #ifndef LIGHTMAP_OFF
                fixed4 lightmap = UNITY_SAMPLE_TEX2D (unity_Lightmap, IN.lmap.xy);
                fixed4 delmap = fixed4(DecodeLightmap(lightmap),1);
                outClr = delmap * outClr;
                #endif
                //#ifdef APPLYHSV
                //outClr.rgb = apply_hsv(outClr.rgb,_Hue,_Saturation,_Value);
                //#endif
                //UNITY_APPLY_FOG(IN.fogCoord, outClr); // apply fog
                outClr.a = alpha.r * _Blend;
                clip(alpha.r - 0.3);
                return outClr;
            }
            ENDHLSL
        }
//游戏内暂时仅仅见于背景板，先不用考虑深度。如果用于物品渲染再说
//        Pass
//        {
//            Tags {"LightMode"="ShadowCaster"}
//            Fog {Mode off}
//            ZWrite On
//            ZTest Less
//            Cull off
//            
//            CGPROGRAM
//            #pragma vertex vert
//            #pragma fragment frag
//            #pragma multi_compile_shadowcaster
//            #include "UnityCG.cginc"
//            
//            sampler2D _AlphaTex;
//    		fixed4 _Pos;
//    		fixed4 _Direction;
//    		fixed4 _TimeScale;
//    		fixed4 _TimeDelay;
//
//            struct v2f { 
//                float2 mainTex : TEXCOORD0;
//                V2F_SHADOW_CASTER;
//            };
//
//            v2f vert(appdata_full v)
//            {
//                v2f o;
//                // 摆动
//                half dis = distance(v.vertex ,_Pos) ;
//                half time = (_Time.y + _TimeDelay) * _TimeScale;
//                v.vertex.xyz += dis * (sin(time) * cos(time * 2 / 3) + 1) * _Direction.xyz * v.color.r;
//
//                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
//                o.mainTex.xy = v.texcoord;
//                return o;
//            }
//
//            float4 frag(v2f i) : SV_Target
//            {
//                fixed4 alpha = tex2D(_AlphaTex, i.mainTex);
//				clip( alpha.r - 0.5 );
//                SHADOW_CASTER_FRAGMENT(i)
//            }
//            ENDCG
//        }
    }
}
