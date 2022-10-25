#if !defined(SG3_CHARACTER_INCLUDED)
#define SG3_CHARACTER_INCLUDED


#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "Lighting.cginc"
#include "UnityStandardUtils.cginc"
//#include "Common.cginc"

	sampler2D _MainTex, _MaskTex, _ReflectTex;

	float4 _MainTex_ST;

	fixed3 _SpecCol, _shadowColor, _ReflectColor, _RimColor;
	float _SpecPower, _BloomFactor, _Contrast, _ReflectPower, _ReflectionMultiplier, _RimPower, _rimMultiplier;


#if defined(HIGHPOLY_CHARACTER)
	sampler2D _NormalTex, _LightTex, _NoiseTex, _SkinMaskTex;
	float4 _NoiseTex_ST, _Color;
	fixed3 _LightColor, _HeightColor, _NoiseColor, _SkinSpecCol;
	float _Offset, _SpecMultiplier, _HeightLightCompensation, _Scroll2X, _Scroll2Y, _MMultiplier, _innerRim, _TimeOnDuration, _TimeOffDuration, _SkinSpecPower, _SkinSpecMultiplier, _LightMultiplier;
	fixed _BumpScale, _HighScaleX, _HighScaleY, _HighScaleZ, _Cutoff;
#endif

	#if defined(LOWPOLY_CHARACTER)
		struct v2f
		{
		    float4 pos      : SV_POSITION;
		    float3 wNormal  : NORMAL;
		    float4 uv       : TEXCOORD0;
		    float3 worldPos : TEXCOORD1;
		    SHADOW_COORDS(2)
		};
	#endif

	#if defined(HIGHPOLY_CHARACTER)
		struct v2f
        {
            float4 pos      : SV_POSITION;
            float4 uv       : TEXCOORD0;
            float3 worldPos : TEXCOORD1;
            half3 tspace0   : TEXCOORD2;
            half3 tspace1   : TEXCOORD3;
            half3 tspace2   : TEXCOORD4;
            SHADOW_COORDS(5)
        };
	#endif

	//fixed4 GetAlbedo(v2f i){
	//	fixed4 albedo = 0;
	//	albedo = tex2D(_MainTex, i.uv.xy);
	//	return albedo;
	//}

	//fixed4 GetMaskCol(v2f i){
	//	fixed4 maskCol = 0;
	//	maskCol = tex2D(_MaskTex, i.uv.xy);
	//	return maskCol;
	//}


	v2f vert(appdata_full v)
	{
	    v2f o;
	    UNITY_INITIALIZE_OUTPUT(v2f, o);
	    o.pos = UnityObjectToClipPos(v.vertex);
	    o.uv.xy = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
	    #if defined(LOWPOLY_CHARACTER)
	    	o.wNormal = UnityObjectToWorldNormal(v.normal);
	    #endif
	    #if defined(HIGHPOLY_CHARACTER)
//			float fracTime = fmod(_Time.y, _TimeOnDuration + _TimeOffDuration);
//			float wave = step(_TimeOnDuration * 0.25 , fracTime) * (1- step(_TimeOnDuration , fracTime));
//			wave = _Time.x * wave;
			o.uv.zw = TRANSFORM_TEX(v.texcoord, _NoiseTex) + float2(frac(_Scroll2X * _Time.x), frac(_Scroll2Y * _Time.x));
	   	    half3 wNormal = UnityObjectToWorldNormal(v.normal);
			half3 wTangent = UnityObjectToWorldDir(v.tangent.xyz);
			half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
			half3 wBitangent = cross(wNormal, wTangent) * tangentSign;
			o.tspace0 = half3(wTangent.x, wBitangent.x, wNormal.x);
			o.tspace1 = half3(wTangent.y, wBitangent.y, wNormal.y);
			o.tspace2 = half3(wTangent.z, wBitangent.z, wNormal.z);
			
	    #endif

	    o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
		
		TRANSFER_SHADOW(o);

	    return o;
	}

	float4 frag(v2f i) : SV_Target
    {   
    	fixed4 mainCol = tex2D(_MainTex, i.uv.xy);
		fixed4 maskCol = tex2D(_MaskTex, i.uv.xy);
    	#if defined(LOWPOLY_CHARACTER)
		        	//apply contrast
				fixed3 avgColor = fixed3(0.5, 0.5, 0.5);
				mainCol.rgb = lerp(avgColor, mainCol, _Contrast);

				half3 N = normalize(i.wNormal);
				//float3 RfR = reflect(-_WorldSpaceLightPos0.xyz, float3(0,1,0));
				float3 RfR = _WorldSpaceLightPos0.xyz * float3(-1, 1, -1);
				float NdotL = max(0.0, dot(RfR, N));// * 0.49 + 0.49;


				//float NdotL = max(0.0, dot(N, _WorldSpaceLightPos0.xyz));// * 0.49 + 0.49;
				float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				half3 h = normalize(_WorldSpaceLightPos0.xyz + viewDir);
				float nh = max(0.0, dot(N, h));
				fixed3 specColor = _SpecCol* (pow(nh, _SpecPower) * maskCol.r) * 2.0 * mainCol.rgb;
				fixed3 diffSpecCol= specColor + mainCol.rgb;

			float3 matnormal = normalize(mul((float3x3)UNITY_MATRIX_V, i.wNormal));
			float2 matCapUV = matnormal.xy * 0.5 + 0.5;
			fixed4 refColor = tex2D(_ReflectTex, matCapUV);
			refColor.rgb = diffSpecCol * pow((refColor.rgb * _ReflectColor.rgb), _ReflectPower) * _ReflectionMultiplier * maskCol.g;

			float fr = saturate(1.0 - dot(viewDir, N));
			fixed3 rimColor = saturate(pow(NdotL * fr , _RimPower) * _RimColor).rgb * _rimMultiplier;
			//fixed3 finalCol = lerp((diffSpecCol * diffSpecCol), diffSpecCol, 1.0);
			fixed3 finalCol = diffSpecCol + refColor + rimColor;

			float shadow = SHADOW_ATTENUATION(i);

		#endif

		#if defined(HIGHPOLY_CHARACTER)

			fixed3 skinMaskCol = tex2D(_SkinMaskTex, i.uv.xy);
			skinMaskCol.r = 1.0 - skinMaskCol.r;
			float3 tNormal = UnpackScaleNormal(tex2D(_NormalTex, i.uv.xy), _BumpScale);
			half3 worldNormal;
			worldNormal.x = dot(i.tspace0, tNormal);
			worldNormal.y = dot(i.tspace1, tNormal);
			worldNormal.z = dot(i.tspace2, tNormal);
			worldNormal = normalize(worldNormal);

			fixed3 noiseColor = tex2D(_NoiseTex, i.uv.zw).rgb;
			fixed3 noiseDiffColor = (noiseColor * (mainCol.rgb * _NoiseColor)) * (maskCol.a * _MMultiplier);

			float3 matnormal = normalize(mul((float3x3)UNITY_MATRIX_V, worldNormal));
			float2 matCapUV = matnormal.xy * 0.5 + 0.5;
			fixed3 diffuseCol = (tex2D(_LightTex, matCapUV) * 1.2).xyz * _LightColor.xyz * maskCol.r * _LightMultiplier + mainCol;
			fixed3 albedo = lerp(mainCol.rgb, diffuseCol, maskCol.b) + noiseDiffColor;

			float NdotL = dot(worldNormal, _WorldSpaceLightPos0.xyz);
			float PNdotL = max(0.0, NdotL);
			float HNdotL = NdotL * 0.49 + 0.49;
			float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

			float3 refLight = normalize(reflect(-viewDir, worldNormal)); 

			//stylized Highlights for cartoon rendering
			refLight = refLight - _HighScaleX * refLight.x * fixed3(1, 0, 0);
			refLight = normalize(refLight);
			refLight = refLight - _HighScaleY * refLight.y * fixed3(0, 1, 0);
			refLight = normalize(refLight);
			refLight = refLight - _HighScaleZ * refLight.z * fixed3(0, 0, 1);
			refLight = normalize(refLight);
			//

			float specFactor = max(0.0, dot(refLight, _WorldSpaceLightPos0.xyz) * 0.49 + 0.49);

			fixed3 specColor = _SpecCol* (pow(specFactor, _SpecPower) * maskCol.r) * _SpecMultiplier * 2.0 * albedo;
			fixed3 skinSpecColor = _SkinSpecCol* (pow(specFactor, _SkinSpecPower) * skinMaskCol.r) * _SkinSpecMultiplier * 2.0 ;
			fixed4 refColor = tex2D(_ReflectTex, matCapUV);
//			float3 RfR = reflect(-viewDir, worldNormal);
//			float Rf = dot(RfR, _WorldSpaceLightPos0.xyz) * 0.5 + 0.5;

			refColor.rgb = albedo * pow((refColor.rgb * _ReflectColor.rgb), _ReflectPower) * _ReflectionMultiplier * maskCol.g;
			float fr = saturate(1.0 - dot(viewDir, worldNormal));
			fixed3 rimColor1 = (saturate(pow(fr , _RimPower)) * mainCol.rgb * _innerRim).rgb ;
			fixed3 rimColor2 = (saturate(pow(HNdotL * fr , _RimPower) * (1.0 + _RimPower)) * _RimColor).rgb * _rimMultiplier;
//			fixed3 rimColor = rimColor1 + rimColor2;
			//albedo = lerp(albedo + rimColor1, refColor + rimColor2, maskCol.r);
			albedo = (albedo + rimColor1)* (1-maskCol.g) + refColor.rgb + rimColor2;
						
//			float ramColFactor = tex2D(_RampMap, float2(HNdotL, 0.5)).r;
			fixed3 diffSpecCol= specColor + albedo + skinSpecColor;
//			fixed3 finalCol = lerp((diffSpecCol * diffSpecCol), diffSpecCol, ramColFactor);
			fixed3 finalCol = diffSpecCol;

			float height = 1-((mul(unity_ObjectToWorld, float4(0.0, 0.0, 0.0, 1.0)).y + _Offset) - i.worldPos.y);
			height = saturate(height + worldNormal.y * 0.5);
			finalCol = saturate(finalCol * lerp(_HeightColor.xyz, float3(1.0, 1.0, 1.0), height) * _HeightLightCompensation);
			float shadow = SHADOW_ATTENUATION(i);

			skinMaskCol.g = 1.0 - skinMaskCol.g;
			shadow = saturate(shadow + skinMaskCol.g);

		#endif
			
			finalCol = lerp(finalCol * _shadowColor , finalCol, shadow);   
			
			//finalCol = EncodeColor(finalCol);
		#if defined(TRANSPARENT)
			clip (mainCol.a - _Cutoff);
			return fixed4(finalCol, mainCol.a);
		#else
			return fixed4(finalCol, _BloomFactor);
		#endif
        

    }

#endif