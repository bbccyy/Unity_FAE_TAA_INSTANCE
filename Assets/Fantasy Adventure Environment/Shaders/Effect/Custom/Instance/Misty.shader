Shader "sg3/Misty" 
{
	Properties 
	{
		// 中心点Alpha值
		_CenterAlpha("CenterAlpha", Range(0, 1)) = 0.98
		// 第一环(0, _Distance0)
		_Distance0("Distance0", Range(0, 1)) = 0.5
		_Alpha0("Alpha0", Range(0, 1)) = 0.8

		// 第二环(_Distance0, _Distance1)
		_Distance1("Distance1", Range(0, 1)) = 0.7
		_Alpha1("Alpha1", Range(0, 1)) = 0.6
	}
	SubShader 
	{
		Tags{ "RenderPipeline"="UniversalPipeline" "Queue" = "Transparent" "RenderType" = "Transparent" }
		
		Pass
	{
		Blend SrcAlpha OneMinusSrcAlpha
		HLSLPROGRAM
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"

	struct appdata
	{
		float4 vertex : POSITION;
		float4 color : COLOR;
	};

	struct v2f
	{
		float4 vertex : SV_POSITION;
		float4 color : COLOR;
	};

	float _CenterAlpha;
	float _Distance0;
	float _Alpha0;
	float _Distance1;
	float _Alpha1;
	float _Distance2;
	float _Alpha2;

	v2f vert(appdata v)
	{
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.color = v.color;

		return o;
	}

	fixed4 frag(v2f i) : SV_Target
	{
		// 第一环区间
		if (i.color.w < _Distance0)
		{
			float d = i.color.w / _Distance0;
			float cD = cos(radians(d * 90));
			float s = _Alpha0 + cD * (_CenterAlpha - _Alpha0);
			return float4(1, 1, 1, s * i.color.x);
		}
		// 第二环区间
		else if (i.color.w < _Distance1)
		{
			float d = (i.color.w - _Distance0) / (_Distance1 - _Distance0);
			float cD = cos(radians(d * 90));
			float s = _Alpha1 + cD * (_Alpha0 - _Alpha1);
			return float4(1, 1, 1, s * i.color.x);
		}
		// 第四环区间
		else
		{
			float d = (i.color.w - _Distance1) / (1 - _Distance1);
			float sD = sin(radians(d * 90));
			float s = _Alpha1 - sD * _Alpha1;
			return float4(1, 1, 1, s * i.color.x);
		}

		return i.color;
	}
		ENDHLSL
	}
	}
}
