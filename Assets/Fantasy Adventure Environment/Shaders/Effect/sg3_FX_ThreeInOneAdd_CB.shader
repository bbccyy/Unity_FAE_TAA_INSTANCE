Shader "sg3/Fx/ThreeInOne_Add_CB"
{
	Properties
	{
		_MainTex ("Main Map",2D) = "white"{}
		_MaskTex ("Mask Map",2D) = "white"{}
		_MaskAllTex ("MaskAll Map",2D) = "white"{}
		_NoiseTex ("Nosie Map",2D) = "white"{}
		_TintColor ("Tint Color",Color) = (1,1,1,1)
		_ColorPower ("Color Power",Range(1,4)) = 1
		_USpeed ("U Direction Speed",Float) = 0
		_VSpeed ("V Direction Speed",Float) = 0
		[Toggle] _TurbulenceAlpha ("Turbelunce Alpha",Float) = 0
		_Turbulence ("Turbelunce Intensity",Range(0,1)) = 0
		_UDistort ("U Turbelunce Speed",Float) = 0
		_VDistort ("V Turbelunce Speed",Float) = 0
		_Cutout ("Cut Out",Range(0,1)) = 0
		_EdgeColor ("Edge Color",Color) = (1,1,1,1)
		_Edge ("Edge Width",Range(0,1)) = 0
		_SoftEdge ("Soft Edge",Range(0,0.5)) = 0
	}
	SubShader
	{
		Tags{"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline"}

		Blend SrcAlpha One
		//Cull Off 
		Lighting Off 
		ZWrite Off

		Pass
		{
			Tags { "LightMode"="UniversalForward"}

			HLSLPROGRAM
			#pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
			#pragma vertex vert
			#pragma fragment frag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			TEXTURE2D(_MainTex);		SAMPLER(sampler_MainTex);
			TEXTURE2D(_MaskTex);		SAMPLER(sampler_MaskTex);
			TEXTURE2D(_NoiseTex);		SAMPLER(sampler_NoiseTex);
			TEXTURE2D(_MaskAllTex);		SAMPLER(sampler_MaskAllTex);
			CBUFFER_START(UnityPerMaterial)
			float4 _MainTex_ST,_MaskTex_ST,_NoiseTex_ST,_MaskAllTex_ST;
			float _Cutout,_AlphaBoost,_Edge,_SoftEdge,_Turbulence,_USpeed,_VSpeed,_TurbulenceAlpha,
				  _VDistort,_UDistort,_ColorPower;
			half3 _EdgeColor;
			half4 _TintColor;
			CBUFFER_END
			struct a2v
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				half4 color : COLOR0;		
			};

			struct v2f
			{
   				float4 pos : SV_POSITION;
   				float4 uv : TEXCOORD0;
				float2 uvNoise : TEXCOORD1;
				float2 uvMaskAll : TEXCOORD2;
				half4 vertexColor : COLOR0;
   			};

   			v2f vert(a2v v)
   			{
   				v2f o;
   				o.pos = TransformObjectToHClip(v.vertex.xyz);
   				o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
				o.uv.x += _Time.y*_USpeed;
				o.uv.y += _Time.y*_VSpeed;
				o.uv.zw = TRANSFORM_TEX(v.texcoord,_MaskTex);
				o.uv.z += _Time.y*_USpeed;
				o.uv.w += _Time.y*_VSpeed;
				o.uvNoise = TRANSFORM_TEX(v.texcoord,_NoiseTex);
				o.uvNoise.x += _Time.y*_UDistort;
				o.uvNoise.y += _Time.y*_VDistort;
				o.vertexColor = v.color;

				o.uvMaskAll = TRANSFORM_TEX(v.texcoord,_MaskAllTex);

   				return o;
   			}

   			half4 frag (v2f i ) : SV_Target
   			{
				float2 uvDistortMain = SAMPLE_TEXTURE2D(_NoiseTex,sampler_NoiseTex,i.uvNoise).rg * _Turbulence + i.uv.xy - _Turbulence*0.5;
				float2 uvDistortMask = SAMPLE_TEXTURE2D(_NoiseTex,sampler_NoiseTex,i.uvNoise).rg * _Turbulence + i.uv.zw - _Turbulence*0.5;

				half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uvDistortMain);
				half mask = saturate(SAMPLE_TEXTURE2D(_MaskTex,sampler_MaskTex,lerp(i.uv.zw,uvDistortMask,_TurbulenceAlpha)).r + 0.001);
				half dissolve = smoothstep(0,_SoftEdge,mask-(1-i.vertexColor.a+_Cutout));
				half edge = smoothstep(_Edge,0,mask-(1-i.vertexColor.a+_Cutout));

				half3 finalCol = lerp(col.rgb * i.vertexColor.rgb * _TintColor.rgb * _ColorPower, _EdgeColor.rgb , edge);

				half3 maskAll = SAMPLE_TEXTURE2D(_MaskAllTex,sampler_MaskAllTex,i.uvMaskAll).rgb;

				return half4 (finalCol, dissolve * col.a * _TintColor.a * maskAll.r);
   			}
   			ENDHLSL
   		}
   	}

	SubShader
	{
		Tags{"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}

		Blend SrcAlpha One
		Lighting Off 
		ZWrite Off

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			sampler2D _MainTex,_MaskTex,_NoiseTex,_MaskAllTex;
			float4 _MainTex_ST,_MaskTex_ST,_NoiseTex_ST,_MaskAllTex_ST;
			float _Cutout,_AlphaBoost,_Edge,_SoftEdge,_Turbulence,_USpeed,_VSpeed,_TurbulenceAlpha,
				  _VDistort,_UDistort,_ColorPower;
			fixed3 _EdgeColor;
			fixed4 _TintColor;

			struct a2v
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				fixed4 color : COLOR0;		
			};

			struct v2f
			{
   				float4 pos : SV_POSITION;
   				float4 uv : TEXCOORD0;
				float2 uvNoise : TEXCOORD1;
				float2 uvMaskAll : TEXCOORD2;
				fixed4 vertexColor : COLOR0;
   			};

   			v2f vert(a2v v)
   			{
   				v2f o;
   				o.pos = UnityObjectToClipPos(v.vertex);
   				o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
				o.uv.x += _Time.y*_USpeed;
				o.uv.y += _Time.y*_VSpeed;
				o.uv.zw = TRANSFORM_TEX(v.texcoord,_MaskTex);
				o.uv.z += _Time.y*_USpeed;
				o.uv.w += _Time.y*_VSpeed;
				o.uvNoise = TRANSFORM_TEX(v.texcoord,_NoiseTex);
				o.uvNoise.x += _Time.y*_UDistort;
				o.uvNoise.y += _Time.y*_VDistort;
				o.vertexColor = v.color;

				o.uvMaskAll = TRANSFORM_TEX(v.texcoord,_MaskAllTex);

   				return o;
   			}

   			fixed4 frag (v2f i ) : SV_Target
   			{
				float2 uvDistortMain = tex2D(_NoiseTex,i.uvNoise).rg * _Turbulence + i.uv.xy - _Turbulence*0.5;
				float2 uvDistortMask = tex2D(_NoiseTex,i.uvNoise).rg * _Turbulence + i.uv.zw - _Turbulence*0.5;

				fixed4 col = tex2D(_MainTex,uvDistortMain);
				fixed mask = saturate(tex2D(_MaskTex,lerp(i.uv.zw,uvDistortMask,_TurbulenceAlpha)).r + 0.001);
				fixed dissolve = smoothstep(0,_SoftEdge,mask-(1-i.vertexColor.a+_Cutout));
				fixed edge = smoothstep(_Edge,0,mask-(1-i.vertexColor.a+_Cutout));

				fixed3 finalCol = lerp(col.rgb * i.vertexColor.rgb * _TintColor.rgb * _ColorPower, _EdgeColor , edge);

				fixed3 maskAll = tex2D(_MaskAllTex,i.uvMaskAll);

				return fixed4 (finalCol, dissolve * col.a * _TintColor.a * maskAll.r);
   			}
   			ENDCG
   		}
   	}
 	Fallback Off
 }
