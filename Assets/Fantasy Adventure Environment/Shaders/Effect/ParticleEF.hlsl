#if !defined(SG3_PARTICLE_INCLUDED)
#define SG3_PARTICLE_INCLUDED


#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

	CBUFFER_START(UnityPerMaterial)
	float4 _MainTex_ST, _Mask_ST, _NoiseTex_ST, _Turbulence_ST; 
	float4 _TintColor, _EdgeColor;
	float _InvFade, _ScrollX, _ScrollY, _Scroll2X, _Scroll2Y, _Palstance, _MaskPalstance;
	float _ColorPower, _TurbulenceAmt, _Cutout, _Edge, _SoftEdge, _Cutoff;
	float _Intensity;
	float _Transparency = 0;	//add by mengzhijiang
	
	float _ZOffset; // 用以做特效镜头方向偏移 by Allen, 20190916
	CBUFFER_END
	
	float4 _NormalMap_ST;
	half _foglerp;
	half _ZWOffsetWordk;
    float _AlphaBoost;
    half _Height;
	//float4 _NormalMap_ST;
	//sampler2D _MainTex, _NoiseTex;
	//sampler2D _Mask, _Turbulence, _NormalMap, _GrabTexture;
	
    TEXTURE2D(_MainTex);		SAMPLER(sampler_MainTex);
	TEXTURE2D(_NoiseTex);	    SAMPLER(sampler_NoiseTex);
	TEXTURE2D(_Mask);			SAMPLER(sampler_Mask);
	TEXTURE2D(_Turbulence);		SAMPLER(sampler_Turbulence);
	TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
	//暂时没用到，先注释了
	//TEXTURE2D(_NormalMap);	SAMPLER(sampler_NormalMap);
	//TEXTURE2D(_GrabTexture);	SAMPLER(sampler_GrabTexture);

	//sampler2D_float _CameraDepthTexture;

	struct appdata
	{
		float4 vertex : POSITION;
        float3 normal : NORMAL;
		float4 color : COLOR;
		float4 uv : TEXCOORD0;
		float2 uv1 : TEXCOORD1;
		UNITY_VERTEX_INPUT_INSTANCE_ID
	};

	struct v2f
	{
		float4 pos : SV_POSITION;
		float4 color : COLOR;
		float4 uv : TEXCOORD0;
		#if defined(_RENDERING_DISSOLVE)
		float4 uv1 : TEXCOORD1;
		#endif
        #ifdef _HEIGHTSOFT_ON
		half heightInfo : TEXCOORD4;
		#endif
		float fogFactor : TEXCOORD2;

		half3 positionWS : TEXCOORD5;

		//UNITY_FOG_COORDS(3)

		UNITY_VERTEX_INPUT_INSTANCE_ID
	};

		
			
	v2f vert (appdata v)
	{
		UNITY_SETUP_INSTANCE_ID(v);
		v2f o;
		//UNITY_INITIALIZE_OUTPUT(v2f, o);
		UNITY_TRANSFER_INSTANCE_ID(v, o);
		UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

        // 用以做特效镜头方向偏移 by Allen, 20190916
        float3	viewerLocal	= mul((float3x3)unity_WorldToObject, _WorldSpaceCameraPos);	
        v.vertex.xyz += normalize(viewerLocal - v.vertex) * _ZOffset;
        //o.pos = UnityObjectToClipPos(v.vertex);
		o.pos = TransformObjectToHClip(v.vertex.xyz);

		o.color = v.color;
		o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
        
		float2 zwOffset = v.uv.zw * _ZWOffsetWordk;

        o.uv.xy = o.uv.xy  + zwOffset;
        
		//
		o.positionWS = TransformObjectToWorld(v.vertex.xyz);

		#if defined(_RENDERING_UVANIMATION) || _RENDERING_DISSOLVE
			o.uv.xy = TRANSFORM_TEX((v.uv + float2(_ScrollX, _ScrollY) * _Time.y), _MainTex) + zwOffset;
			o.uv.zw = TRANSFORM_TEX((v.uv + float2(_Scroll2X, _Scroll2Y) * _Time.y), _Mask);
		#elif defined(_RENDERING_UVROTATION)
		    float4 uv = float4(v.uv.xy, v.uv.xy);
			o.uv = uv - float4(0.5, 0.5, 0.5, 0.5);
			half speed = _Palstance * _Time.y;
			half speed2 = _MaskPalstance * _Time.y;
			o.uv.xy = float2(o.uv.x * cos(speed) - o.uv.y * sin(speed), o.uv.x * sin(speed) + o.uv.y * cos(speed));
			o.uv.zw = float2(o.uv.z * cos(speed2) - o.uv.w * sin(speed2), o.uv.z * sin(speed2) + o.uv.w * cos(speed2));
			o.uv += float4(0.5, 0.5, 0.5, 0.5);
		#endif

		#if defined(_RENDERING_DISSOLVE)
			o.uv1.xy = TRANSFORM_TEX((v.uv.xy + float2(_ScrollX, _ScrollY) * _Time.y), _Turbulence);
			o.uv1.zw = TRANSFORM_TEX((v.uv.xy + float2(_Scroll2X, _Scroll2Y) * _Time.y), _NoiseTex);
		#endif
		
        // 简单的高度软粒子
	    #if  defined(_HEIGHTSOFT_ON)
	    	float3 worldPos = mul(UNITY_MATRIX_M, v.vertex);
	    	o.heightInfo = worldPos.y;
	    #endif
    
		//UNITY_TRANSFER_FOG(o, o.pos);
		o.fogFactor = ComputeFogFactor(o.pos.z);
		return o;
	}
	
	half4 frag (v2f i) : SV_Target
	{
		UNITY_SETUP_INSTANCE_ID(i);
		
		//_SeaPlaneYHeight 在lua中有需要时设置为0，不需要时默认是-1000
		//clip(i.positionWS.y - _SeaPlaneYHeight);

		half4 colScale = half4(_ColorPower * i.color.rgb * _TintColor.rgb, i.color.a * _TintColor.a);
		half4 col = 1;

		#ifndef _RENDERING_DISSOLVE
			col = colScale * SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, i.uv.xy);
		#endif

		#if defined (_RENDERING_UVANIMATION) || _RENDERING_UVROTATION
			half4 colMask = SAMPLE_TEXTURE2D(_Mask,sampler_Mask, i.uv.zw);
			col *= colMask.r;	
		#elif defined(_RENDERING_DISSOLVE)
			half4 colMask = SAMPLE_TEXTURE2D(_Mask,sampler_Mask, i.uv.zw);
			half2 uv = SAMPLE_TEXTURE2D(_NoiseTex,sampler_NoiseTex, i.uv1.zw).rg * _TurbulenceAmt - _TurbulenceAmt * 0.5;
			float2 uvDistortMain = uv + i.uv.xy;
			float2 uvDistortMask = uv + i.uv1.xy;	
			half4 diffCol = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, uvDistortMain);
			#if defined(_TOGGLETURBULENCE)
			half turbulence = saturate(SAMPLE_TEXTURE2D(_Turbulence,sampler_Turbulence, i.uv1.xy).r + 0.001);
			#else
			half turbulence = saturate(SAMPLE_TEXTURE2D(_Turbulence,sampler_Turbulence, uvDistortMask).r + 0.001);
			#endif
			turbulence  = turbulence - (1 - i.color.a + _Cutout);
			half dissolve = smoothstep(0, _SoftEdge, turbulence);
			half edge = smoothstep(_Edge, 0, turbulence);
			col.rgb = lerp(diffCol *  colScale, _EdgeColor, edge);
			col.a = dissolve * diffCol.a * colMask.r * _TintColor.a;
			// 应邀在溶解的a计算时再乘个输入的a。如果溶解效果不对，再把这个去掉。
			col.a *= i.color.a;
		#endif

		#if defined(_USECUTOFF)
			clip(col.a - _Cutoff);
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

		half4 col0 = col;

        // 高度软粒子
		#if defined(_HEIGHTSOFT_ON)
            half dis = i.heightInfo - _Height;
			col.a *= saturate((dis*dis*dis) * _InvFade);
		#endif
    
		//float fogCoord = ComputeFogFactor(i.pos.z);
		//col.rgb = MixFog(col.rgb, fogCoord);
		col.rgb = MixFog(col.rgb, i.fogFactor);
		// apply fog
		//UNITY_APPLY_FOG(i.fogCoord, col);

		//col.rgb = EncodeColor(col.rgb * _Intensity);
		col = (1-_foglerp) * col + _foglerp * col0;

		return col;
	}
	

#endif