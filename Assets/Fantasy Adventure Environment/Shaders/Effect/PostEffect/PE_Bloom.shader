//
// Kino/Bloom v2 - Bloom filter for Unity
//
// Copyright (C) 2015, 2016 Keijiro Takahashi
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
Shader "Hidden/PostEffect/Bloom"
{
    Properties
    {
        _MainTex ("", 2D) = "" {}
        _BaseTex ("", 2D) = "" {}
    }

    HLSLINCLUDE

		#pragma shader_feature __ HDR_RGB111110
		#pragma shader_feature __ POST_EFFECT_HIGH_QUALITY

        #include "UnityCG.cginc"
		#include "PE_Common.cginc"

		sampler2D _MainTex;
		float2 _MainTex_TexelSize;
        sampler2D _BaseTex;
        float2 _BaseTex_TexelSize;

        float _Threshold;
        float3 _Curve;
        float _SampleScale;
		float _BloomToneMapping;


        // -----------------------------------------------------------------------------
        // Vertex shaders

        struct VaryingsMultitex
        {
            float4 pos : SV_POSITION;
            float2 uvMain : TEXCOORD0;
            float2 uvBase : TEXCOORD1;
        };

		struct AttributesDefault
		{
			float4 vertex : POSITION;
			float4 texcoord : TEXCOORD0;
		};

		struct VaryingsDefault
		{
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
		};

		VaryingsDefault VertDefault(AttributesDefault v)
		{
			VaryingsDefault o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv = v.texcoord.xy;
			return o;
		}

        // -----------------------------------------------------------------------------
        // Fragment shaders

        half4 FetchAutoExposed(sampler2D tex, float2 uv)
        {
			half4 color = tex2D(tex, uv);
            return color;
        }

        half4 FragPrefilter(VaryingsDefault i) : SV_Target
        {
            half4 s0 = FetchAutoExposed(_MainTex, i.uv);
			half3 m = s0.rgb;

        #if UNITY_COLORSPACE_GAMMA
			m = GammaToLinearSpace(m);
        #endif

            // Pixel brightness
            half br = Brightness(m);

            // Under-threshold part: quadratic curve
            half rq = clamp(br - _Curve.x, 0.0, _Curve.y);
            rq = _Curve.z * rq * rq;

            // Combine and apply the brightness response curve.
            m *= max(rq, br - _Threshold) / max(br, 1e-5);

            return EncodeHDR(m);
        }

        half4 FragDownsample1(VaryingsDefault i) : SV_Target
        {
            return EncodeHDR(DownsampleFilter(_MainTex, i.uv, _MainTex_TexelSize.xy));
        }

        half4 FragDownsample2(VaryingsDefault i) : SV_Target
        {
            return EncodeHDR(DownsampleFilter(_MainTex, i.uv, _MainTex_TexelSize.xy));
        }

        half4 FragUpsample(VaryingsDefault i) : SV_Target
        {
            half3 base = DecodeHDR(tex2D(_BaseTex, i.uv));
            half3 blur = UpsampleFilter(_MainTex, i.uv, _MainTex_TexelSize.xy, _SampleScale);
			half3 color = (base+blur);
            return EncodeHDR(color);
        }

    ENDHLSL

    SubShader
    {
        ZTest Always Cull Off ZWrite Off
		// 0
        Pass 
        {
            HLSLPROGRAM
                #pragma vertex VertDefault
                #pragma fragment FragPrefilter
            ENDHLSL
        }

		// 1
        Pass
        {
            HLSLPROGRAM
                #pragma vertex VertDefault
                #pragma fragment FragDownsample1
            ENDHLSL
        }

		// 2
        Pass
        {
            HLSLPROGRAM
                #pragma vertex VertDefault
                #pragma fragment FragDownsample2
            ENDHLSL
        }

		// 3
        Pass
        {
            HLSLPROGRAM
                #pragma vertex VertDefault
                #pragma fragment FragUpsample
            ENDHLSL
        }
    }
}
