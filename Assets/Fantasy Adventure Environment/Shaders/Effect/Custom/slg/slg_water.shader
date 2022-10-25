// ***********************************************************************
// Copyright 2017-2018 BabelTime, Inc. All Rights Reserved.
//
// Author           : MengZhijiang
// Created          : 03-13-2018
// ***********************************************************************
// 定义SLG地图通用动态水的渲染Shader
//
// Last Modified By		 : MengZhijiang
// Last Modified On		 : 03-13-2018
// Last Modified Content : 提供核心思想算法，具体优化过程需要美术和TA共同完成
//
// ***********************************************************************

Shader "sg3/slg/water"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Color("Color", Color) = (0, 0.175, 0.275, 1)
		_MainTileSize("MainTileSize", Int) = 5
		_NormalTex("Normalmap", 2D) = "bump" {}
		_NormalScale("NormalScale", Range(0.01, 0.1)) = 0.01
		_refractionTex("refractionTex", 2D) = "white" {}
		_NorTileSize("NorTileSize", Vector) = (15, 11, 7, 3)
		_NorSpeed("NorSpeed", Vector) = (1, 1, 1, 1)
		_FlowMap ("FlowMap (RG) Alpha (B) Gradient (A)", 2D) = ""{}
		[MaterialToggle] _Worldspacetiling ("流向", Float ) = 0
		_Glossiness("Glossiness", Range(1, 256)) = 3
		_SpecularFactor("SpecularFactor", Range(0.1, 1.0)) = 0.175
		_Refraction("Refraction", Range(0, 5)) = 1
		_NdotLScale ("暗面", Range(0, 1)) = 0.45
		_CameraLogicOriginOffect("CameraLogicOriginOffect", Vector) = (10, -10, 10, 0)
		_LightingLogicDir("LightingLogicDir", Vector) = (-0.707105, -0.707105, -0.707105, 0)
		_NormalStrength ("Normal Strength", Range(0, 1)) = 1
	}

	SubShader
	{
		Tags{"RenderPipeline"="UniversalPipeline" "RenderType" = "Opaque" }

		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "UnityPBSLighting.cginc"


			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
				float4 color : COLOR;
			};

			struct v2f
			{
				float2 logicPos : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 posWorld : TEXCOORD1;
				float3 normalDir : NORMAL;
				float2 uv : TEXCOORD2;
			};

			sampler2D _MainTex;
			sampler2D _NormalTex;
			sampler2D _FlowMap;
			sampler2D _refractionTex;

			float4 _Color;
			float4 _FlowMap_ST;
			float _MainTileSize;

			float4 _NorTileSize;
			float4 _NorSpeed;
			float4 _FlowMapOffset;
			half _PhaseLength;
			fixed _Worldspacetiling;

			float _Glossiness;
			float _SpecularFactor;
			float _Refraction;
			float _NormalStrength;
			
			fixed _NormalScale;
			fixed _NdotLScale;
			float4 _CameraLogicOriginOffect;

			float4 _LightingLogicDir = float4(0, -0.707105, -0.707105, 0);	//光照在逻辑空间的方向，程序可动态设置此变量

			//代码更新此变量
			float2 _ScreenCentreLogicPos = float2(0, 0);		//屏幕中心点逻辑空间的位置
			float4 _NormalDisturbance = float4(0, 0, 0, 0);		//法线扰动

			v2f vert(appdata v)
			{
				v2f o;
				o.normalDir = UnityObjectToWorldNormal(v.normal);
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _FlowMap);
				o.logicPos = v.color.xy + v.uv.yx;
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}

			//光照主要放逻辑空间计算
			//法线的b通道为主方法方向
			//而逻辑空间方向方向应该是z向上，所以把法线的rgb换成rbg
			fixed4 frag(v2f i) : SV_Target
			{
				i.normalDir = normalize(i.normalDir);			

				//normal 0
				//half2 nor_uv_0 = i.logicPos.yx / _NorTileSize.x;
				half2 nor_uv_0 = i.posWorld.rg / _NorTileSize.x;
				nor_uv_0 += _Time.x.xx * 0.05f * half2(0.5, 1) * _NorSpeed.x;
				half3 nor_0 = UnpackNormal(tex2D(_NormalTex, nor_uv_0));

				//normal 1
				//half2 nor_uv_1 = i.logicPos.yx / _NorTileSize.y;
				half2 nor_uv_1 = i.posWorld.rg / _NorTileSize.y;
				nor_uv_1 += _Time.x.xx * 0.05f  * half2(0.5, -1) * _NorSpeed.y;
				half3 nor_1 = UnpackNormal(tex2D(_NormalTex, nor_uv_1));

				////normal 2
				//half2 nor_uv_2 = i.logicPos.yx / _NorTileSize.z;
				//nor_uv_2 += _Time.x.xx * 0.05f  * half2(-1, -1) * _NorSpeed.z;
				//half3 nor_2 = UnpackNormal(tex2D(_NormalTex, nor_uv_2));

				////normal 3
				//half2 nor_uv_3 = i.logicPos.yx / _NorTileSize.w;
				//nor_uv_3 += _Time.x.xx * 0.05f  * half2(-1, 1) * _NorSpeed.w;
				//half3 nor_3 = UnpackNormal(tex2D(_NormalTex, nor_uv_3));

				//normal mix
				half3 nor = normalize(nor_0 + nor_1 ).xzy;	//主要把方向大致朝向改为正Y

				//posWorldNormal			
				half4 flowMap = tex2D (_FlowMap, i.posWorld.rg / _NorTileSize.w);
				flowMap.r = flowMap.r * 2.0f - 1.011765;
				flowMap.g = flowMap.g * 2.0f - 1.003922;
				float phase1 = _FlowMapOffset.x;
				float phase2 = _FlowMapOffset.y;
				float2 uvNoise_1 = -flowMap.rg * phase1;
				float2 uvNoise_2 = -flowMap.rg * phase2;

				float2 vertexTransformUV = i.posWorld.rg / _NorTileSize.z;
	
				half4 t1B = tex2D(_NormalTex, vertexTransformUV + uvNoise_1);
				half4 t2B = tex2D(_NormalTex, vertexTransformUV + uvNoise_2);
				half blend = abs(_PhaseLength - _FlowMapOffset.z) / _PhaseLength;
				blend = max(0, blend);

				half4 finalB = lerp(t1B, t2B, blend);
				half3 waveNormal = UnpackNormal(finalB);
				//

				//normal
				float3 normal = lerp(nor, waveNormal.xzy, _Worldspacetiling);// * (1.0 - _Tiling);
				normal = lerp(i.normalDir.rbg, normal, _NormalStrength);
			
				//phone params
				half3 lightDir = normalize(-_LightingLogicDir.xyz);	//需要用逻辑方向
				half3 viewDir = normalize((half3(_ScreenCentreLogicPos, 0) + _CameraLogicOriginOffect.xyz) - half3(i.logicPos.xy, 0));	//需要用逻辑相机位置
				half3 refLight = normalize(reflect(-viewDir, normal));
				//
				
				// Lambert
				float NdotL = dot(normal , lightDir) * 0.5 + 0.5;	
				NdotL = pow(NdotL, _NdotLScale);      
				//

				// main uv
				half2 main_uv = i.logicPos.yx / _MainTileSize;
				//refraction
				main_uv += (normal.xz * _Refraction * _NormalScale);
				
				// sample the texture
				half4 col = tex2D(_MainTex, main_uv);
				//phone specular
				half RDotL = max(0.0, dot(refLight, lightDir));
				half specular = pow(RDotL, _Glossiness * 128) * _SpecularFactor;
				fixed4 reflectCol = tex2D(_refractionTex, nor_uv_0); 
				fixed3 diffuseCol = NdotL * col.rgb * _Color.rgb;
				col.rgb = diffuseCol + specular + reflectCol.rgb * 0.1;

				return col;
				//return float4(i.logicPos.xy * 0.1, 0, 1);
				//return float4(reflectCol.rgb, 1);
			}

			ENDHLSL
		}
	}
}
