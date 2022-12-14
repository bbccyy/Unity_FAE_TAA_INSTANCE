#if !defined(SG3_SCENEBULDING_INCLUDED)
#define SG3_SCENEBULDING_INCLUDED


#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"
//#include "Common.cginc"

#if defined(FOG_LINEAR) || defined(FOG_EXP) ||defined(FOG_EXP2)
	#if !defined(FOG_DISTANCE)
		#define FOG_DEPTH 1
	#endif
	#define FOG_ON 1
#endif


#if !defined(LIGHTMAP_ON) && defined(SHADOWS_SCREEN)
	#if defined(SHADOWS_SHADOWMASK) && !defined(UNITY_NO_SCREENSPACE_SHADOWS)
		#define ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS 1
	#endif
#endif

#if defined(LIGHTMAP_ON) && defined(SHADOWS_SCREEN)
	#if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK)
		#define SUBTRACTIVE_LIGHTING 1
	#endif
#endif

	sampler2D _MainTex, _NormalMap, _EmissionMap, _MetallicMap;
	float4 _MainTex_ST;
	float4 _MainCol, _SpecCol, _EmissionCol;
	float _LightMapMML;

	fixed _CutOff, _Metallic, _Shininess , _BumpScale;




	struct v2f
	{
		float4 pos : SV_POSITION;
		float4 uv : TEXCOORD0;
		float3 normal : NORMAL;
		#if defined(BINORMAL_PER_FRAGMENT)
			float4 tangent : TEXCOORD1;
		#else
			float3 tangent : TEXCOORD1;
			float3 binormal : TEXCOORD2;
		#endif

		#if FOG_DEPTH
			float4 worldPos : TEXCOORD3;
		#else
			float3 worldPos : TEXCOORD3;
		#endif

		UNITY_SHADOW_COORDS(4)

		#if defined(VERTEXLIGHT_ON)
			float3 vertexLightColor : TEXCOORD5;
		#endif

		#if defined(LIGHTMAP_ON) || ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS
			float2 lightmapUV : TEXCOORD5;
		#endif

		#if defined(DYNAMICLIGHTMAP_ON)
			float2 dynamicLightmapUV : TEXCOORD6;
		#endif
		UNITY_VERTEX_INPUT_INSTANCE_ID
	};

	float3 GetAlbedo (v2f i){
		fixed3 albedo = 0;
		#if defined(UNLIT_BACKGROUND)
			albedo = tex2D(_MainTex, i.uv.xy); 
		#else
			albedo = tex2D(_MainTex, i.uv.xy) * _MainCol;
		#endif
		return albedo;
	}

	float GetAlpha (v2f i){
		float alpha = _MainCol.a;
		#if !defined(_METALLIC_MAP)
			alpha *= tex2D(_MainTex, i.uv.xy).a;
		#endif
		return alpha;
	}

	float3 GetTangentSpaceNormal (v2f i){
		float3 normal = float3(0, 0, 1);
		#if defined(_NORMAL_MAP)
			normal = UnpackScaleNormal(tex2D(_NormalMap, i.uv.xy), _BumpScale);
		#endif
		return normal;
	}

	float GetMetallic (v2f i) {
		#if defined(_SMOOTHNESS_METALLIC) && defined(_METALLIC_MAP)
			return tex2D(_MainTex, i.uv.xy).a;
		#else
			return _Metallic;
		#endif
	}



	float3 GetEmission (v2f i){
		#if defined(FORWARD_BASE_PASS) || defined(DEFERRED_PASS)
			#if defined(_EMISSION_MAP)
				return tex2D(_EmissionMap, i.uv.xy) * _EmissionCol;
			#else
				return _EmissionCol;
			#endif
		#else
			return 0;
		#endif
	}



	float3 CreateBinormal (float3 normal, float3 tangent, float binormalSign){
		return cross(normal, tangent.xyz) * (binormalSign * unity_WorldTransformParams.w);
	}

	void ComputeVertexLightColor (inout v2f i){
			#if defined(VERTEXLIGHT_ON)
				i.vertexLightColor = Shade4PointLights(unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0, unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb, unity_4LightAtten0, i.worldPos.xyz, i.normal);
			#endif
	}



	v2f vert (appdata_full v)
	{
		UNITY_SETUP_INSTANCE_ID(v);
		v2f o;
		UNITY_INITIALIZE_OUTPUT(v2f, o);
		UNITY_TRANSFER_INSTANCE_ID(v, o);
		UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);

		o.worldPos.xyz = mul(unity_ObjectToWorld, v.vertex).xyz;
		#if FOG_DEPTH
			o.worldPos.w = o.pos.z;
		#endif
		o.normal = UnityObjectToWorldNormal(v.normal);

		#if defined(BINORMAL_PER_FRAGMENT)
			o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
		#else
			o.tangent = UnityObjectToWorldDir(v.tangent.xyz);
			o.binormal = CreateBinormal(o.normal, o.tangent, v.tangent.w);
		#endif

		#if defined(LIGHTMAP_ON) || ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS
			o.lightmapUV = v.texcoord1 * unity_LightmapST.xy + unity_LightmapST.zw;
		#endif

		#if defined(DYNAMICLIGHTMAP_ON)
			o.dynamicLightmapUV = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
		#endif

		UNITY_TRANSFER_SHADOW(o, v.texcoord1);

		ComputeVertexLightColor(o);
