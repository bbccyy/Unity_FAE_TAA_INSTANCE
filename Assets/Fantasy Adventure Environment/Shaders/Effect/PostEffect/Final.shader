Shader "Hidden/PostEffect/Final"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}

	HLSLINCLUDE

		#pragma shader_feature __ HDR_RGB111110
		#pragma shader_feature __ POST_EFFECT_HIGH_QUALITY
		#pragma shader_feature __ BLOOM 
		#pragma shader_feature __ VIGNETTE
		#pragma shader_feature __ TONE_MAPPING

		#include "UnityCG.cginc"
		#include "PE_Common.cginc"

		//下面定义所有各自效果需要的参数
		//包含各自效果需要的头文件
		//最好每个效果的最后处理过程都封装在各个效果的头文件内部


		//Main-RenderTexture
		//
		sampler2D _MainTex;
		float2 _MainTex_TexelSize;
		float2 _ToneMappingSettings;


		//Bloom
		//
		#if BLOOM
			sampler2D _BloomTex;
			float2 _BloomTex_TexelSize;
			float2 _Bloom_Settings;
		#endif


		#if VIGNETTE
			sampler2D _VignetteTex;
		#endif

		// -----------------------------------------------------------------------------
		struct FinalVertexInput
		{
			float4 vertex : POSITION;
			float4 texcoord : TEXCOORD0;
		};

		struct FinalVertexOutput
		{
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
		};

		FinalVertexOutput FinalVertex(FinalVertexInput v)
		{
			FinalVertexOutput o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv = v.texcoord.xy;

//http://jira.babeltime.com/browse/PROJSG-587?filter=12414
//https://blog.csdn.net/WPAPA/article/details/72721185
//Unity 在内部做了封装
//#if SHADER_API_MOBILE
//	#if !UNITY_UV_STARTS_AT_TOP
//			o.uv.y = 1.0 - o.uv.y;
//	#endif
//#else
//	#if UNITY_UV_STARTS_AT_TOP
//			if (_MainTex_TexelSize.y < 0.0)
//				o.uv.y = 1.0 - o.uv.y;
//	#endif
//#endif
			return o;
		}


		half4 Frag(FinalVertexOutput i) : SV_Target
		{
			half4 color = tex2D(_MainTex, i.uv);

			//Before Tone Mapping
			//Bloom
			//
			#if BLOOM
			{
				half3 bloom = UpsampleFilter(_BloomTex, i.uv, _BloomTex_TexelSize.xy, _Bloom_Settings.x) * _Bloom_Settings.y;
				color.xyz += LinearToGammaSpace(bloom);
			}
			#endif

			//Do Tone Mapping
			#if TONE_MAPPING
			{
				color.xyz = 1.0 - exp(_ToneMappingSettings.x *  color.xyz);
				color.xyz = pow(color.xyz, 0.001 + _ToneMappingSettings.y);
			}
			#endif	

			//After Tone Mapping
			//
			
			//
			#if VIGNETTE
			{
				half4 brokenColor = tex2D(_VignetteTex, i.uv);
				color.xyz = lerp(saturate(color.xyz), brokenColor.xyz, brokenColor.a);
			}
			#endif

			return color;
		}

	ENDHLSL

	SubShader
	{
		Pass
		{
			HLSLPROGRAM

				#pragma vertex FinalVertex
				#pragma fragment Frag

			ENDHLSL
		}
	}
}
