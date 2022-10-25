#if !defined(SG3_PARTICLE_INCLUDED)
#define SG3_PARTICLE_INCLUDED

#include "UnityCG.cginc"
//#include "Common.cginc"

	sampler2D _MainTex, _NoiseTex;
	sampler2D _Mask, _Turbulence, _NormalMap, _GrabTexture;
	float4 _MainTex_ST, _Mask_ST, _NoiseTex_ST, _Turbulence_ST, _NormalMap_ST; 
	float4 _TintColor, _EdgeColor;

	float _InvFade, _ScrollX, _ScrollY, _Scroll2X, _Scroll2Y, _Palstance, _MaskPalstance, _HorizontalAmount, _VerticalAmount;
	float _ColorPower, _TurbulenceAmt, _AlphaBoost, _Cutout, _Edge, _SoftEdge, _Speed, _Cutoff;
	float _Intensity;
	float _Transparency = 0;	//add by mengzhijiang
	float _ZOffset; // 用以做特效镜头方向偏移 by Allen, 20190916

	fixed _VerticalBillboarding;

	sampler2D_float _CameraDepthTexture;

	struct appdata
	{
		float4 vertex : POSITION;
		float4 color : COLOR;
		float2 uv : TEXCOORD0;
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
		#ifdef SOFTPARTICLES_ON
			float4 projPos : TEXCOORD2;
		#endif
		UNITY_FOG_COORDS(3)
		UNITY_VERTEX_INPUT_INSTANCE_ID
	};

		
			
	v2f vert (appdata v)
	{
		UNITY_SETUP_INSTANCE_ID(v);
		v2f o;
		UNITY_INITIALIZE_OUTPUT(v2f, o);
		UNITY_TRANSFER_INSTANCE_ID(v, o);
		UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
		#if defined(_BILLBOARD) || _BILLBOARDY
			///Model vertex way
			//float3 center = float3(0, 0, 0);
			//float3 viewer = mul((float3x3)unity_WorldToObject, _WorldSpaceCameraPos);
			//float3 normalDir = viewer - center;
			//normalDir.y = normalDir.y * _VerticalBillboarding;
			//normalDir = normalize(normalDir);
			//float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);
			//float3 rightDir = normalize(cross(upDir, normalDir));
			//upDir = normalize(cross(normalDir, rightDir));
			//float3 centerOffs = v.vertex.xyz - center;
			//float3 localPos = center + rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z;
			//o.pos = UnityObjectToClipPos(float4(localPos, 1));
			///

			///ShadowGun's Billboard 
			float3 centerOffs = float3(float(0.5).xx - v.color.rg, 0) * v.uv1.xyy;
			float3 centerLocal = v.vertex.xyz + centerOffs;
			float3	viewerLocal	= mul((float3x3)unity_WorldToObject, _WorldSpaceCameraPos);	
			float3 localDir = viewerLocal - centerLocal;
			#if defined(_BILLBOARD)
				#define VerticalBillboarding 1.0
			#elif defined(_BILLBOARDY)
				#define VerticalBillboarding 0.0
			#endif
			localDir.y = localDir.y * VerticalBillboarding;
			localDir = normalize(localDir);
			float3 upLocal = abs(localDir.y) > 0.999f ? float3(0, 0, 1) : float3(0, 1, 0);
			float3 rightLocal = normalize(cross(upLocal, localDir));
	
			upLocal = normalize(cross(localDir, rightLocal));
			float3 BBLocalPos = centerLocal - (rightLocal * centerOffs.x + upLocal * centerOffs.y);
			
			// 用以做特效镜头方向偏移 by Allen, 20190916
    		BBLocalPos += normalize(viewerLocal - v.vertex) * _ZOffset;
			o.pos = UnityObjectToClipPos(float4(BBLocalPos, 1));
		#else
			// 用以做特效镜头方向偏移 by Allen, 20190916
			float3	viewerLocal	= mul((float3x3)unity_WorldToObject, _WorldSpaceCameraPos);	
			v.vertex.xyz += normalize(viewerLocal - v.vertex) * _ZOffset;
			o.pos = UnityObjectToClipPos(v.vertex);
		#endif		
		#ifdef SOFTPARTICLES_ON
			o.projPos = ComputeScreenPos(o.pos);
			COMPUTE_EYEDEPTH(o.projPos.z);
		#endif
		o.color = v.color;
		o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
		#if defined(_RENDERING_UVANIMATION) || _RENDERING_DISSOLVE
			o.uv.xy = TRANSFORM_TEX((v.uv + float2(_ScrollX, _ScrollY) * _Time.y), _MainTex);
			o.uv.zw = TRANSFORM_TEX((v.uv + float2(_Scroll2X, _Scroll2Y) * _Time.y), _Mask);
		#elif defined(_RENDERING_UVROTATION)
		    float4 uv = float4(v.uv, v.uv);
			o.uv = uv - float4(0.5, 0.5, 0.5, 0.5);
			half speed = _Palstance * _Time.y;
			half speed2 = _MaskPalstance * _Time.y;
			o.uv.xy = float2(o.uv.x * cos(speed) - o.uv.y * sin(speed), o.uv.x * sin(speed) + o.uv.y * cos(speed));
			o.uv.zw = float2(o.uv.z * cos(speed2) - o.uv.w * sin(speed2), o.uv.z * sin(speed2) + o.uv.w * cos(speed2));
			o.uv += float4(0.5, 0.5, 0.5, 0.5);
		#endif
		#if defined(_RENDERING_DISSOLVE)
			o.uv1.xy = TRANSFORM_TEX((v.uv + float2(_ScrollX, _ScrollY) * _Time.y), _Turbulence);
			o.uv1.zw = TRANSFORM_TEX((v.uv + float2(_Scroll2X, _Scroll2Y) * _Time.y), _NoiseTex);
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
		#if defined(_BILLBOARD) || _BILLBOARDY
			i.color = 1.0;
		#endif
			fixed4 colScale = _ColorPower * i.color * _TintColor;
			fixed4 col = colScale * tex2D(_MainTex, i.uv.xy);
		#if defined (_RENDERING_UVANIMATION) || _RENDERING_UVROTATION
			fixed4 colMask = tex2D(_Mask, i.uv.zw);
			col *= colMask.r;	
		#elif defined(_RENDERING_DISSOLVE)
			fixed4 colMask = tex2D(_Mask, i.uv.zw);
			half2 uv = tex2D(_NoiseTex, i.uv1.zw).rg * _TurbulenceAmt - _TurbulenceAmt * 0.5;
			float2 uvDistortMain = uv + i.uv.xy;
			float2 uvDistortMask = uv + i.uv1.xy;	
			fixed4 diffCol = tex2D(_MainTex, uvDistortMain);
			#if defined(_TOGGLETURBULENCE)
			fixed turbulence = saturate(tex2D(_Turbulence, i.uv1.xy).r + 0.001);
			#else
			fixed turbulence = saturate(tex2D(_Turbulence, uvDistortMask).r + 0.001);
			#endif
			turbulence  = turbulence - (1 - i.color.a + _Cutout);
			fixed dissolve = smoothstep(0, _SoftEdge, turbulence);
			fixed edge = smoothstep(_Edge, 0, turbulence);
			col.rgb = lerp(diffCol *  colScale, _EdgeColor, edge);
			col.a = dissolve * diffCol.a * colMask.r * _TintColor.a;
			// 应邀在溶解的a计算时再乘个输入的a。如果溶解效果不对，再把这个去掉。
			#if !defined(_TOGGLE_STOP_INNER_ALPHA)
			col.a *= i.color.a;
			#endif
		#elif defined(_SEQUENCEANIMATION)
			float time = floor(_Time.y * _Speed);
			float row = floor(time / _HorizontalAmount);
			float column = time - row * _HorizontalAmount;
			half2 uv = i.uv.xy + half2(column, -row);
			uv.x /= _HorizontalAmount;
			uv.y /= _VerticalAmount;
			col = tex2D(_MainTex, uv) * colScale;
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
		// apply fog
		UNITY_APPLY_FOG_COLOR(i.fogCoord, col, fixed4(0,0,0,0));
		
		//col.rgb = EncodeColor(col.rgb * _Intensity);

		return col;
	}
	

#endif