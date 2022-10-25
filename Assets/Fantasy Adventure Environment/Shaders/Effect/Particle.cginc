#if !defined(SG3_PARTICLE_INCLUDED)
#define SG3_PARTICLE_INCLUDED

#include "UnityCG.cginc"
//#include "Common.cginc"

	sampler2D _MainTex, _NoiseTex;
	sampler2D _Mask;
	float4 _MainTex_ST, _Mask_ST, _NoiseTex_ST; 
	float4 _TintColor;

	float _InvFade, _ScrollX, _ScrollY, _Scroll2X, _Scroll2Y;
	float _ColorPower, _TurbulenceAmt, _AlphaBoost;
	float _Intensity;
	float _Transparency = 0;	//add by mengzhijiang

	fixed _Tran, _RorA;

	sampler2D_float _CameraDepthTexture;

	struct appdata
	{
		float4 vertex : POSITION;
		float4 color : COLOR;
		float2 uv : TEXCOORD0;
		UNITY_VERTEX_INPUT_INSTANCE_ID
	};

	struct v2f
	{
		float4 pos : SV_POSITION;
		float4 color : COLOR;
		float4 uv : TEXCOORD0;
		UNITY_FOG_COORDS(1)
		#ifdef SOFTPARTICLES_ON
			float4 projPos : TEXCOORD2;
		#endif
		#ifdef SHATTER_TURBULENCE
			float2 turbUV  : TEXCOORD3;
		#endif
		UNITY_VERTEX_INPUT_INSTANCE_ID
	};

		
			
	v2f vert (appdata v)
	{
		UNITY_SETUP_INSTANCE_ID(v);
		v2f o;
		UNITY_INITIALIZE_OUTPUT(v2f, o);
		UNITY_TRANSFER_INSTANCE_ID(v, o);
		UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
		o.pos = UnityObjectToClipPos(v.vertex);
		#ifdef SOFTPARTICLES_ON
			o.projPos = ComputeScreenPos(o.pos);
			COMPUTE_EYEDEPTH(o.projPos.z);
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
		UNITY_TRANSFER_FOG(o, o.pos);
		return o;
	}
	
	fixed4 frag (v2f i) : SV_Target
	{
		UNITY_SETUP_INSTANCE_ID(i);
		#ifdef SOFTPARTICLES_ON
			float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
			float partZ = i.projPos.z;
			float fade = saturate(_InvFade * (sceneZ - partZ));
			i.color.a *= fade;
		#endif
			fixed4 col = _ColorPower * i.color * _TintColor;
			col *= tex2D(_MainTex, i.uv.xy);
		#if defined(ENABLE_SCROLL)
			fixed4 colMask = tex2D(_Mask, i.uv.zw);
			col *= colMask;
		#elif defined(SHATTER_TURBULENCE)
			float2 noiseUV = (float3(i.turbUV, 0.0) + (tex2D(_Mask, i.uv.zw).rgb * _TurbulenceAmt)).rg;
			fixed4 noiseCol = tex2D(_NoiseTex, TRANSFORM_TEX(noiseUV, _NoiseTex));
			col = tex2D(_MainTex, i.uv.xy);
			col.a = step(0, ((noiseCol.r + i.color.a) - 0.5));
			col *= col.a;
			col.rgb *= i.color.rgb;
			#ifdef SHATTER_TURBULENCE_BLEND
				col = fixed4(col.rgb, col.r);
			#endif
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
		UNITY_APPLY_FOG_COLOR(i.fogCoord, col, fixed4(0,0,0,0));
		
		//col.rgb = EncodeColor(col.rgb * _Intensity);

		return col;
	}
	

#endif