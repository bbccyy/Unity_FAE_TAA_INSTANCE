Shader "Babeitime/Character/Toonshader"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_OutlineTex("Texture", 2D) = "white" {}
		_SSSTex("SSS (RGB)", 2D) = "white" {}
		_ILMTex("ILM (RGB)", 2D) = "white" {}
		//_MainSample ("_MainSample Texture", 2D) = "white" {}
		_Shininess("Shininess", Range(0.001, 2)) = 0.2
		_SpecStep("SpecStep",Range(0.1,0.3)) = 0.3
		_OutlineColor("Outline Color", Color) = (0,0,0,1)
		_Outline("Outline Width", Range(0,0.01)) = 0.01
		_ShadowContrast("Shadow Contrast", Range(-1,1)) = 0.2
		_ShadowOffset("ShadowOffset", Range(-1,1)) = 0.2
		_ShadowColor("Shadow Color", Color) = (1,1,1,1)
		_ShadowEnhance("Shadow Enhance", Range(0.1, 10)) = 0.5
		_BrightColor("Bright Color", Color) = (1,1,1,1)
		_DarkenInnerLine("Darken Inner Line", Range(0, 1)) = 0.2
		_RimColor("Rim Color", Color) = (0,1,0.8758622,0)
		_RimPower("Rim Power", Range(0,1)) = 0.9
		_RimOffset("Rim Offset", Float) = 0.24
		//_WorldLightDir ("WorldLightDir",Vector) = (1,1,1,0.5)
		//UI遮罩
		_StencilComp ("Stencil Comparison", Float) = 8
		_Stencil ("Stencil ID", Float) = 0
		_StencilOp ("Stencil Operation", Float) = 0
		_StencilWriteMask ("Stencil Write Mask", Float) = 255
		_StencilReadMask ("Stencil Read Mask", Float) = 255
		[HDR] _ColorToMulti ("Color to multiply", Color) = (1,1,1,1)
		[HideInInspector] _SrcBlend ("_SrcBlend", Float) = 1
		[HideInInspector] _DstBlend ("_DstBlend", Float) = 0
		[HideInInspector] _ModelScale ("_ModelScale", Float) = 1
