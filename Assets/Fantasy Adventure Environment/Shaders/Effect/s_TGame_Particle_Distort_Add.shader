// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


/*
    TGame 扭曲Additive

    
*/
Shader "TGame/Particles/Distort_Additive" 
{
    Properties 
    {
        _TintColor ("Tint Color", Color) = (1,1,1,1)

  		_MainTex ("Particle Texture", 2D) = "white" {}
        
        _DistortTexture ("Distort Texture", 2D) = "white" {}

        _DistortMultiplier ("Distort Multiplier", Float ) = 0.2
        _Glow ("Glow", Float ) = 1

        _VSpeed ("VSpeed", Float ) = 0.2
        _USpeed ("USpeed", Float ) = 0

        [HideInInspector]_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5

    }
    SubShader 
    {
        
        Tags {"RenderPipeline"="UniversalPipeline"  "IgnoreProjector"="True" "Queue"="Transparent" "RenderType"="Transparent" }

        LOD 100
        Pass 
        {
            Name "FORWARD"
            Tags { "LightMode"="UniversalForward" }

            Blend One One
            Cull Off
            ZWrite Off
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fwdbase
            #pragma target 2.0
            
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            sampler2D _MainTex; 
            float4 _MainTex_ST;
            float4 _TintColor;

            sampler2D _DistortTexture; 
            float4 _DistortTexture_ST;

            float _DistortMultiplier;
            float _Glow;
            float _VSpeed;
            float _USpeed;

            struct appdata 
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float4 vertexColor : COLOR;

            };

            struct v2f 
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float4 vertexColor : COLOR;

            };

            v2f vert (appdata v) 
            {
                v2f o = (v2f)0;
                o.uv.xy = v.texcoord;
                o.vertexColor = v.vertexColor;
                o.pos = TransformObjectToHClip(v.vertex );
                return o;

            }

            float4 frag(v2f i) : COLOR 
            {

                float4 time = _Time;

                // 
                float2 uvAnim = (float2((_USpeed*time.g),(_VSpeed*time.g))+i.uv.xy);
                float2 distortUV = uvAnim * _DistortTexture_ST.xy + _DistortTexture_ST.zw;
                float4 distort = tex2D(_DistortTexture,distortUV);

                // 
                float2 uvAnimParticle = ((distort.r*_DistortMultiplier)+i.uv);     
                float2 partUV = uvAnimParticle * _MainTex_ST.xy + _MainTex_ST.zw;
                float4 particle = tex2D(_MainTex,partUV);

                // 
                float3 emissive = (((2.0*distort.rgb)*particle.rgb)*(particle.rgb*i.vertexColor.rgb*(_TintColor.rgb*_Glow)));
                float3 finalColor = emissive;
                
                // Alpha
                //float alpha = particle.a*i.vertexColor.a*_TintColor.a;

                return float4(finalColor*i.vertexColor.a,0);
            }
            ENDHLSL
        }    
    }
    FallBack "Babeltime/Diffuse"

}
