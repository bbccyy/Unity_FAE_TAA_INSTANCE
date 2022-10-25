// Copyright 2017-2018 BabelTime, Inc. All Rights Reserved.
// Author           : MengZhijiang
// Created          : 01-26-2018
//
// 处理进度条血条的高效分割显示
//

Shader "sg3/UI/sg3_UI_Lifebar"
{
	Properties
	{
		_Color("Tint", Color) = (1, 1, 1, 1)		//Image颜色
		_MainTex ("Main Tex (RGB)",  2D) = "white" { }
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
				float3 texcoord : TEXCOORD0;
			};

			sampler2D _MainTex;
			half4 _Color = half4(1, 1, 1, 1);
			half4 _BloodColor, _ShieldColor, _FallColor, _EmptyColor, _SectionSplitColor;
			float _BloodValue = 100, _ShieldValue = 30, _FallValue = 20;
			float _SectionCount = 10, _SectionWidth = 10, _SectionSplitWidth = 2;
			float _ValidWidth = 200;

			v2f vert(appdata v)
			{
				v2f Out;
				Out.pos = UnityObjectToClipPos(v.vertex);
				Out.texcoord.xy = v.texcoord;
				Out.texcoord.z = v.texcoord.x * _ValidWidth;
				return Out;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				half4 col = tex2D(_MainTex, i.texcoord.xy) * _Color;
				float pos = i.texcoord.z;

				//空条
				if (_BloodValue + _ShieldValue + _FallValue < pos)
				{
					return _EmptyColor * col;
				}
				
				//分隔条
				float splitPos = pos;
				for ( ; splitPos > 0; )
				{
					splitPos -= _SectionWidth;
					if (splitPos < 0.01)
					{
						break;
					}					
					if (splitPos < _SectionSplitWidth + 0.01)
					{
						return _SectionSplitColor * col;
					}
					splitPos -= _SectionSplitWidth;
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