//		[Toggle(_AdditionalLights)] _AddLights ("AddLights", Float) = 1
	}
  
		SubShader
		{
			Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
			HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
			#include "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariablesFunctions.hlsl"
			
			float4 _CharLightColorInScene;
			CBUFFER_START (UnityPerMaterial)
				half4 _ShadowColor;
				half4 _BrightColor;
				float4 _ColorToMulti;
				float4 _MainTex_ST;
				float _ShadowContrast;
				float _ShadowOffset;
				float _DarkenInnerLine;
                float _Shininess;
                float _SpecStep;
				float _RimOffset;
				float _RimPower;
				float4 _RimColor;
				float _ShadowEnhance;
				float _ModelScale;
                half _Outline;
				half4 _OutlineColor;
            CBUFFER_END
				
			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);
			TEXTURE2D(_OutlineTex);
			SAMPLER(sampler_OutlineTex);
			TEXTURE2D(_SSSTex);
			SAMPLER(sampler_SSSTex);
			TEXTURE2D(_ILMTex);
			SAMPLER(sampler_ILMTex); 
			
			ENDHLSL
			
			//UI遮罩
            Stencil 
            {
                Ref [_Stencil]
                Comp [_StencilComp]
                Pass [_StencilOp] 
                ReadMask [_StencilReadMask]
                WriteMask [_StencilWriteMask]
            }


			Pass
			{
				Tags{"LightMode" = "UniversalForward"}
				Blend [_SrcBlend] [_DstBlend]
				
				HLSLPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_fog
//				#pragma multi_compile_fwdbase
				#pragma shader_feature _USE_CHAR_LIGHT_COLOR
//				#pragma shader_feature _ _AdditionalLights
				#pragma shader_feature _ _MAIN_LIGHT_SHADOWS
				#pragma shader_feature _ _MAIN_LIGHT_SHADOWS_CASCADE
				
                #pragma multi_compile _ _SHADOWS_SOFT
                #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS

				struct appdata
				{
					float4 vertex : POSITION;
					float2 texCoord : TEXCOORD0;
					half4 color : COLOR;
					float3 normal : NORMAL;
				};

				struct v2f
				{
					float4 pos : SV_POSITION;
					float2 uv : TEXCOORD0;
					half4 color : COLOR;
					float3 normal : NORMAL;
					float4 positionWS : TEXCOORD1;
					float fogCoord : TEXCOORD2;
					float4 _ShadowCoord : TEXCOORD3;
				};

                half luminance(half3 color) {
                    return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
                }
                
                half4 CalculateAddLight(v2f i,half3 lightColor, half3 lightDirectionWS, half lightAttenuation, half3 normalWS, half3 viewDirectionWS)
				{
					half4 finCol;
					half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
					half4 sssTex = SAMPLE_TEXTURE2D(_SSSTex, sampler_SSSTex, i.uv);
					half4 ilmTex = SAMPLE_TEXTURE2D(_ILMTex, sampler_ILMTex, i.uv); 
					
					finCol = mainTex;

					half3 brightCol = mainTex.rgb * _BrightColor.rgb;
					half3 shadowCol = mainTex.rgb * sssTex.rgb * _ShadowColor.rgb;
					
					half lineCol = ilmTex.a;
					lineCol = lerp(lineCol,_DarkenInnerLine,step(lineCol,_DarkenInnerLine));

					half shadow = ilmTex.g;
					//shadow *= i.color.r;
					half shadowThreshold = 1 - shadow + _ShadowContrast;

//					float3 viewDirWS = normalize(viewDirectionWS);
					float NdotL = dot(normalWS,lightDirectionWS);
					float NdotL1 = dot(normalWS,lightDirectionWS);
					NdotL1 -= shadowThreshold;

					half ilmTexR = ilmTex.r;
					half ilmTexB = ilmTex.b;

					float shadowContrast = step(shadowThreshold,NdotL);

					if (NdotL1 < -1)
					{
						shadowCol *= sssTex.rgb;
					}
					shadowCol = 0;
					finCol.rgb = lerp(shadowCol,brightCol*lightColor.rgb,shadowContrast);

					return finCol;
				}
                
                half3 LightingBased(v2f i,Light light, half3 normalWS, half3 viewDirectionWS)
                {
                    // 注意light.distanceAttenuation * light.shadowAttenuation，这里已经将距离衰减与阴影衰减进行了计算
                    return CalculateAddLight(i,light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS).xyz;
                }
                
				v2f vert(appdata v)
				{
					v2f o;
					o.pos = TransformObjectToHClip(v.vertex.xyz);
					o.normal = TransformObjectToWorldNormal(v.normal);
					o.uv = TRANSFORM_TEX(v.texCoord,_MainTex);
					o.color = v.color;
					o.positionWS = mul(UNITY_MATRIX_M, v.vertex);
					o.fogCoord = ComputeFogFactor(o.pos.z);
					//TRANSFER_SHADOW(o);
					// 接收影子的位置向光源偏移1.2m，避免接收自己的影子
					float4 sw = o.positionWS + _MainLightPosition * 1.2;
					o._ShadowCoord = TransformWorldToShadowCoord(sw.xyz);
					return o;
				}

				half4 frag(v2f i) : SV_Target
				{
				//TODO 人物shader多光源处理是一致的，有空主光并入其他光源处理
				    Light mainLight = GetMainLight();
//				     #ifdef _AdditionalLights
				     //由于urp现在的多光源设置，mainlight可能是光亮最强却不影响物体的光(对物体亮度为0)
				     //故在本项目光源设置下，先检查主光源是否为0，如果为0对所有光源做一个遍历，找出最亮光设置为主光源。
				        uint pixelLightCount = GetAdditionalLightsCount();
				        uint maxIndex = -1;
				     	if(mainLight.distanceAttenuation==0){
				            half maxLumin = -999;
                            for (uint lightIndex = 0; lightIndex < pixelLightCount; ++ lightIndex)
                            {
                                // 获取其他光源
                                Light light = GetAdditionalLight(lightIndex, i.positionWS.xyz);
                                if(light.distanceAttenuation>0){
                                    half tLumin = luminance(light.color);
                                     if(tLumin>maxLumin){
                                        maxIndex = lightIndex;
                                        maxLumin = tLumin;
                                     }
                                }
                            }
                            if(pixelLightCount>0){
                                mainLight = GetAdditionalLight(maxIndex, i.positionWS.xyz);
                            }

				        }
//                    #endif
				    //mainLight = GetAdditionalLight(0, i.positionWS);
				    float4 lightColor;
				     lightColor.xyz = mainLight.color * mainLight.distanceAttenuation;
				    #if _USE_CHAR_LIGHT_COLOR
				    //让角色自身单独的光
				    lightColor = _CharLightColorInScene;
				    #endif
					float4 finCol;
					half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
					half4 outlineTex = SAMPLE_TEXTURE2D(_OutlineTex, sampler_OutlineTex, i.uv);
					half4 sssTex = SAMPLE_TEXTURE2D(_SSSTex, sampler_SSSTex, i.uv);
					half4 ilmTex = SAMPLE_TEXTURE2D(_ILMTex, sampler_ILMTex, i.uv); 
					
					float realShadow = MainLightRealtimeShadow(i._ShadowCoord);
					// 实时阴影的影响度（0不影响，0.5实时影子变暗一半，1完全用实时影子）
					float realShadowInfluence = 0.5;

					finCol = mainTex;

					float3 brightCol = mainTex.rgb * _BrightColor.rgb;
					// TAG: 实时阴影调整最亮色
					//brightCol *= 1 - (1 - realShadow) * realShadowInfluence;
					float3 shadowCol = mainTex.rgb * sssTex.rgb * _ShadowColor.rgb;
					// TAG: 实时阴影调整最暗色
					//shadowCol *= 1 - (1 - realShadow) * realShadowInfluence;
					//设置内描边
					float lineCol = ilmTex.a;
					lineCol = lerp(lineCol,_DarkenInnerLine,step(lineCol,_DarkenInnerLine));

//                    return float4(ilmTex.r,0,0,1);
                    //对模型角落设置更多阴影，模仿ao
					float shadow = ilmTex.g;
					//shadow = 0.5;
					//shadow *= i.color.r;
					float shadowThreshold = 1 - shadow + _ShadowContrast;

					float3 normalWS = normalize(i.normal);
					float3 lightDir = normalize(mainLight.direction);//normalize(_WorldLightDir.xyz);
					float3 viewDirWS = GetWorldSpaceNormalizeViewDir(i.positionWS.xyz);
                    //运算N*L来计算反射光强
					float NdotL = dot(normalWS,lightDir);
					float NdotL1 = dot(normalWS,lightDir);
					NdotL1 -= shadowThreshold + _ShadowOffset;

					float ilmTexR = ilmTex.r;
					float ilmTexB = ilmTex.b;

					float shadowContrast = step(shadowThreshold,NdotL);

					if (NdotL1 < -1)
					{
						shadowCol *= sssTex.rgb;
					}

					finCol.rgb = lerp(shadowCol,brightCol,shadowContrast);
					finCol *= outlineTex;
					//finCol.rgb = NdotL1;
					//高光，鼻，锁骨肌肉凸起，脸颊在小角度下会高光
					finCol.rgb += shadowCol * _ShadowEnhance*step(_SpecStep,ilmTexB*pow(abs(NdotL),_Shininess*ilmTexR * 128)) *shadowContrast;
					//内描边，舍弃
					finCol.rgb *= lineCol;
					finCol *= lightColor;
					
					// 计算其他光源
//                    #ifdef _AdditionalLights
                        for (uint lightIndex = 0; lightIndex < pixelLightCount; ++ lightIndex)
                        {
                            // 获取其他光源
                            Light light = GetAdditionalLight(lightIndex, i.positionWS.xyz);
                            if(light.distanceAttenuation>0&&lightIndex!=maxIndex){
                                 finCol.rgb += LightingBased(i,light, normalWS, viewDirWS);
                            }
                        }
//                        finCol=half4(1,1,1,1);
//                    #endif
					
					//finCol *= 1 + UNITY_LIGHTMODEL_AMBIENT;
					finCol.a = mainTex.a;

					//边缘光
					float dotResult = dot(normalWS,viewDirWS);
					float bright = pow(1 - saturate(dotResult + _RimOffset) , _RimPower);
					float3 clr = saturate(bright) * (_RimColor * lightColor).rgb;

					finCol.rgb += clr;

					//finCol = i.fogCoord.xy;

					//finCol.rgba *=mainTex.rgba;
					//finCol *= NdotL;

					// TAG: 实时阴影调整整个颜色
					finCol.rgb *= 1 - (1 - realShadow) * realShadowInfluence;

					finCol.rgb = MixFog(finCol.rgb, i.fogCoord);
					finCol *= _ColorToMulti;
					return finCol;
				}
				ENDHLSL
			}

