Shader "sg3/Fx/SpaceWarp" {
    Properties {
        _NormalMap ("NormalMap", 2D) = "bump" {}
        _MaskMap ("MaskMap", 2D) = "white" {}
        _RefractionScale ("RefractionScale", Range(0, 2)) = 1
        [MaterialToggle] _ParticleControl ("ParticleControl", Float ) = 1
    }
    SubShader {
        Tags {"IgnoreProjector"="True" "Queue"="Transparent" "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline"}
        GrabPass{ }
        Pass {
            Name "FORWARD"
            Tags {"LightMode"="UniversalForward"}
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            ZWrite Off
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
          	#pragma exclude_renderers xboxone ps4 psp2 n3ds wiiu

            sampler2D _GrabTexture, _NormalMap, _MaskMap;

            float4 _NormalMap_ST, _MaskMap_ST;
            float _RefractionScale;
            fixed _ParticleControl;

            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
                float4 vertexColor : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float4 uv0 : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
                float4 vertexColor : COLOR;
            };
            VertexOutput vert (VertexInput v ) {
                VertexOutput o = (VertexOutput)0;
                o.uv0.xy = TRANSFORM_TEX(v.texcoord0, _NormalMap);
                o.uv0.zw = TRANSFORM_TEX(v.texcoord0, _MaskMap);
                o.vertexColor = v.vertexColor;
                o.pos = UnityObjectToClipPos(v.vertex );
                o.screenPos = o.pos;

                return o;
            }
            float4 frag(VertexOutput i) : COLOR {

                #if UNITY_UV_STARTS_AT_TOP
                    float grabSign = -_ProjectionParams.x;
                #else
                    float grabSign = _ProjectionParams.x;
                #endif
                i.screenPos = float4(i.screenPos.xy / i.screenPos.w, 0, 0 );
                i.screenPos.y *= _ProjectionParams.x;
                float3 _NormalMap_var = UnpackNormal(tex2D(_NormalMap, i.uv0.xy));
                float4 _MaskMap_var = tex2D(_MaskMap, i.uv0.zw);
                float2 sceneUVs = float2(1,grabSign) * i.screenPos.xy*0.5+0.5 + (lerp(float3(0,0,1),_NormalMap_var.rgb,_MaskMap_var.rgb).rg*lerp( _RefractionScale, (_RefractionScale*i.vertexColor.a), _ParticleControl));
                float4 sceneColor = tex2D(_GrabTexture, sceneUVs);
                return fixed4(sceneColor.rgb, 1);
            }
            ENDHLSL
        }
    }
}
