Shader "FAE/Cliff_Coverage_Trans"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[ASEBegin]_ObjectColor("Object Color", Color) = (1,1,1,0)
		[NoScaleOffset]_Objectalbedo("Object albedo", 2D) = "white" {}
		[NoScaleOffset]_Objectnormals("Object normals", 2D) = "bump" {}
		_GlobalColor("Global Color", Color) = (1,1,1,0)
		[NoScaleOffset]_Globalalbedo("Global albedo", 2D) = "gray" {}
		_Globaltiling("Global tiling", Float) = 1.56
		[NoScaleOffset]_Detailnormal("Detail normal", 2D) = "bump" {}
		_Detailstrength("Detail strength", Range( 0 , 1)) = 1
		[NoScaleOffset]_CoverageAlbedo("Coverage Albedo", 2D) = "white" {}
		[NoScaleOffset]_CoverageNormals("Coverage Normals", 2D) = "bump" {}
		_Roughness("Roughness", Range( 0 , 1)) = 0.5
		_CoverageAmount("CoverageAmount", Range( 0 , 2)) = 0.13
		_CoverageTiling("CoverageTiling", Range( 0 , 5)) = 0
		[ASEEnd]_CoverageMap("CoverageMap", 2D) = "white" {}
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

			#pragma shader_feature _ LIGHTMAP_SHADOW_MIXING
			#pragma shader_feature _ SHADOWS_SHADOWMASK
			#pragma shader_feature _ _SCREEN_SPACE_OCCLUSION

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
				float2 uv : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
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
				half4 color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			sampler2D _Globalalbedo;
			sampler2D _Objectalbedo;
			sampler2D _CoverageAlbedo;
			sampler2D _Objectnormals;
			sampler2D _Detailnormal;
			sampler2D _CoverageNormals;
			sampler2D _CoverageMap;
			float4 _TerrainUV;

			UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
    			UNITY_DEFINE_INSTANCED_PROP(half4, _GlobalColor)
    			UNITY_DEFINE_INSTANCED_PROP(half4, _ObjectColor)
    			UNITY_DEFINE_INSTANCED_PROP(float, _Globaltiling)
    			UNITY_DEFINE_INSTANCED_PROP(float, _CoverageTiling)
    			UNITY_DEFINE_INSTANCED_PROP(float, _Detailstrength)
    			UNITY_DEFINE_INSTANCED_PROP(float, _CoverageAmount)
    			UNITY_DEFINE_INSTANCED_PROP(float, _Roughness)
			UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
			
			VertexOutput vert ( VertexInput v )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.uv = v.uv;
				o.color = v.color;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				//float3 positionVS = TransformWorldToView( positionWS );
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
					float3 normalWS = TransformObjectToWorldNormal(normalize(SAMPLE_TEXTURE2D(_TerrainNormalmapTexture, sampler_TerrainNormalmapTexture, sampleCoords).rgb * 2 - 1));
					float3 tangentWS = -cross(GetObjectToWorldMatrix()._13_23_33, normalWS);
					float3 bitangentWS = cross(normalWS, -tangentWS);
				#else
					float3 normalWS = normalize( IN.tSpace0.xyz );
					float3 tangentWS = IN.tSpace1.xyz;
					float3 bitangentWS = IN.tSpace2.xyz;
				#endif
				float3 positionWS = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 viewdirWS = _WorldSpaceCameraPos.xyz  - positionWS;
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				ShadowCoords = TransformWorldToShadowCoord( positionWS );
				
				viewdirWS = SafeNormalize( viewdirWS );

				half2 positionWS_xz = half2(positionWS.x , positionWS.z);
				half2 positionWS_xy = half2(positionWS.x , positionWS.y);
				half2 positionWS_yz = half2(positionWS.y , positionWS.z);
				float cos68 = cos( 1.55 );
				float sin68 = sin( 1.55 );
				half2 positionWS_yz_rotate = mul( positionWS_yz, float2x2( cos68 , -sin68 , sin68 , cos68 ));

				float3 normalOS = abs( mul( GetWorldToObjectMatrix(), half4( normalWS , 0.0 ) ).xyz ) / dot( abs( mul( GetWorldToObjectMatrix(), half4( normalWS , 0.0 ) ).xyz ) , float3(1,1,1) );
				half4 albedo_objectTex = tex2D( _Objectalbedo, IN.uv );
				half4 col_global = ( _GlobalColor * ( ( ( tex2D( _Globalalbedo, ( _Globaltiling * positionWS_yz_rotate ) ) * normalOS.x ) + ( tex2D( _Globalalbedo, ( _Globaltiling * positionWS_xz ) ) * normalOS.y ) ) + ( tex2D( _Globalalbedo, ( _Globaltiling * positionWS_xy ) ) * normalOS.z ) ) );
				half4 col_object = _ObjectColor * albedo_objectTex;
				half2 uv_coverage = IN.uv * _CoverageTiling;
				half3 normal_objectTex = UnpackNormalScale( tex2D( _Objectnormals, IN.uv ), 1.0 );
				half3 normal_detailTex = UnpackNormalScale( tex2D( _Detailnormal, IN.uv ), 1.0 );
				half3 normal_texBlend = lerp( normal_objectTex , BlendNormal( normal_objectTex , normal_detailTex ) , _Detailstrength);
				
				half2 uv_terrain_zw = half2(_TerrainUV.z , _TerrainUV.w);
				float2 uv_terrainM = ((1.0 - uv_terrain_zw) / _TerrainUV.x) + ((_TerrainUV.x / (_TerrainUV.x * _TerrainUV.x)) * (positionWS).xz);
				half coverage_Tex_r = tex2D(_CoverageMap, uv_terrainM).r * _CoverageAmount;
				
				half3 normal_output = lerp(normal_texBlend, UnpackNormalScale(tex2D(_CoverageNormals, uv_coverage), 1.0f), saturate((normalWS.y * coverage_Tex_r)));
				half3 tbn_x = float3( tangentWS.x, bitangentWS.x, normalWS.x );
				half3 tbn_y = float3( tangentWS.y, bitangentWS.y, normalWS.y );
				half3 tbn_z = float3( tangentWS.z, bitangentWS.z, normalWS.z );
				half3 normal_coverageWS = float3(dot(tbn_x,normal_output), dot(tbn_y,normal_output), dot(tbn_z,normal_output));
				half4 col_output = lerp( ( saturate( (( col_object > 0.5 ) ? ( 1.0 - 2.0 * ( 1.0 - col_object ) * ( 1.0 - col_global ) ) : ( 2.0 * col_object * col_global ) ) )) , tex2D( _CoverageAlbedo, uv_coverage ) , saturate( ( normal_coverageWS.y * coverage_Tex_r ) ));
				
				half smooth_output = lerp( 0.0 , ( _Roughness * albedo_objectTex.a ) , IN.color.g);
				
				half3 Albedo = col_output.rgb;
				float3 Normal = normal_output;
				half3 Emission = 0;
				half3 Specular = 0.5;
				half3 Metallic = 0;
				float Smoothness = smooth_output;
				half Occlusion = 1;
				half Alpha = 1;
				half AlphaClipThreshold = 0.5;
				half AlphaClipThresholdShadow = 0.5;
				half BakedGI = 0;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				InputData inputData;
				inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.clipPos);
				inputData.shadowMask = SAMPLE_SHADOWMASK(IN.lightmapUVOrVertexSH.xy);
				
				inputData.positionWS = positionWS;
				inputData.viewDirectionWS = viewdirWS;
				inputData.shadowCoord = ShadowCoords;

				inputData.normalWS = TransformTangentToWorld(Normal, half3x3( tangentWS, bitangentWS, normalWS ));
				inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);

				inputData.fogCoord = IN.fogFactorAndVertexLight.x;

				inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;
				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					half3 SH = SampleSH(inputData.normalWS.xyz);
				#else
					half3 SH = IN.lightmapUVOrVertexSH.xyz;
				#endif

				inputData.bakedGI = SAMPLE_GI( IN.lightmapUVOrVertexSH.xy, SH, inputData.normalWS );
				#ifdef _ASE_BAKEDGI
					inputData.bakedGI = BakedGI;
				#endif
				half4 color = UniversalFragmentPBR(
				inputData, 
				Albedo, 
				Metallic, 
				Specular, 
				Smoothness, 
				Occlusion, 
				Emission, 
				Alpha);

				#ifdef ASE_FINAL_COLOR_ALPHA_MULTIPLY
					color.rgb *= color.a;
				#endif

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
			#include "common.cginc"
			
			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 normalOS : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
    			UNITY_DEFINE_INSTANCED_PROP(float4, _GlobalColor)
    			UNITY_DEFINE_INSTANCED_PROP(float4, _ObjectColor)
    			UNITY_DEFINE_INSTANCED_PROP(float, _Globaltiling)
    			UNITY_DEFINE_INSTANCED_PROP(float, _CoverageTiling)
    			UNITY_DEFINE_INSTANCED_PROP(float, _Detailstrength)
    			UNITY_DEFINE_INSTANCED_PROP(float, _CoverageAmount)
    			UNITY_DEFINE_INSTANCED_PROP(float, _Roughness)
			UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
			
			float3 _LightDirection;

			VertexOutput vert ( VertexInput v )
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

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

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );
			
				float4 ShadowCoords = float4( 0, 0, 0, 0 );
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					#ifdef _ALPHATEST_SHADOW_ON
						clip(Alpha - AlphaClipThresholdShadow);
					#else
						clip(Alpha - AlphaClipThreshold);
					#endif
				#endif

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
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
    			UNITY_DEFINE_INSTANCED_PROP(float4, _GlobalColor)
    			UNITY_DEFINE_INSTANCED_PROP(float4, _ObjectColor)
    			UNITY_DEFINE_INSTANCED_PROP(float, _Globaltiling)
    			UNITY_DEFINE_INSTANCED_PROP(float, _CoverageTiling)
    			UNITY_DEFINE_INSTANCED_PROP(float, _Detailstrength)
    			UNITY_DEFINE_INSTANCED_PROP(float, _CoverageAmount)
    			UNITY_DEFINE_INSTANCED_PROP(float, _Roughness)
			UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

			VertexOutput vert ( VertexInput v )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );
				o.clipPos = positionCS;
				return o;
			}

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				float Alpha = 1;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

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
			//#define ASE_FOG 1
			#define _NORMALMAP 1
			//#define ASE_SRP_VERSION 70301

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_META

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			//#define ASE_NEEDS_FRAG_WORLD_POSITION
			//#define ASE_NEEDS_VERT_NORMAL

			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 normalOS : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 uv : TEXCOORD0;
				half4 tangentOS : TANGENT;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float3 worldPos : TEXCOORD0;
				float4 normalWS : TEXCOORD2;
				float2 uv : TEXCOORD3;
				float4 tangentWS : TEXCOORD4;
				float4 bitangentWS : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
    			UNITY_DEFINE_INSTANCED_PROP(float4, _GlobalColor)
    			UNITY_DEFINE_INSTANCED_PROP(float4, _ObjectColor)
    			UNITY_DEFINE_INSTANCED_PROP(float, _Globaltiling)
    			UNITY_DEFINE_INSTANCED_PROP(float, _CoverageTiling)
    			UNITY_DEFINE_INSTANCED_PROP(float, _Detailstrength)
    			UNITY_DEFINE_INSTANCED_PROP(float, _CoverageAmount)
    			UNITY_DEFINE_INSTANCED_PROP(float, _Roughness)
			UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
			sampler2D _Globalalbedo;
			sampler2D _Objectalbedo;
			sampler2D _CoverageAlbedo;
			sampler2D _Objectnormals;
			sampler2D _Detailnormal;
			sampler2D _CoverageNormals;
			sampler2D _CoverageMap;
			float4 _TerrainUV;

			VertexOutput vert ( VertexInput v )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.normalWS.xyz = TransformObjectToWorldNormal(v.normalOS);
				o.tangentWS.xyz = TransformObjectToWorldDir(v.tangentOS.xyz);
				o.bitangentWS.xyz = cross(o.normalWS.xyz, o.tangentWS.xyz) * v.tangentOS.w * unity_WorldTransformParams.w;
				o.uv.xy = v.uv.xy;
				o.worldPos = TransformObjectToWorld( v.vertex.xyz );
				o.clipPos = MetaVertexPosition( v.vertex, v.texcoord1.xy, v.texcoord1.xy, unity_LightmapST, unity_DynamicLightmapST );

				return o;
			}

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				//#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 positionWS = IN.worldPos;
				//#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				half2 positionWS_xz = (half2(positionWS.x , positionWS.z));
				half2 positionWS_xy = (half2(positionWS.x , positionWS.y));
				half2 positionWS_yz = (half2(positionWS.y , positionWS.z));
				float cos68 = cos( 1.55 );
				float sin68 = sin( 1.55 );
				half2 positionWS_yz_rotate = mul( positionWS_yz - float2( 0,0 ) , float2x2( cos68 , -sin68 , sin68 , cos68 )) + float2( 0,0 );
				
				half3 normalWS = IN.normalWS.xyz;
				float3 normalOS = abs(mul(GetWorldToObjectMatrix(), half4(normalWS, 0.0)).xyz) / dot(abs(mul(GetWorldToObjectMatrix(), half4(normalWS, 0.0)).xyz), float3(1,1,1));

				half4 albedo_objectTex = tex2D( _Objectalbedo, IN.uv );
				half4 col_global = _GlobalColor * (((tex2D(_Globalalbedo, (_Globaltiling * positionWS_yz_rotate)) * normalOS.x) + (tex2D(_Globalalbedo, (_Globaltiling * positionWS_xz)) * normalOS.y)) + (tex2D(_Globalalbedo, (_Globaltiling * positionWS_xy)) * normalOS.z));
				half4 col_object = _ObjectColor * albedo_objectTex;
				
				half2 uv_terrain_zw = half2(_TerrainUV.z , _TerrainUV.w);
				float2 uv_terrainM = ((1.0 - uv_terrain_zw) / _TerrainUV.x) + ((_TerrainUV.x / ( _TerrainUV.x * _TerrainUV.x)) * positionWS.xz);
				half coverage_Tex_r = ( tex2D( _CoverageMap, uv_terrainM ).r * _CoverageAmount );

				half2 uv_coverage = IN.uv * _CoverageTiling;
				half3 normal_objectTex = UnpackNormalScale(tex2D(_Objectnormals, IN.uv), 1.0);
				half3 normal_detailTex = UnpackNormalScale(tex2D(_Detailnormal, IN.uv), 1.0);
				half3 normal_texBlend = lerp(normal_objectTex, BlendNormal(normal_objectTex, normal_detailTex), _Detailstrength);
				half3 normal_output = lerp( normal_texBlend , UnpackNormalScale( tex2D( _CoverageNormals, uv_coverage ), 1.0f ) , saturate( ( normalWS.y * coverage_Tex_r ) ));
				
				half3 tangentWS = IN.tangentWS.xyz;
				float3 bitangentWS = IN.bitangentWS.xyz;
				half3 tbn_x = float3( tangentWS.x, bitangentWS.x, normalWS.x );
				half3 tbn_y = float3( tangentWS.y, bitangentWS.y, normalWS.y );
				half3 tbn_z = float3( tangentWS.z, bitangentWS.z, normalWS.z );
				half3 normal_coverageWS = float3(dot(tbn_x,normal_output), dot(tbn_y,normal_output), dot(tbn_z,normal_output));
				half4 col_output = lerp((saturate(((col_object > 0.5) ? (1.0 - 2.0 * (1.0 - col_object) * (1.0 - col_global)) : (2.0 * col_object * col_global)))), tex2D(_CoverageAlbedo, uv_coverage), saturate((normal_coverageWS.y * coverage_Tex_r)));
				
				half3 Albedo = col_output.rgb;
				half Emission = 0;
				half Alpha = 1;
				half AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				MetaInput metaInput = (MetaInput)0;
				metaInput.Albedo = Albedo;
				metaInput.Emission = Emission;
				
				return MetaFragment(metaInput);
			}
			ENDHLSL
		}

	//Fallback "Babeltime/Diffuse"
	}
}