//		UNITY_TRANSFER_FOG(o,o.pos);

		return o;
	}





////////******************* Metallic Function
inline half MyOneMinusReflectivityFromMetallic(half metallic)
{
    // We'll need oneMinusReflectivity, so
    //   1-reflectivity = 1-lerp(dielectricSpec, 1, metallic) = lerp(1-dielectricSpec, 0, metallic)
    // store (1-dielectricSpec) in unity_ColorSpaceDielectricSpec.a, then
    //   1-reflectivity = lerp(alpha, 0, metallic) = alpha + metallic*(0 - alpha) =
    //                  = alpha - metallic * alpha
    half oneMinusDielectricSpec = unity_ColorSpaceDielectricSpec.a;
    return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
}

inline half3 MyDiffuseAndSpecularFromMetallic (half3 albedo, half metallic, out half3 specColor, out half oneMinusReflectivity)
{
    specColor = lerp (unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);
	oneMinusReflectivity = MyOneMinusReflectivityFromMetallic(metallic);
    return albedo * oneMinusReflectivity;
}


float FadeShadows (v2f i, float attenuation) {
	#if HANDLE_SHADOWS_BLENDING_IN_GI || ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS
		// UNITY_LIGHT_ATTENUATION doesn't fade shadows for us.
		#if ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS
			attenuation = SHADOW_ATTENUATION(i);
		#endif
		float viewZ = dot(_WorldSpaceCameraPos - i.worldPos, UNITY_MATRIX_V[2].xyz);
		float shadowFadeDistance = UnityComputeShadowFadeDistance(i.worldPos, viewZ);
		float shadowFade = UnityComputeShadowFade(shadowFadeDistance);
		float bakedAttenuation = UnitySampleBakedOcclusion(i.lightmapUV, i.worldPos);
		attenuation = UnityMixRealtimeAndBakedShadows(attenuation, bakedAttenuation, shadowFade);
	#endif

	return attenuation;
}

void ApplySubtractiveLighting(v2f i, inout UnityIndirect indirectLight){
	#if SUBTRACTIVE_LIGHTING
		UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos.xyz);
		attenuation = FadeShadows(i, attenuation);

		float ndotl = saturate(dot(i.normal, _WorldSpaceLightPos0.xyz));
		float3 shadowedLightEstimate = ndotl * (1 - attenuation) * _LightColor0.rgb;
		float3 subtractedLight = indirectLight.diffuse - shadowedLightEstimate;
		subtractedLight = max(subtractedLight, unity_ShadowColor.rgb);
		subtractedLight = lerp(subtractedLight, indirectLight.diffuse, _LightShadowData.x);
		indirectLight.diffuse = min(subtractedLight, indirectLight.diffuse); 
	#endif
}

