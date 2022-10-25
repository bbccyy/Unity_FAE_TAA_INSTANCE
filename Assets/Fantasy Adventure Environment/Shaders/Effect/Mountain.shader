Shader "sg3/Fx/Mountain" {
    Properties {
        [HDR]_Color ("Color", Color) = (1,1,1,1)
        _Noise ("Noise", 2D) = "white" {}
        _Speed ("Speed", Range(-5, 5)) = 0
        _Height ("Height", Range(0, 10)) = 1
        _FoamTex ("FoamTex", 2D) = "black" {}
        _FoamColor ("FoamColor", Color) = (0.5,0.5,0.5,1)
    }
    SubShader {
        Tags {
            "RenderPipeline"="UniversalPipeline" 
            "RenderType"="Opaque"
            "CanUseSpriteAtlas"="True"
        }
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="UniversalForward"
            }
            
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            //#define UNITY_PASS_FORWARDBASE
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma multi_compile_fog
            #pragma only_renderers d3d9 d3d11 glcore gles gles3 
            #pragma target 3.0
            uniform float4 _Color;
            uniform sampler2D _Noise; uniform float4 _Noise_ST;
            uniform float _Speed;
            uniform float _Height;
            uniform sampler2D _FoamTex; uniform float4 _FoamTex_ST;
            uniform float4 _FoamColor;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord0 : TEXCOORD0;
                float4 vertexColor : COLOR;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float3 normalDir : TEXCOORD1;
                float4 vertexColor : COLOR;
                UNITY_FOG_COORDS(2)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.vertexColor = v.vertexColor;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                float4 node_6893 = _Time;
                float node_3674_ang = node_6893.g;
                float node_3674_spd = _Speed;
                float node_3674_cos = cos(node_3674_spd*node_3674_ang);
                float node_3674_sin = sin(node_3674_spd*node_3674_ang);
                float2 node_3674_piv = float2(0.5,0.5);
                float2 node_3674 = (mul(o.uv0-node_3674_piv,float2x2( node_3674_cos, -node_3674_sin, node_3674_sin, node_3674_cos))+node_3674_piv);
                float4 _Noise_var = tex2Dlod(_Noise,float4(TRANSFORM_TEX(node_3674, _Noise),0.0,0));
                v.vertex.xyz += ((dot(_Noise_var.rgb,float3(0.3,0.59,0.11))*_Noise_var.a*saturate((1.0 - length((o.uv0*2.0+-1.0))))*_Height*o.vertexColor.a)*v.normal);
                o.pos = UnityObjectToClipPos( v.vertex );
                UNITY_TRANSFER_FOG(o,o.pos);
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
                i.normalDir = normalize(i.normalDir);
                float3 normalDirection = i.normalDir;
////// Lighting:
////// Emissive:
                float4 node_6893 = _Time;
                float2 node_7046 = (i.uv0+node_6893.g*float2(0.1,0.3));
                float4 _FoamTex_var = tex2D(_FoamTex,TRANSFORM_TEX(node_7046, _FoamTex));
                float3 emissive = (_FoamTex_var.rgb*_FoamTex_var.a*_FoamColor.rgb);
                float node_3674_ang = node_6893.g;
                float node_3674_spd = _Speed;
                float node_3674_cos = cos(node_3674_spd*node_3674_ang);
                float node_3674_sin = sin(node_3674_spd*node_3674_ang);
                float2 node_3674_piv = float2(0.5,0.5);
                float2 node_3674 = (mul(i.uv0-node_3674_piv,float2x2( node_3674_cos, -node_3674_sin, node_3674_sin, node_3674_cos))+node_3674_piv);
                float4 _Noise_var = tex2D(_Noise,TRANSFORM_TEX(node_3674, _Noise));
                float3 finalColor = emissive + (_Color.rgb*i.vertexColor.rgb*_Noise_var.rgb);
                fixed4 finalRGBA = fixed4(finalColor,1);
                UNITY_APPLY_FOG(i.fogCoord, finalRGBA);
                return finalRGBA;
            }
            ENDHLSL
        }
        Pass {
            Name "ShadowCaster"
            Tags {
                "LightMode"="ShadowCaster"
            }
            Offset 1, 1
            Cull Back
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_SHADOWCASTER
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_fog
            #pragma only_renderers d3d9 d3d11 glcore gles gles3 
            #pragma target 3.0
            uniform sampler2D _Noise; uniform float4 _Noise_ST;
            uniform float _Speed;
            uniform float _Height;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord0 : TEXCOORD0;
                float4 vertexColor : COLOR;
            };
            struct VertexOutput {
                V2F_SHADOW_CASTER;
                float2 uv0 : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                float4 vertexColor : COLOR;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.vertexColor = v.vertexColor;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                float4 node_6343 = _Time;
                float node_3674_ang = node_6343.g;
                float node_3674_spd = _Speed;
                float node_3674_cos = cos(node_3674_spd*node_3674_ang);
                float node_3674_sin = sin(node_3674_spd*node_3674_ang);
                float2 node_3674_piv = float2(0.5,0.5);
                float2 node_3674 = (mul(o.uv0-node_3674_piv,float2x2( node_3674_cos, -node_3674_sin, node_3674_sin, node_3674_cos))+node_3674_piv);
                float4 _Noise_var = tex2Dlod(_Noise,float4(TRANSFORM_TEX(node_3674, _Noise),0.0,0));
                v.vertex.xyz += ((dot(_Noise_var.rgb,float3(0.3,0.59,0.11))*_Noise_var.a*saturate((1.0 - length((o.uv0*2.0+-1.0))))*_Height*o.vertexColor.a)*v.normal);
                o.pos = UnityObjectToClipPos( v.vertex );
                TRANSFER_SHADOW_CASTER(o)
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
                i.normalDir = normalize(i.normalDir);
                float3 normalDirection = i.normalDir;
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDHLSL
        }
    }
    FallBack "Babeltime/Diffuse"
    //CustomEditor "ShaderForgeMaterialInspector"
}