//			Pass
//			{
//				Tags{"LightMode" = "DepthOnly"}
//				Blend [_SrcBlend] [_DstBlend]
// 
//				HLSLPROGRAM
//				#pragma vertex vert
//				#pragma fragment frag
//				#pragma multi_compile_fog
////				#pragma multi_compile_fwdbase
//				#pragma shader_feature _USE_CHAR_LIGHT_COLOR
////				#pragma shader_feature _ _AdditionalLights
//				#pragma shader_feature _ _MAIN_LIGHT_SHADOWS
//				#pragma shader_feature _ _MAIN_LIGHT_SHADOWS_CASCADE
//
//				struct appdata
//				{
//					float4 vertex : POSITION;
//					float2 texCoord : TEXCOORD0;
//					half4 color : COLOR;
//					float3 normal : NORMAL;
//				};
//
//				struct v2f
//				{
//					float4 pos : SV_POSITION;
////					float2 uv : TEXCOORD0;
////					half4 color : COLOR;
////					float3 normal : NORMAL;
////					float4 positionWS : TEXCOORD1;
////					float fogCoord : TEXCOORD2;
////					float4 _ShadowCoord : TEXCOORD3;
//				};
//                
//				v2f vert(appdata v)
//				{
//					v2f o;
//					o.pos = TransformObjectToHClip(v.vertex.xyz);
//					return o;
//				}
//
//				half4 frag(v2f i) : SV_Target
//				{
//					return 0;
//				}
//				ENDHLSL
//			}

        Pass
        {
            Name "ShadowCaster"
            Tags {"LightMode" = "ShadowCaster"}
            
            ZWrite On // the only goal of this pass is to write depth!
            ZTest LEqual // early exit at Early-Z stage if possible            
            ColorMask 0 // we don't care about color, we just want to write depth, ColorMask 0 will save some write bandwidth
            Cull Back // support Cull[_Cull] requires "flip vertex normal" using VFACE in fragment shader, which is maybe beyond the scope of a simple tutorial shader
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            struct sa2v{
                float4 positionOS : POSITION;
                float4 normalOS : NORMAL;
                float2 texcoord : TEXCOORD;
            };  
            
            struct sv2f{
                float4 positionCS : SV_POSITION;
            };
            
            half3 _LightDirection;
            
            sv2f vert(sa2v input)
            { 
                sv2f output;
                float3 posWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = normalize(TransformObjectToWorldNormal(input.normalOS.xyz));
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(posWS,normalWS,_LightDirection));
                //not UNITY_REVERSE_Z!!!!
                #if UNITY_REVERSED_Z
                positionCS.z = min(positionCS.z, positionCS.w*UNITY_NEAR_CLIP_VALUE);
                #else
                positionCS.z = max(positionCS.z, positionCS.w*UNITY_NEAR_CLIP_VALUE);
                #endif
                output.positionCS = positionCS;
                return output;
            }
            
            real4 frag(sv2f input): SV_TARGET
            {
                return 0;
            }
            
            ENDHLSL
        }
			
		}
		//FallBack "Babeltime/Diffuse"
}