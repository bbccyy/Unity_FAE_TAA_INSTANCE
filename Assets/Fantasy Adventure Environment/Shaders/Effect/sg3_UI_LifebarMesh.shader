// Copyright 2017-2018 BabelTime, Inc. All Rights Reserved.
// Author           : MengZhijiang
// Created          : 01-26-2018
//
// 处理血条的高效显示
//

Shader "sg3/UI/sg3_UI_LifebarMesh"
{
	Properties
	{
		//_MainTex("Main Tex (RGB)",  2D) = "white" { }
	}
	SubShader
	{
		Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" "PreviewType" = "Plane" }

		Cull Off
		Lighting Off
		ZWrite Off
		ZTest LEqual
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
				float4 color	: COLOR;
			};

			struct v2f
			{
				float4 pos   : SV_POSITION;
				float2 texcoord : TEXCOORD0;
				float4 color	: COLOR;
			};

			sampler2D _Texture;
			float4 _BloodColor, _ShieldColor, _FallColor, _EmptyColor, _SectionSplitColor;
			float _Alpha = 1, _BloodValue = 0.5, _ShieldValue = 0.2, _FallValue = 0.15;

			v2f vert(appdata v)
			{
				v2f Out;
				Out.pos = UnityObjectToClipPos(v.vertex);
				Out.texcoord = v.texcoord;
				Out.color = v.color;
				return Out;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				half4 col = tex2D(_Texture, i.texcoord.xy) * i.color;
				col.a *= _Alpha;

				float pos = i.texcoord.x;

				//空条
				if (_BloodValue + _ShieldValue + _FallValue < pos)
				{
					return _EmptyColor * col;
				}

				//血条
				if (pos <= _BloodValue)
				{
					return _BloodColor * col;
				}

				//盾
				pos -= _BloodValue;
				if (pos <= _ShieldValue)
				{
					return _ShieldColor * col;
				}

				//回落条
				pos -= _ShieldValue;
				if (pos <= _FallValue)
				{
					return _FallColor * col;
				}

				return _EmptyColor * col;
			}
			ENDCG
		}
	}
}
