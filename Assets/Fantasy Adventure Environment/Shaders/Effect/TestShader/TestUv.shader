// Copyright 2017-2018 BabelTime, Inc. All Rights Reserved.
// Author           : MengZhijiang
// Created          : 01-26-2018
//
// 处理进度条血条的高效分割显示
//

Shader "sg3/Test/Uv"
{
	Properties
	{
		
	}
	SubShader
	{
		Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" "PreviewType" = "Plane" "CanUseSpriteAtlas" = "True" }

		Cull Off
		Lighting Off
		ZWrite Off
		ZTest[unity_GUIZTestMode]
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#include "UnityCG.cginc"
			#include "UnityUI.cginc"

			struct appdata
			{
				float4 vertex   : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos   : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			v2f vert(appdata v)
			{
				v2f Out;
				Out.pos = UnityObjectToClipPos(v.vertex);
				Out.uv = v.texcoord;
				return Out;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				return fixed4(pow(i.uv, 3), 0, 1);
			}
			ENDCG
		}
	}
}
