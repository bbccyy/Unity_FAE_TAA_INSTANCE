Shader "FAE/Foliage_trans"
{
	Properties
	{
		_Cutoff( "Mask Clip Value", Float ) = 0.5
		[ASEBegin][NoScaleOffset]_MainTex("MainTex", 2D) = "white" {}
		[NoScaleOffset][Normal]_BumpMap("BumpMap", 2D) = "bump" {}
		_WindTint("WindTint", Range( -0.5 , 0.5)) = 0.1
		_TransmissionSize("Transmission Size", Range( 0 , 20)) = 1
		_TransmissionAmount("Transmission Amount", Range( 0 , 10)) = 2.696819
		_WindSwinging("WindSwinging", Range( 0 , 1)) = 0
		_WindAmplitudeMultiplier("WindAmplitudeMultiplier", Float) = 10
		_MaxWindStrength("Max Wind Strength", Range( 0 , 1)) = 0.126967
		_GlobalWindMotion("GlobalWindMotion", Range( 0 , 1)) = 1
		[ASEEnd]_LeafFlutter("LeafFlutter", Range( 0 , 1)) = 0.495
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
	}

	SubShader
	{
		LOD 0

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
		Cull Back
		AlphaToMask Off
		
		Pass //forward
		{
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }
			
			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			
			HLSLPROGRAM
			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma shader_feature _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define _NORMALMAP 1

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma shader_feature _ _MAIN_LIGHT_SHADOWS
			#pragma shader_feature _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma shader_feature _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma shader_feature _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma shader_feature _ _SHADOWS_SOFT
			#pragma shader_feature _ _MIXED_LIGHTING_SUBTRACTIVE
			
			#pragma shader_feature _ DIRLIGHTMAP_COMBINED
			#pragma shader_feature _ LIGHTMAP_ON

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_FORWARD

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "common.cginc"

			#if defined(UNITY_INSTANCING_ENABLED) && defined(_TERRAIN_INSTANCED_PERPIXEL_NORMAL)
				#define ENABLE_TERRAIN_PERPIXEL_NORMAL
			#endif

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float4 texcoord1 : TEXCOORD1;
				float2 uv : TEXCOORD0;
				half4 color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float4 lightmapUVOrVertexSH : TEXCOORD0;
				half4 fogFactorAndVertexLight : TEXCOORD1;
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
				float2 uv : TEXCOORD7;
				float4 color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			// CBUFFER_START(UnityPerMaterial)
			// 	float _GlobalWindMotion;
			// 	float _WindSwinging;
			// 	float _LeafFlutter;
			// 	float _WindAmplitudeMultiplier;
			// 	float _MaxWindStrength;
			// 	float _WindTint;
			// 	float _TransmissionSize;
			// 	float _TransmissionAmount;
			// 	float _Cutoff;
			// CBUFFER_END

			UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
    			UNITY_DEFINE_INSTANCED_PROP(half, _GlobalWindMotion)
    			UNITY_DEFINE_INSTANCED_PROP(half, _WindSwinging)
    			UNITY_DEFINE_INSTANCED_PROP(half, _LeafFlutter)
    			UNITY_DEFINE_INSTANCED_PROP(half, _WindAmplitudeMultiplier)
    			UNITY_DEFINE_INSTANCED_PROP(half, _MaxWindStrength)
    			UNITY_DEFINE_INSTANCED_PROP(half, _WindTint)
    			UNITY_DEFINE_INSTANCED_PROP(half, _TransmissionSize)
    			UNITY_DEFINE_INSTANCED_PROP(half, _TransmissionAmount)
    			UNITY_DEFINE_INSTANCED_PROP(half, _Cutoff)
			UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

			sampler2D _MainTex;
			sampler2D _BumpMap;
			float _WindSpeed;
			float4 _WindDirection;
			sampler2D _WindVectors;
			float _WindAmplitude;
			float _WindStrength;
			float _WindDebug;
			
			VertexOutput vert ( VertexInput v )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.uv.xy = v.uv.xy;
				o.color = v.color;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float3 positionVS = TransformWorldToView( positionWS );
				float4 positionCS = TransformWorldToHClip( positionWS );

				VertexNormalInputs normalInput = GetVertexNormalInputs( v.normalOS, v.tangentOS );

				o.tSpace0 = float4( normalInput.normalWS, positionWS.x);
				o.tSpace1 = float4( normalInput.tangentWS, positionWS.y);
				o.tSpace2 = float4( normalInput.bitangentWS, positionWS.z);

				OUTPUT_LIGHTMAP_UV( v.texcoord1, unity_LightmapST, o.lightmapUVOrVertexSH.xy );
				OUTPUT_SH( normalInput.normalWS.xyz, o.lightmapUVOrVertexSH.xyz );

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					o.lightmapUVOrVertexSH.zw = v.uv;
					o.lightmapUVOrVertexSH.xy = v.uv * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif

				half3 vertexLight = VertexLighting( positionWS, normalInput.normalWS );
				half fogFactor = ComputeFogFactor( positionCS.z );
				o.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

				o.clipPos = positionCS;

				return o;
			}

			half4 frag ( VertexOutput IN  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float2 sampleCoords = (IN.lightmapUVOrVertexSH.zw / _TerrainHeightmapRecipSize.zw + 0.5f) * _TerrainHeightmapRecipSize.xy;
					float3 WorldNormal = TransformObjectToWorldNormal(normalize(SAMPLE_TEXTURE2D(_TerrainNormalmapTexture, sampler_TerrainNormalmapTexture, sampleCoords).rgb * 2 - 1));
					float3 WorldTangent = -cross(GetObjectToWorldMatrix()._13_23_33, WorldNormal);
					float3 WorldBiTangent = cross(WorldNormal, -WorldTangent);
				#else
					float3 WorldNormal = normalize( IN.tSpace0.xyz );
					float3 WorldTangent = IN.tSpace1.xyz;
					float3 WorldBiTangent = IN.tSpace2.xyz;
				#endif
				float3 positionWS = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 viewdirWS = _WorldSpaceCameraPos.xyz  - positionWS;
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					ShadowCoords = TransformWorldToShadowCoord( positionWS );
				#endif
				
				viewdirWS = SafeNormalize( viewdirWS );

				half4 outcol = tex2D(_MainTex, IN.uv);
				//// half timeScale = _WindSpeed * (_TimeParameters.x * 3);
				half timeScale = _WindSpeed * _Time.x * 3;

				float3 objectScale = float3( length( GetObjectToWorldMatrix()[ 0 ].xyz ), length( GetObjectToWorldMatrix()[ 1 ].xyz ), length( GetObjectToWorldMatrix()[ 2 ].xyz ) );
				half2 winddir_xz = half2(_WindDirection.x , _WindDirection.z);
				half3 windScale = sin(((timeScale * objectScale) * half3(winddir_xz, 0.0)));
				windScale = lerp(((windScale + 1) / (float3( 1,0,0 ) + 1)) , windScale , _WindSwinging);
				float3 windvec = UnpackNormalScale(tex2D(_WindVectors, (((timeScale * 0.05) * winddir_xz) + (((positionWS).xz * 0.01) * _WindAmplitudeMultiplier * _WindAmplitude))), 1.0f);
				
				half2 leafFlutter = _GlobalWindMotion * windScale.x + _LeafFlutter * windvec.xy;
				half3 leafFlutter_x0y = half3(leafFlutter.x , 0.0 , leafFlutter.y);
				float3 wind_Global = leafFlutter_x0y * _MaxWindStrength * IN.color.r * _WindStrength;
				float wind_tint = lerp(wind_Global.x, 0.0, (1.0 - IN.color.r)) * _WindTint * 2.0;
				
				outcol = lerp(outcol , 2.0 , wind_tint);
				half VdotL = dot(-viewdirWS, _MainLightPosition.xyz);
				half transmission = lerp((pow(max(VdotL, 0.0), _TransmissionSize) * _TransmissionAmount), 0.0, ((1.0 - IN.color.r) * 1.33));
				transmission = clamp(transmission, 0.0, 1.0 );

				outcol = lerp(outcol, (outcol * 2.0), transmission);
				half3 normal = UnpackNormalScale(tex2D(_BumpMap, IN.uv), 1.0);
				normal.z = lerp( 1, normal.z, saturate(1.0) );
				
				half3 Albedo = lerp(outcol, half4(windvec, 0.0), _WindDebug).xyz;
				float3 Normal = normal;
				half3 Emission = 0;
				half3 Specular = 0.5;
				half Metallic = 0;
				half Smoothness = 0.5;
				half Occlusion = 1;
				half Alpha = 1;
				half AlphaClipThreshold = 0.5;
				half AlphaClipThresholdShadow = 0.5;
				float3 BakedGI = 0;
				float3 RefractionColor = 1;
				half RefractionIndex = 1;
				float3 Transmission = 1;
				float3 Translucency = 1;

				half alpha = lerp(outcol.a, 1.0 , _WindDebug);
				clip(alpha - _Cutoff);

				InputData inputData;
				inputData.positionWS = positionWS;
				inputData.viewDirectionWS = viewdirWS;
				inputData.shadowCoord = ShadowCoords;

				inputData.normalWS = TransformTangentToWorld(Normal, half3x3( WorldTangent, WorldBiTangent, WorldNormal ));
				inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
				inputData.fogCoord = IN.fogFactorAndVertexLight.x;

				inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;
				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float3 SH = SampleSH(inputData.normalWS.xyz);
				#else
					float3 SH = IN.lightmapUVOrVertexSH.xyz;
				#endif

				inputData.bakedGI = SAMPLE_GI( IN.lightmapUVOrVertexSH.xy, SH, inputData.normalWS );

				half4 color = UniversalFragmentPBR(
				inputData, 
				Albedo, 
				Metallic, 
				Specular, 
				Smoothness, 
				Occlusion, 
				Emission, 
				Alpha);

				color.rgb = MixFog(color.rgb, IN.fogFactorAndVertexLight.x);
				return color;
			}
			ENDHLSL
		}

		Pass //shadow caster
		{
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual
			AlphaToMask Off

			HLSLPROGRAM
			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma shader_feature _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define _NORMALMAP 1

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_SHADOWCASTER

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "common.cginc"
			
			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 normalOS : NORMAL;
				float4 uv : TEXCOORD0;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float2 uv : TEXCOORD2;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
    			UNITY_DEFINE_INSTANCED_PROP(half, _GlobalWindMotion)
    			UNITY_DEFINE_INSTANCED_PROP(half, _WindSwinging)
    			UNITY_DEFINE_INSTANCED_PROP(half, _LeafFlutter)
    			UNITY_DEFINE_INSTANCED_PROP(half, _WindAmplitudeMultiplier)
    			UNITY_DEFINE_INSTANCED_PROP(half, _MaxWindStrength)
    			UNITY_DEFINE_INSTANCED_PROP(half, _WindTint)
    			UNITY_DEFINE_INSTANCED_PROP(half, _TransmissionSize)
    			UNITY_DEFINE_INSTANCED_PROP(half, _TransmissionAmount)
    			UNITY_DEFINE_INSTANCED_PROP(half, _Cutoff)
			UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
			sampler2D _MainTex;
			sampler2D _BumpMap;
			float _WindDebug;
			float3 _LightDirection;

			VertexOutput vert ( VertexInput v )
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				o.uv.xy = v.uv.xy;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float3 normalWS = TransformObjectToWorldDir(v.normalOS);

				float4 clipPos = TransformWorldToHClip( ApplyShadowBias( positionWS, normalWS, _LightDirection ) );

				#if UNITY_REVERSED_Z
					clipPos.z = min(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
				#else
					clipPos.z = max(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
				#endif

				o.clipPos = clipPos;
				return o;
			}

			half4 frag(VertexOutput IN) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				half4 outcol = tex2D(_MainTex, IN.uv);
				//half Alpha = 1;
				half AlphaClipThreshold = 0.5;
				half AlphaClipThresholdShadow = 0.5;

				half alpha = lerp( outcol.a , 1.0 , _WindDebug);
				//clip(alpha - _Cutoff);

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				return 0;
			}

			ENDHLSL
		}
		
		Pass //depth only
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask 0
			AlphaToMask Off

			HLSLPROGRAM
			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma shader_feature _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define _NORMALMAP 1

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "common.cginc"

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 normalOS : NORMAL;
				float4 uv : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float2 uv : TEXCOORD2;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
    			UNITY_DEFINE_INSTANCED_PROP(half, _GlobalWindMotion)
    			UNITY_DEFINE_INSTANCED_PROP(half, _WindSwinging)
    			UNITY_DEFINE_INSTANCED_PROP(half, _LeafFlutter)
    			UNITY_DEFINE_INSTANCED_PROP(half, _WindAmplitudeMultiplier)
    			UNITY_DEFINE_INSTANCED_PROP(half, _MaxWindStrength)
    			UNITY_DEFINE_INSTANCED_PROP(half, _WindTint)
    			UNITY_DEFINE_INSTANCED_PROP(half, _TransmissionSize)
    			UNITY_DEFINE_INSTANCED_PROP(half, _TransmissionAmount)
    			UNITY_DEFINE_INSTANCED_PROP(half, _Cutoff)
			UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
			sampler2D _MainTex;
			sampler2D _BumpMap;
			float _WindDebug;

			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.uv.xy = v.uv.xy;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				o.clipPos = positionCS;
				return o;
			}

			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				//float2 IN.uv = IN.uv.xy;
				half4 outcol = tex2D( _MainTex, IN.uv );
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;

				//float alpha = outcol.a;
				half alpha = lerp( outcol.a , 1.0 , _WindDebug);
				clip( alpha - _Cutoff );

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				return 0;
			}
			ENDHLSL
		}
		
		Pass //meta
		{
			
			Name "Meta"
			Tags { "LightMode"="Meta" }

			Cull Off

			HLSLPROGRAM
			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma shader_feature _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define _NORMALMAP 1

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_META

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "common.cginc"

			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 normalOS : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 uv : TEXCOORD0;
				half4 color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float3 worldPos : TEXCOORD0;
				float2 uv : TEXCOORD2;
				float4 color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
    			UNITY_DEFINE_INSTANCED_PROP(half, _GlobalWindMotion)
    			UNITY_DEFINE_INSTANCED_PROP(half, _WindSwinging)
    			UNITY_DEFINE_INSTANCED_PROP(half, _LeafFlutter)
    			UNITY_DEFINE_INSTANCED_PROP(half, _WindAmplitudeMultiplier)
    			UNITY_DEFINE_INSTANCED_PROP(half, _MaxWindStrength)
    			UNITY_DEFINE_INSTANCED_PROP(half, _WindTint)
    			UNITY_DEFINE_INSTANCED_PROP(half, _TransmissionSize)
    			UNITY_DEFINE_INSTANCED_PROP(half, _TransmissionAmount)
    			UNITY_DEFINE_INSTANCED_PROP(half, _Cutoff)
			UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
			sampler2D _MainTex;
			sampler2D _BumpMap;
			float _WindSpeed;
			float4 _WindDirection;
			sampler2D _WindVectors;
			float _WindAmplitude;
			float _WindStrength;
			float _WindDebug;

			VertexOutput vert ( VertexInput v )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.uv.xy = v.uv.xy;
				o.color = v.color;
				
				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				o.worldPos = positionWS;

				o.clipPos = MetaVertexPosition( v.vertex, v.texcoord1.xy, v.texcoord1.xy, unity_LightmapST, unity_DynamicLightmapST );
				return o;
			}

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				float3 positionWS = IN.worldPos;
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				half4 outcol = tex2D( _MainTex, IN.uv );
				half timeScale = ( _WindSpeed * ( _TimeParameters.x * 3 ) );
				float3 objectScale = float3( length( GetObjectToWorldMatrix()[ 0 ].xyz ), length( GetObjectToWorldMatrix()[ 1 ].xyz ), length( GetObjectToWorldMatrix()[ 2 ].xyz ) );
				half2 winddir_xz = (half2(_WindDirection.x , _WindDirection.z));
				half3 windScale = sin( ( ( timeScale * objectScale ) * half3( winddir_xz ,  0.0 ) ) );
				windScale = lerp(((windScale + 1) / (float3( 1,0,0 ) + 1)) , windScale , _WindSwinging);
				float3 windvec = UnpackNormalScale( tex2D( _WindVectors, ( ( ( timeScale * 0.05 ) * winddir_xz ) + ( ( (positionWS).xz * 0.01 ) * _WindAmplitudeMultiplier * _WindAmplitude ) ) ), 1.0f );
				half2 leafFlutter = ( ( _GlobalWindMotion * (windScale).x ) + ( _LeafFlutter * (windvec).xy ) );
				half3 leafFlutter_x0y = (half3(leafFlutter.x , 0.0 , leafFlutter.y));

				float3 wind_Global = ( leafFlutter_x0y * _MaxWindStrength * IN.color.r * _WindStrength );
				float wind_tint = lerp((wind_Global).x, 0.0, (1.0 - IN.color.r)) * _WindTint * 2.0;

				outcol = lerp(outcol , 2 , wind_tint);
				float3 viewdir_WS = normalize(_WorldSpaceCameraPos.xyz - positionWS);
				half VdotL = dot(-viewdir_WS, _MainLightPosition.xyz);
				half transmission = lerp((pow(max(VdotL, 0.0), _TransmissionSize) * _TransmissionAmount), 0.0, ((1.0 - IN.color.r) * 1.33));
				transmission = clamp(transmission, 0.0, 1.0);
				outcol = lerp(outcol, (outcol * 2.0), transmission);
				
				half3 Albedo = lerp(outcol , half4(windvec , 0.0), _WindDebug).rgb;
				half3 Emission = 0;
				half Alpha = 1;
				half AlphaClipThreshold = 0.5;

				half alpha = lerp(outcol.a, 1.0, _WindDebug);
				clip(alpha - _Cutoff);

				MetaInput metaInput = (MetaInput)0;
				metaInput.Albedo = Albedo;
				metaInput.Emission = Emission;
				
				return MetaFragment(metaInput);
			}
			ENDHLSL
		}
	}
	CustomEditor "UnityEditor.ShaderGraph.PBRMasterGUI"
	Fallback "Babeltime/Diffuse"
}