float3 BoxProjection(float3 direction, float3 position, float4 cubemapPosition, float3 boxMin, float3 boxMax){
	#if UNITY_SPECCUBE_BOX_PROJECTION
		UNITY_BRANCH
		if(cubemapPosition.w > 0){
			float3 factors = ((direction > 0 ? boxMax : boxMin) - position) / direction;
			float scalar = min(min(factors.x, factors.y), factors.z);
			direction = direction * scalar + (position - cubemapPosition);
		}
	#endif
	return direction;
}





UnityLight CreateLight (v2f i) {
	UnityLight light;
	#if defined(DEFERRED_PASS) || SUBTRACTIVE_LIGHTING
		light.dir = float3(0, 1, 0);
		light.color = 0;
	#else
		#if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
			light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
		#else
			light.dir = _WorldSpaceLightPos0.xyz;
		#endif

		UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos.xyz);
		attenuation = FadeShadows(i, attenuation);

		light.color = _LightColor0.rgb * attenuation;

	#endif
	light.ndotl = DotClamped(i.normal, light.dir);
	return light;
}

UnityIndirect CreateIndirectLight (v2f i, float3 viewDir){
	UnityIndirect indirectLight;
	indirectLight.diffuse = 0;
	indirectLight.specular = 0;

	#if defined(VERTEXLIGHT_ON)
		indirectLight.diffuse = i.vertexLightColor;
	#endif

	#if defined(FORWARD_BASE_PASS) || defined(DEFERRED_PASS)
		#if defined(LIGHTMAP_ON)
			indirectLight.diffuse = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lightmapUV));

			#if defined(DIRLIGHTMAP_COMBINED)
				float4 lightmapDirection = UNITY_SAMPLE_TEX2D_SAMPLER(unity_LightmapInd, unity_Lightmap, i.lightmapUV);
				indirectLight.diffuse = DecodeDirectionalLightmap(indirectLight.diffuse, lightmapDirection, i.normal);
			#endif

			ApplySubtractiveLighting(i, indirectLight);
		#endif

		#if defined(DYNAMICLIGHTMAP_ON)
			float3 dynamicLightDiffuse = DecodeRealtimeLightmap(UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, i.dynamicLightmapUV));
			#if defined(DIRLIGHTMAP_COMBINED)
				float4 dynamicLightmapDirection = UNITY_SAMPLE_TEX2D_SAMPLER(unity_DynamicDirectionality, unity_DynamicLightmap, i.dynamicLightmapUV);
				indirectLight.diffuse += DecodeDirectionalLightmap(dynamicLightDiffuse, dynamicLightmapDirection, i.normal);
			#else
				indirectLight.diffuse += dynamicLightDiffuse;
			#endif
		#endif

		#if !defined(LIGHTMAP_ON) && !defined(DYNAMICLIGHTMAP_ON)
			#if UNITY_LIGHT_PROBE_PROXY_VOLUME
				if (unity_ProbeVolumeParams.x == 1){
					indirectLight.diffuse = SHEvalLinearL0L1_SampleProbeVolume(float4(i.normal, 1), i.worldPos);
					#if defined(UNITY_COLORSPACE_GAMMA)
						 indirectLight.diffuse = LinearToGammaSpace(indirectLight.diffuse);
					#endif
				}
				else {
					indirectLight.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));
				}
			#else
				indirectLight.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));
			#endif
		#endif

		float3 reflectionDir = reflect(-viewDir, i.normal);
		Unity_GlossyEnvironmentData envData;
		envData.roughness = 1 - _Shininess;
		envData.reflUVW = BoxProjection(reflectionDir, i.worldPos.xyz, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
		float3 probe0 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData);
		envData.reflUVW = BoxProjection(reflectionDir, i.worldPos.xyz, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
		#if UNITY_SPECCUBE_BLENDING
			float interpolator = unity_SpecCube0_BoxMin.w;
			UNITY_BRANCH
			if (interpolator < 0.99999) {
				float3 probe1 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0),unity_SpecCube0_HDR, envData);
				indirectLight.specular = lerp(probe1, probe0, interpolator);
			}
			else {
				indirectLight.specular = probe0;
			}
		#else
			indirectLight.specular = probe0;
		#endif

		#if defined(DEFERRED_PASS) && UNITY_ENABLE_REFLECTION_BUFFERS
			indirectLight.specular = 0;
		#endif
	#endif

		
	return indirectLight;
}

