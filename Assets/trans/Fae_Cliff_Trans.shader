Shader "FAE/Cliff_Trans"
{
    Properties
    {
        [HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
        [HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
        [ASEBegin]_ObjectColor("Object Color", Color) = (1,1,1,0)
        [NoScaleOffset]_Objectalbedo("Object albedo", 2D) = "white" {}
        [NoScaleOffset]_Objectnormals("Object normals", 2D) = "bump" {}
        _GlobalColor("Global Color", Color) = (1,1,1,0)
        [NoScaleOffset]_Globalalbedo("Global albedo", 2D) = "gray" {}
        _Globaltiling("Global tiling", Float) = 1.56
        _Detailnormal("Detail normal", 2D) = "bump" {}
        _Detailstrength("Detail strength", Range( 0 , 1)) = 1
        [ASEEnd]_Roughness("Roughness", Range( 0 , 1)) = 0.5
        [HideInInspector] _texcoord( "", 2D ) = "white" {}
    }

    SubShader
    {
        LOD 0
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
        Cull Back
        AlphaToMask Off

        Pass
        {
            Name "Forward"
            Tags { "LightMode"="UniversalForward" }
            
            Blend One Zero, One Zero
            ZWrite On
            ZTest LEqual
            Offset 0 , 0
            ColorMask RGBA

            HLSLPROGRAM
            #pragma multi_compile_instancing
            #pragma shader_feature _ LOD_FADE_CROSSFADE
            #pragma multi_compile_fog
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define SHADERPASS_FORWARD

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
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float4 uv : TEXCOORD0;
                float4 lightmapUV : TEXCOORD1;
                half4 vertColor : COLOR;
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
                half4 vertColor : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            // CBUFFER_START(UnityPerMaterial)
            //     float4 _GlobalColor;
            //     float4 _ObjectColor;
            //     float4 _Detailnormal_ST;
            //     float _Globaltiling;
            //     float _Detailstrength;
            //     float _Roughness;
            // CBUFFER_END

			UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
    			UNITY_DEFINE_INSTANCED_PROP(half4, _GlobalColor)
    			UNITY_DEFINE_INSTANCED_PROP(half4, _ObjectColor)
    			UNITY_DEFINE_INSTANCED_PROP(float4, _Detailnormal_ST)
    			UNITY_DEFINE_INSTANCED_PROP(float, _Globaltiling)
    			UNITY_DEFINE_INSTANCED_PROP(float, _Detailstrength)
    			UNITY_DEFINE_INSTANCED_PROP(float, _Roughness)
			UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
            sampler2D _Globalalbedo;
            sampler2D _Objectalbedo;
            sampler2D _Objectnormals;
            sampler2D _Detailnormal;
            
            VertexOutput vert ( VertexInput v )
            {
                VertexOutput o = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.uv.xy = v.uv.xy;
                o.vertColor = v.vertColor;

                float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );
                float4 positionCS = TransformWorldToHClip( positionWS );

                VertexNormalInputs normalInput = GetVertexNormalInputs( v.normalOS, v.tangentOS );

                o.tSpace0 = float4( normalInput.normalWS, positionWS.x);
                o.tSpace1 = float4( normalInput.tangentWS, positionWS.y);
                o.tSpace2 = float4( normalInput.bitangentWS, positionWS.z);

                OUTPUT_LIGHTMAP_UV( v.lightmapUV, unity_LightmapST, o.lightmapUVOrVertexSH.xy );
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
                float3 WorldPosition = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
                float3 WorldViewDirection = _WorldSpaceCameraPos.xyz  - WorldPosition;
                half4 ShadowCoords = half4( 0, 0, 0, 0 );
                ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
                
                WorldViewDirection = SafeNormalize( WorldViewDirection );

                half4 ObjectAlbedoTex = tex2D( _Objectalbedo, IN.uv );
                half4 col = _ObjectColor * ObjectAlbedoTex;

                float2 worldUV_xz = float2(WorldPosition.x , WorldPosition.z);
                float2 worldUV_xy = float2(WorldPosition.x , WorldPosition.y);
                float2 worldUV_yz = float2(WorldPosition.y , WorldPosition.z);
                float cos68 = cos(1.55);
                float sin68 = sin(1.55);
                float2 worldUV_yz_rotate = mul( worldUV_yz, float2x2( cos68 , -sin68 , sin68 , cos68 ));

                float3 NormalOS = abs( mul( GetWorldToObjectMatrix(), half4( WorldNormal , 0.0 ) ).xyz ) / dot( abs( mul( GetWorldToObjectMatrix(), half4( WorldNormal , 0.0 ) ).xyz ) , float3(1,1,1) );
                //float3 NormalOS = TransformWorldToObjectDir(WorldNormal);
                half4 col_global = _GlobalColor * (tex2D(_Globalalbedo, (_Globaltiling * worldUV_yz_rotate)) * NormalOS.x + tex2D(_Globalalbedo, (_Globaltiling * worldUV_xz)) * NormalOS.y + tex2D(_Globalalbedo, (_Globaltiling * worldUV_xy)) * NormalOS.z);
                
                float3 normalMap = UnpackNormalScale( tex2D( _Objectnormals, IN.uv ), 1.0 );
                float2 uv_Detailnormal = IN.uv * _Detailnormal_ST.xy + _Detailnormal_ST.zw;
                float3 detailNormalMap = UnpackNormalScale( tex2D( _Detailnormal, uv_Detailnormal ), 1.0 );
                float3 Normal = lerp( normalMap , BlendNormal( normalMap , detailNormalMap ) , _Detailstrength);
                
                float Smoothness = lerp( 0.0 , ( _Roughness * ObjectAlbedoTex.a ) , IN.vertColor.g);
                
                half3 Albedo = (saturate(((col > 0.5) ? (1.0 - 2.0 * (1.0 - col) * (1.0 - col_global)) : (2.0 * col * col_global)))).rgb;
                half3 Emission = 0;
                half Specular = 0.5;
                half Metallic = 0;
                half Occlusion = 1;
                half Alpha = 1;

                InputData inputData;

                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.clipPos);
                inputData.shadowMask = SAMPLE_SHADOWMASK(IN.lightmapUVOrVertexSH.xy);
                
                inputData.positionWS = WorldPosition;
                inputData.viewDirectionWS = WorldViewDirection;
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

                half4 color = UniversalFragmentPBR(inputData, Albedo, Metallic, Specular, Smoothness, Occlusion, Emission, Alpha);

                color.rgb = MixFog(color.rgb, IN.fogFactorAndVertexLight.x);
                
                return color;
            }

            ENDHLSL
        }

        Pass
        {
            
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }

            ZWrite On
            ZTest LEqual
            AlphaToMask Off

            HLSLPROGRAM
            #pragma multi_compile_instancing
            #pragma shader_feature _ LOD_FADE_CROSSFADE
            #pragma multi_compile_fog

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

            #pragma vertex vert
            #pragma fragment frag

            #define _NORMALMAP 1

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
    			UNITY_DEFINE_INSTANCED_PROP(half4, _GlobalColor)
    			UNITY_DEFINE_INSTANCED_PROP(half4, _ObjectColor)
    			UNITY_DEFINE_INSTANCED_PROP(float4, _Detailnormal_ST)
    			UNITY_DEFINE_INSTANCED_PROP(float, _Globaltiling)
    			UNITY_DEFINE_INSTANCED_PROP(float, _Detailstrength)
    			UNITY_DEFINE_INSTANCED_PROP(float, _Roughness)
			UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
            
            float3 _LightDirection;

            VertexOutput VertexFunction( VertexInput v )
            {
                VertexOutput o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

                v.normalOS = v.normalOS;

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

            VertexOutput vert ( VertexInput v )
            {
                return VertexFunction( v );
            }

            half4 frag(VertexOutput IN  ) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID( IN );
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );
                
                half4 ShadowCoords = half4( 0, 0, 0, 0 );
                
                half Alpha = 1;
                half AlphaClipThreshold = 0.5;
                half AlphaClipThresholdShadow = 0.5;

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

        Pass
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
    			UNITY_DEFINE_INSTANCED_PROP(half4, _GlobalColor)
    			UNITY_DEFINE_INSTANCED_PROP(half4, _ObjectColor)
    			UNITY_DEFINE_INSTANCED_PROP(float4, _Detailnormal_ST)
    			UNITY_DEFINE_INSTANCED_PROP(float, _Globaltiling)
    			UNITY_DEFINE_INSTANCED_PROP(float, _Detailstrength)
    			UNITY_DEFINE_INSTANCED_PROP(float, _Roughness)
			UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            VertexOutput vert ( VertexInput v )
            {
                VertexOutput o = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                v.normalOS = v.normalOS;
                float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
                float4 positionCS = TransformWorldToHClip( positionWS );

                o.clipPos = positionCS;
                return o;
            }


            half4 frag(VertexOutput IN  ) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

                half4 ShadowCoords = half4( 0, 0, 0, 0 );
                half Alpha = 1;
                half AlphaClipThreshold = 0.5;

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
        
        Pass
        {
            Name "Meta"
            Tags { "LightMode"="Meta" }

            Cull Off

            HLSLPROGRAM
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

            #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            struct VertexInput
            {
                float4 vertex : POSITION;
                float3 normalOS : NORMAL;
                float4 texcoord1 : TEXCOORD1;
                float4 texcoord2 : TEXCOORD2;
                float4 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct VertexOutput
            {
                float4 clipPos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float4 normalWS : TEXCOORD2;
                float4 uv : TEXCOORD3;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

			UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
    			UNITY_DEFINE_INSTANCED_PROP(half4, _GlobalColor)
    			UNITY_DEFINE_INSTANCED_PROP(half4, _ObjectColor)
    			UNITY_DEFINE_INSTANCED_PROP(float4, _Detailnormal_ST)
    			UNITY_DEFINE_INSTANCED_PROP(float, _Globaltiling)
    			UNITY_DEFINE_INSTANCED_PROP(float, _Detailstrength)
    			UNITY_DEFINE_INSTANCED_PROP(float, _Roughness)
			UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            sampler2D _Globalalbedo;
            sampler2D _Objectalbedo;

            VertexOutput vert ( VertexInput v )
            {
                VertexOutput o = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.normalWS.xyz = TransformObjectToWorldNormal(v.normalOS);
                
                o.uv.xy = v.uv.xy;
                
                //setting value to unused interpolator channels and avoid initialization warnings
                o.normalWS.w = 0;
                o.uv.zw = 0;

                float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
                o.worldPos = positionWS;

                o.clipPos = MetaVertexPosition( v.vertex, v.texcoord1.xy, v.texcoord1.xy, unity_LightmapST, unity_DynamicLightmapST );
                return o;
            }

            half4 frag(VertexOutput IN  ) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );
                float3 WorldPosition = IN.worldPos;
                half4 ShadowCoords = half4( 0, 0, 0, 0 );

                float2 worldUV_yz = (float2(WorldPosition.y , WorldPosition.z));
                float cos68 = cos( 1.55 );
                float sin68 = sin( 1.55 );
                float2 worldUV_yz_rotate = mul( worldUV_yz - float2( 0,0 ) , float2x2( cos68 , -sin68 , sin68 , cos68 )) + float2( 0,0 );
                float3 NormalOS = normalize(abs( mul( GetWorldToObjectMatrix(), float4( IN.normalWS.xyz , 0.0)).xyz));
                float2 worldUV_xz = (float2(WorldPosition.x , WorldPosition.z));
                float2 worldUV_xy = (float2(WorldPosition.x , WorldPosition.y));
                half4 col_global = ( _GlobalColor * ( ( ( tex2D( _Globalalbedo, ( _Globaltiling * worldUV_yz_rotate ) ) * NormalOS.x ) + ( tex2D( _Globalalbedo, ( _Globaltiling * worldUV_xz ) ) * NormalOS.y ) ) + ( tex2D( _Globalalbedo, ( _Globaltiling * worldUV_xy ) ) * NormalOS.z ) ) );
                half4 col = ( _ObjectColor * tex2D( _Objectalbedo, IN.uv.xy ) );
                
                half3 Albedo = ( saturate( (( col > 0.5 ) ? ( 1.0 - 2.0 * ( 1.0 - col ) * ( 1.0 - col_global ) ) : ( 2.0 * col * col_global ) ) )).rgb;
                half3 Emission = 0;
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
    }
}