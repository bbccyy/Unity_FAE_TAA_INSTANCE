// ***********************************************************************
// Copyright 2017-2018 BabelTime, Inc. All Rights Reserved.
//
// Author           : MengZhijiang
// Created          : 03-13-2018
// ***********************************************************************
// 定义SLG地图通用不透明菱形块的渲染
//
// Last Modified By		 : MengZhijiang
// Last Modified On		 : 03-13-2018
// Last Modified Content : 提供核心思想算法，具体优化过程需要美术和TA共同完成
//
// ***********************************************************************

Shader "sg3/slg/block"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
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

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float4 color : COLOR;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv + v.color.zw;
#if !UNITY_UV_STARTS_AT_TOP
				o.uv.y = 1.0 - o.uv.y;
#endif
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				// sample the texture
				half4 col = tex2D(_MainTex, i.uv);

				//return float4(i.uv, 0, 1);
				return col;
			}

			ENDHLSL
		}
	}
}