void InitializeFragmentNormal(inout v2f i){
	float3 tangentSpaceNormal = GetTangentSpaceNormal(i);
	#if defined(BINORMAL_PER_FRAGMENT)
		float3 binormal = CreateBinormal(i.normal, i.tangent.xyz, i.tangent.w);
	#else
		float3 binormal = i.binormal;
	#endif

	i.normal = normalize(tangentSpaceNormal.x * i.tangent + tangentSpaceNormal.y * binormal + tangentSpaceNormal.z * i.normal);
}

float4 ApplyFog(float4 col, v2f i){
	#if FOG_ON
		float viewDistance = length(_WorldSpaceCameraPos - i.worldPos.xyz);
		#if FOG_DEPTH
			viewDistance = UNITY_Z_0_FAR_FROM_CLIPSPACE(i.worldPos.w);
		#endif
		UNITY_CALC_FOG_FACTOR_RAW(viewDistance);
		float3 fogColor = 0;
		#if defined(FORWARD_BASE_PASS)
			fogColor = unity_FogColor.rgb;
		#endif
		col.rgb = lerp(fogColor, col.rgb, saturate(unityFogFactor));
	#endif
	return col;
}


fixed4 frag (v2f i) : SV_Target{
		UNITY_SETUP_INSTANCE_ID(i);
		fixed4 col;
		col = 0;
		float alpha = GetAlpha(i);
		#if defined(_RENDERING_CUTOUT)
			clip(alpha - _CutOff);
		#endif

		InitializeFragmentNormal(i);

		float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
		half3 specularTint;
		half oneMinusReflectivity;
		float3 albedo = MyDiffuseAndSpecularFromMetallic(GetAlbedo(i), GetMetallic(i), specularTint, oneMinusReflectivity);
		
		#if defined(_RENDERING_TRANSPARENT)
			albedo *= alpha;
			alpha = 1 - oneMinusReflectivity + alpha * oneMinusReflectivity;
		#endif

		UnityLight  light = CreateLight(i);
		UnityIndirect indirectLight = CreateIndirectLight(i, viewDir);


		half3 h = normalize (light.dir + viewDir);
		float nh = DotClamped(i.normal, h);
		float spec = pow(nh, _Shininess * 128.0) * GetMetallic(i) * unity_LightGammaCorrectionConsts_PIDiv4;


		half nv = DotClamped(i.normal, viewDir);
		//half lh = DotClamped(light.dir, h);
		half smoothness = _Shininess;
		half grazingTerm = saturate(smoothness + (1 - oneMinusReflectivity));  

		col.rgb = GetAlbedo(i) * (indirectLight.diffuse + light.color * light.ndotl) + spec * light.color * _SpecCol + max(0.0, (indirectLight.specular * FresnelLerpFast (specularTint, grazingTerm, nv) - 0.1));

		col.rgb += GetEmission(i);
		
		#if defined(_RENDERING_FADE) || defined(_RENDERING_TRANSPARENT)
			col.a = alpha;
		#endif		
		#if defined (UNLIT_BACKGROUND) 
			col = tex2D(_MainTex, i.uv);
		#endif
		col = ApplyFog(col, i);
		//col.rgb = EncodeColor(col.rgb);
		return col;
	}



#endif