Shader "Babeitime/Scene/Cloud movement"
{
	Properties
	{
		[MaterialToggle] _addGradient("Add Gradient", Float) = 0
		[Toggle(ADDCLOUD)] _addCloud("Add Cloud", Float) = 0

	    [Header(Cloud Settings)]
		_Cloud("Cloud Texture", 2D) = "black" {}
		_CloudCutoff("Cloud Cutoff",  Range(0, 3)) = 0.08
		_CloudSpeed("Cloud Move Speed",  Range(-10, 10)) = 0.3
		_CloudScale("Cloud Scale",  Range(0, 10)) = 0.3

		[Space()]
		_CloudNoise("Cloud Noise", 2D) = "black" {}
		_CloudNoiseScale("Cloud Noise Scale",  Range(0, 1)) = 0.2
		_CloudNoiseSpeed("Cloud Noise Speed",  Range(-1, 1)) = 0.1

		[Space()]
		_DistortTex("Distort Tex", 2D) = "black" {}
		_DistortScale("Distort Noise Scale",  Range(0, 1)) = 0.06
		_DistortionSpeed("Distortion Speed",  Range(-1, 1)) = 0.1

		[Space()]
		_Fuzziness("Cloud Fuzziness",  Range(-5, 5)) = 0.04
		_FuzzinessSec("Cloud Fuzziness Sec",  Range(-5, 5)) = 0.04

		[Header(Cloud Color Settings)]
		_CloudColorDayMain("Cloud Day Color Main", Color) = (0.0,0.2,0.1,1)
		_CloudColorDaySec("Clouds Day Color Sec", Color) = (0.6,0.7,0.6,1)

		[Space()]
		_CloudBrightnessDay("Cloud Brightness Day",  Range(0, 2)) = 1
		
		[Header(Day Sky Settings)]
		_DayTopColor("Day Top Color", Color) = (0.4,1,1,1)
		_DayBottomColor("Day Bottom Color", Color) = (0,0.8,1,1)

	}
		SubShader
		{
			Tags { "RenderType" = "Transparent" "Queue"="Transparent"  }
			LOD 100
            Blend SrcAlpha OneMinusSrcAlpha
            
			Pass
			{
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#include "UnityCG.cginc"

				#pragma shader_feature MIRROR
				#pragma shader_feature ADDCLOUD

				struct appdata
				{
					float4 vertex : POSITION;
					float3 uv : TEXCOORD0;
				};

				struct v2f
				{
					float3 uv : TEXCOORD0;
					float4 vertex : SV_POSITION;
					float3 worldPos : TEXCOORD1;
				};

				void scaleTex() {
				
				}

				//debug
				float _addGradient, _addCloud;

				float4 _DayTopColor, _DayBottomColor;
				float4 _CloudColorDayMain, _CloudColorDaySec;
				float _MidLightIntensity, _CloudBrightnessDay, _Fuzziness, _FuzzinessSec, _DistortionSpeed, _CloudNoiseSpeed, _CloudNoiseScale, _DistortScale, _CloudCutoff, _CloudSpeed, _CloudScale;
				sampler2D _CloudNoise, _Cloud, _DistortTex;

				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = v.uv;
					o.worldPos = mul(unity_ObjectToWorld, v.vertex);
					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{

//				float2 skyuv = (i.worldPos.xz) / (clamp(i.worldPos.y, 0, 10000));
                float2 skyuv = i.uv;
//                return float4(i.uv.xy,0,1);
				//cloud
				float cloud = tex2D(_Cloud, (skyuv + (_Time.x * _CloudSpeed)) * _CloudScale);
//				return float4(cloud,0,0,1);
				float distort = tex2D(_DistortTex, (skyuv + (_Time.x * _DistortionSpeed)) * _DistortScale);
				float noise = tex2D(_CloudNoise, ((skyuv + distort) - (_Time.x * _CloudNoiseSpeed)) * _CloudNoiseScale);
				float finalNoise = saturate(noise) * 3 * saturate(i.worldPos.y);
				cloud = saturate(smoothstep(_CloudCutoff * cloud, _CloudCutoff * cloud + _Fuzziness, finalNoise));
				float cloudSec = saturate(smoothstep(_CloudCutoff * cloud, _CloudCutoff * cloud + _Fuzziness + _FuzzinessSec, finalNoise));
				
				float3 cloudColoredDay = cloud *  _CloudColorDayMain * _CloudBrightnessDay;
				float3 cloudSecColoredDay = cloudSec * _CloudColorDaySec * _CloudBrightnessDay;
				cloudColoredDay += cloudSecColoredDay;

				float3 finalcloud = cloudColoredDay;

				//gradient day sky
				#if MIRROR
					float ypos = saturate(abs(i.uv.y));
				#else
					float ypos = saturate(i.uv.y);
				#endif
				float3 gradientDay = lerp(_DayBottomColor, _DayTopColor, ypos);
				float3 skyGradients = gradientDay;

				//combine all effects
				float3 combined = skyGradients * _addGradient 
					+ finalcloud * _addCloud;

			    return float4(combined,cloud);
		    }
		    ENDCG
	    }
	}
}
