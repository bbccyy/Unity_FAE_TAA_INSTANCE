// - 熔岩瀑布 透明材质，两层贴图，另加一张控制Alpha透明的贴图

Shader "Babeitime/Character/falls"
{
Properties {
	//基础贴图
	_MainTex ("Base layer (RGB)", 2D) = "white" {}
	//细节贴图
	_DetailTex ("2nd layer (RGB)", 2D) = "white" {}
	//控制Alpha透明的贴图
	_AlphaTex ("Alpha (A)", 2D) = "white" {}
	//基础贴图的X轴速度
	_ScrollX ("Base layer Scroll speed X", Float) = 0.0
	//基础贴图的Y轴速度
	_ScrollY ("Base layer Scroll speed Y", Float) = 0.25
	//细节贴图的X轴速度
	_Scroll2X ("2nd layer Scroll speed X", Float) = 0.0
	//细节贴图的Y轴速度
	_Scroll2Y ("2nd layer Scroll speed Y", Float) = 0.35
	//基础贴图的振幅和频率
	_SineAmplX ("Base layer sine amplitude X",Float) = 0.0
	_SineAmplY ("Base layer sine amplitude Y",Float) = 0.0
	_SineFreqX ("Base layer sine freq X",Float) = 0
	_SineFreqY ("Base layer sine freq Y",Float) = 0
	//细节贴图的振幅和频率
	_SineAmplX2 ("2nd layer sine amplitude X",Float) = 0.0 
	_SineAmplY2 ("2nd layer sine amplitude Y",Float) = 0.0
	_SineFreqX2 ("2nd layer sine freq X",Float) = 0 
	_SineFreqY2 ("2nd layer sine freq Y",Float) = 0
	//倍增基数
	_MultiplierBase ("Base Layer Multiplier", Float) = 1.5
	_Multiplier2nd ("2nd Layer Multiplier", Float) = 1.6
}

	
SubShader {
	//渲染队列为透明  忽略投影 渲染类型为透明
	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
	//Alpha混合  让源和目标颜色完全的通过
	Blend One One
	//两面显示 忽略灯光 不记录深度 雾为白色
	Cull Off Lighting Off ZWrite Off Fog { Color (0,0,0,0) }
	
	LOD 100
	
	
	
	CGINCLUDE
	//若不懂  请参考浅墨shader十
	#pragma shader_feature LIGHTMAP_OFF LIGHTMAP_ON
	//#pragma exclude_renderers molehill
	#include "UnityCG.cginc"
	sampler2D _MainTex;
	sampler2D _DetailTex;
	sampler2D _AlphaTex;
	
	float4 _MainTex_ST;
	float4 _DetailTex_ST;
	float4 _AlphaTex_ST;
		
	float _ScrollX;
	float _ScrollY;
	float _Scroll2X;
	float _Scroll2Y;
	float _MultiplierBase;
	float _Multiplier2nd;
	
	float _SineAmplX;
	float _SineAmplY;
	float _SineFreqX;
	float _SineFreqY;

	float _SineAmplX2;
	float _SineAmplY2;
	float _SineFreqX2;
	float _SineFreqY2;
	
	struct v2f {
		float4 pos : SV_POSITION;
		float4 uv : TEXCOORD0;
	};

	
	v2f vert (appdata_full v)
	{
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv.xy = TRANSFORM_TEX(v.texcoord.xy,_MainTex) + frac(float2(_ScrollX, _ScrollY) * _Time);
		o.uv.zw = TRANSFORM_TEX(v.texcoord.xy,_DetailTex) + frac(float2(_Scroll2X, _Scroll2Y) * _Time);
		
		o.uv.x += sin(_Time * _SineFreqX) * _SineAmplX;
		o.uv.y += sin(_Time * _SineFreqY) * _SineAmplY;
		
		o.uv.z += sin(_Time * _SineFreqX2) * _SineAmplX2;
		o.uv.w += sin(_Time * _SineFreqY2) * _SineAmplY2;
		
		return o;
	}
	ENDCG


	Pass {
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		//计算精度
		#pragma fragmentoption ARB_precision_hint_fastest		
		fixed4 frag (v2f i) : COLOR
		{
			fixed4 o;
			fixed4 tex = tex2D (_MainTex, i.uv.xy);
			fixed4 alpha = tex2D (_AlphaTex, i.uv.xy);
			fixed4 tex2 = tex2D (_DetailTex, i.uv.zw);
			fixed4 alpha2 = tex2D (_AlphaTex, i.uv.zw);
			o = lerp(tex * alpha.a * _MultiplierBase, tex2 * alpha2.a  * _Multiplier2nd, alpha2.a * alpha2.r);
			
			return o;
		}
		ENDCG 
	}	
}
}