#if !defined(SG3_ENVIRONMENTSCROLL_INCLUDED)
#define SG3_ENVIRONMENTSCROLL_INCLUDED

	#include "UnityCG.cginc"
	//#include "Common.cginc"

	sampler2D _MainTex;
	sampler2D _DetailTex;

	float4 _MainTex_ST;
	float4 _DetailTex_ST;
	
	float _ScrollX;
	float _ScrollY;
	float _Scroll2X;
	float _Scroll2Y;
	float _MMultiplier;
	
	float _SineAmplX;
	float _SineAmplY;
	float _SineFreqX;
	float _SineFreqY;

	float _SineAmplX2;
	float _SineAmplY2;
	float _SineFreqX2;
	float _SineFreqY2;
	float4 _Color;

	float _FadeOutDistNear;
	float _FadeOutDistFar;
	float _Bias;
	float _TimeOnDuration;
	float _TimeOffDuration;
	float _BlinkingTimeOffsScale;
	float _SizeGrowStartDist;
	float _SizeGrowEndDist;
	float _MaxGrowSize;
	float _NoiseAmount;
	float _ContractionAmount;

	struct v2f {
		float4 pos : SV_POSITION;
		float4 uv : TEXCOORD0;
		fixed4 color : TEXCOORD1;
		#if defined(LIGHTMAP_ON)
			float2 lmap : TEXCOORD2;
		#endif
		UNITY_VERTEX_OUTPUT_STEREO
	};

	v2f vert (appdata_full v)
	{
		v2f o;
		UNITY_INITIALIZE_OUTPUT(v2f, o);
		UNITY_SETUP_INSTANCE_ID(v);
		UNITY_TRANSFER_INSTANCE_ID(v, o);
		UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

		o.uv.xy = TRANSFORM_TEX(v.texcoord.xy,_MainTex) + frac(float2(_ScrollX, _ScrollY) * _Time);
		
		o.uv.x += sin(_Time * _SineFreqX) * _SineAmplX;
		o.uv.y += sin(_Time * _SineFreqY) * _SineAmplY;
		#if defined(DETAILTEX)
			o.uv.zw = TRANSFORM_TEX(v.texcoord.xy,_DetailTex) + frac(float2(_Scroll2X, _Scroll2Y) * _Time);
			o.uv.z += sin(_Time * _SineFreqX2) * _SineAmplX2;
			o.uv.w += sin(_Time * _SineFreqY2) * _SineAmplY2;
		#endif
		
		#if defined(LIGHTMAP_ON)
			o.lmap = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
		#endif
				

		float		time 		= _Time.y + _BlinkingTimeOffsScale * v.color.b;
		float3		viewPos		= UnityObjectToViewPos(v.vertex);
		float		dist			= length(viewPos);
		float		nfadeout	= saturate(dist / _FadeOutDistNear);
		float		ffadeout	= 1 - saturate(max(dist - _FadeOutDistFar,0) * 0.2);
		float		fracTime	= fmod(time,_TimeOnDuration + _TimeOffDuration);
		float		wave		= smoothstep(0,_TimeOnDuration * 0.25,fracTime)  * (1 - smoothstep(_TimeOnDuration * 0.75,_TimeOnDuration,fracTime));
		float		noiseTime	= time *  (6.2831853f / _TimeOnDuration);
		float		noise		= sin(noiseTime) * (0.5f * cos(noiseTime * 0.6366f + 56.7272f) + 0.5f);
		float		noiseWave	= _NoiseAmount * noise + (1 - _NoiseAmount);
		float		distScale	= min(max(dist - _SizeGrowStartDist,0) / _SizeGrowEndDist,1);

		wave = _NoiseAmount < 0.01f ? wave : noiseWave;
		distScale = distScale * distScale * _MaxGrowSize * v.color.a;
		wave += _Bias;

		#if defined(_RAYS)
			ffadeout *= ffadeout;

			nfadeout *= nfadeout;
			nfadeout *= nfadeout;

			nfadeout *= ffadeout;

			float4	vpos = v.vertex;
			float4	mdlPos = v.vertex;
			mdlPos.xyz = vpos - v.normal * saturate(1 - nfadeout) * v.color.a * _ContractionAmount;
		
			o.uv.xy = v.texcoord.xy;
			o.color	= nfadeout * v.color * _MMultiplier;

			#if defined(_BLINK_RAYS)
				mdlPos.xyz = vpos.xyz + distScale * v.normal;
				o.color	= nfadeout * _Color * _MMultiplier * wave;
			#endif
			o.pos	= UnityObjectToClipPos(mdlPos);
		#else
			o.pos = UnityObjectToClipPos(v.vertex);
			o.color = _MMultiplier * _Color * v.color;
		#endif

		return o;
	}

	fixed4 frag (v2f i) : COLOR
	{
		UNITY_SETUP_INSTANCE_ID(i);
		fixed4 col;
		fixed4 tex = tex2D (_MainTex, i.uv.xy);
		col = tex * i.color;
		#if defined(DETAILTEX)
			fixed4 tex2 = tex2D (_DetailTex, i.uv.zw);
			col *= tex2;
		#endif
		
		#if defined(LIGHTMAP_ON)
			col.rgb *= DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lmap));
		#endif
		return col;
	}



#endif