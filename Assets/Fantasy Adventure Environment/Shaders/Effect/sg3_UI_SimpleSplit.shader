// Copyright 2017-2018 BabelTime, Inc. All Rights Reserved.
// Author           : MengZhijiang
// Created          : 01-26-2018
//
// 处理进度条血条的高效分割显示
//

Shader "sg3/UI/sg3_UI_SimpleSplit"
{
	Properties
	{
		_Color("颜色(_Color)", Color) = (1,1,1,1)	//分割条颜色
		_Width("宽度(_Width)", Float) = 0.025	//宽度
		_SplitCount("分段数(_SplitCount)", Float) = 5		//分段数量
		_ValidValue("有效值(_ValidValue)", Float) = 1	//宽度
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
				float2 texcoord : TEXCOORD0;
				float splitWidth : TEXCOORD1;
			};

			fixed4 _Color;
			float _SplitCount, _Width, _ValidValue;

			v2f vert(appdata v)
			{
				v2f OUT;
				OUT.pos = UnityObjectToClipPos(v.vertex);
				OUT.texcoord = v.texcoord;
				OUT.splitWidth = 1 / _SplitCount;
				return OUT;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				half4 col = half4(0,0,0,0);
				float pos = i.texcoord.x + (_Width * 0.5);
				if (pos > i.splitWidth && pos < _ValidValue)
				{
					float near = fmod(pos, i.splitWidth);
					if (near <= _Width)
					{
						col = _Color;
					}
				}
				return col;
			}
			ENDCG
		}
	}
}
