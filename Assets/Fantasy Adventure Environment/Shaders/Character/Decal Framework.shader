Shader "Babeitime/Character/Decal"
{
Properties {
	_MainColor ("Main Color", Color) = (.2,.2,.2,0)
	_MainTex ("Main Texture", 2D) = "white" {}
        //UI遮罩
    _StencilComp ("Stencil Comparison", Float) = 8
    _Stencil ("Stencil ID", Float) = 0
    _StencilOp ("Stencil Operation", Float) = 0
    _StencilWriteMask ("Stencil Write Mask", Float) = 255
    _StencilReadMask ("Stencil Read Mask", Float) = 255
	[HDR] _ColorToMulti ("Color to multiply", Color) = (1,1,1,1)
}

SubShader {
	Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" }
	
    //UI遮罩
    Stencil
    {
        Ref [_Stencil]
        Comp [_StencilComp]
        Pass [_StencilOp] 
        ReadMask [_StencilReadMask]
        WriteMask [_StencilWriteMask]
    }
	
	Cull Off
	ZWrite Off
	Blend SrcAlpha OneMinusSrcAlpha
	Pass 
	{
        HLSLPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        
        struct appdata
        {
            float4 vertex : POSITION;
            float2 texCoord : TEXCOORD0;
        };
        
        struct v2f
        {
            float4 pos : SV_POSITION;
            half2 uv : TEXCOORD0;
        };
        
        CBUFFER_START(UnityPerMaterial)
            half4 _MainColor;
            half4 _ColorToMulti;
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;
        CBUFFER_END
        
        v2f vert(appdata v)
        {
            v2f o;
            float4 pos = mul(UNITY_MATRIX_MVP, v.vertex);
            o.uv = TRANSFORM_TEX(v.texCoord.xy, _MainTex);
            o.pos = pos;
            return o;
        }
        
        half4 frag(v2f i) : SV_Target
        {
            half4 mainTex = SAMPLE_TEXTURE2D( _MainTex, sampler_MainTex, i.uv );
            half4 col = half4((_MainLightColor * mainTex).xyz, _ColorToMulti.a * mainTex.a);
            return col;
        
        }
        ENDHLSL
  }
}
}