#if !defined(SG3_PARTICLE_INCLUDED)
#define SG3_PARTICLE_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

	TEXTURE2D(_MainTex);		SAMPLER(sampler_MainTex);
	TEXTURE2D(_NoiseTex);	    SAMPLER(sampler_NoiseTex);
	TEXTURE2D(_Mask);			SAMPLER(sampler_Mask);
	TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
	CBUFFER_START(UnityPerMaterial)
	float4 _MainTex_ST, _Mask_ST, _NoiseTex_ST;
	float4 _TintColor;
	float _InvFade, _ScrollX, _ScrollY, _Scroll2X, _Scroll2Y;
	float _ColorPower, _TurbulenceAmt, _AlphaBoost;
	float _Intensity;
	float _Transparency = 0;	//add by mengzhijiang
	half _Tran, _RorA;
	float4 _ClipRect;
	CBUFFER_END

	struct Attributes
	{
		float4 positionOS : POSITION;
		float4 color : COLOR;
		float2 uv : TEXCOORD0;
		UNITY_VERTEX_INPUT_INSTANCE_ID
	};

	struct Varyings
	{
		float4 posCS : SV_POSITION;
		float4 color : COLOR;
		float4 uv : TEXCOORD0;
		#ifdef SOFTPARTICLES_ON
			float4 projPos : TEXCOORD1;
		#endif
		#ifdef SHATTER_TURBULENCE
			float2 turbUV  : TEXCOORD2;
		#endif
		float4 worldPosition : TEXCOORD3;
		float FogFactor  : TEXCOORD4;
		UNITY_VERTEX_INPUT_INSTANCE_ID
		UNITY_VERTEX_OUTPUT_STEREO
	};



	Varyings vert (Attributes v)
	{

		Varyings o = (Varyings)0;
		UNITY_SETUP_INSTANCE_ID(v);
		UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
		o.posCS = TransformObjectToHClip(v.positionOS.xyz);
		#ifdef SOFTPARTICLES_ON
			o.projPos = ComputeScreenPos(o.posCS);
			float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
			o.projPos.z = -TransformWorldToView(positionWS).z;
		#endif
		o.color = v.color;
		o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
		#if defined(ENABLE_SCROLL)
			o.uv.xy = TRANSFORM_TEX((v.uv + float2(_ScrollX, _ScrollY) * _Time.x), _MainTex);
			o.uv.zw = TRANSFORM_TEX((v.uv + float2(_Scroll2X, _Scroll2Y) * _Time.x), _Mask);
		#elif defined(SHATTER_TURBULENCE)
			o.turbUV = v.uv;
			o.uv.zw = TRANSFORM_TEX((v.uv + float2(_ScrollX, _ScrollY) * _Time.y), _Mask);
		#endif
		o.worldPosition = v.positionOS;
		o.FogFactor = ComputeFogFactor(o.posCS.z);
		return o;
	}

	half4 frag (Varyings i) : SV_Target
	{
		UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
		#ifdef SOFTPARTICLES_ON
			float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.projPos.xy / i.projPos.w), _ZBufferParams);
			float partZ = i.projPos.z;
			float fade = saturate(_InvFade * (sceneZ - partZ));
			i.color.a *= fade;
		#endif
			half4 col = _ColorPower * i.color * _TintColor;
			col *= SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
		#if defined(ENABLE_SCROLL)
			half4 colMask = SAMPLE_TEXTURE2D(_Mask, sampler_Mask, i.uv.zw);
			col *= colMask;
		#elif defined(SHATTER_TURBULENCE)
			float2 noiseUV = (float3(i.turbUV, 0.0) + (SAMPLE_TEXTURE2D(_Mask, sampler_Mask, i.uv.zw).rgb * _TurbulenceAmt)).rg;
			half4 noiseCol = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, TRANSFORM_TEX(noiseUV, _NoiseTex));
			col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, i.uv.xy);
			col.a = step(0, ((noiseCol.r + i.color.a) - 0.5));
			col *= col.a;
			col.rgb *= i.color.rgb;
			#ifdef SHATTER_TURBULENCE_BLEND
				col = half4(col.rgb, col.r);
			#endif
		#endif
		#if defined(UNITY_UI_CLIP_RECT) && !defined(UI_CLIP_RECT)
			float2 inside = step(_ClipRect.xy, i.worldPosition.xy) * step(i.worldPosition.xy, _ClipRect.zw);
            col.a *= inside.x * inside.y;
		#endif
		#ifdef PARTICLE_ADDITIVE_SOFT
			col.rgb *= col.a;
		#endif

		//add by mengzhijiang
#ifdef PARTICLE_TRANSPARENT_ADD
		col *= (1 - _Transparency);
#elif defined(PARTICLE_TRANSPARENT_BLEND)
		col.a *= (1 - _Transparency);
#endif
		// apply fog
		col.rgb = MixFog(col.rgb, i.FogFactor);

		//col.rgb = EncodeColor(col.rgb * _Intensity);
		#ifdef UI_NOT_HDR
			col = clamp(col, 0.0, 1.0);
		#endif
		return col;
	}


#endif