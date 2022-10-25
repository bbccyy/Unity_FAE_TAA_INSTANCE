Shader "sg3/wangzhaojun"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_MaskTex ("MaskTex", 2D) = "white" {}
		_NormalTex ("Normalmap", 2D) = "bump" {}
		_LightColor("LightColor", color) = (0.5, 0.5, 0.5, 1.0)
		_RimColor("RimColor", color) = (0.5, 0.5, 0.5, 1.0)
		_RimPower("RimPower", float) = 15.0
		_SpecPower("SpecPower", float) = 5.0
		_SpecMultiplier("SpecMultiplier", float) = 0.5
		_SpecColor("SpecColor", color) = (0.5, 0.5, 0.5, 1.0)
		_LightTex ("_LightTex", 2D) = "white" {}
		_RampMap ("RampMap", 2D) = "gray" {}
		_ShadowColor("ShadowColor", color) = (0.5, 0.5, 0.5, 1.0)
	}
	SubShader
	{
		Tags {"lightmode"="ForwardBase" "RenderType"="Opaque" "queue" = "Geometry" "ignoreprojector" = "true"}
		LOD 100

		Pass
		{
			tags{"lightmode" = "ShadowCaster"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"

			sampler2D _MainTex, _MaskTex, _NormalTex, _LightTex, _RampMap;
			float4 _MainTex_ST, _LightColor, _RimColor, _SpecColor, _ShadowColor;
			float _RimPower, _SpecPower, _SpecMultiplier;

			struct v2f
			{
				float4 pos : SV_POSITION;
				half3 tspace0 : TANGENT;
				half3 tspace1 : Normal;
				half3 tspace2 : COLOR;
				float2 uv : TEXCOORD0;
				float3 worldPos : TEXCOORD1;

				UNITY_FOG_COORDS(2)
				SHADOW_COORDS(3)
			};
			
			v2f vert (appdata_tan v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				half3 wNormal = UnityObjectToWorldNormal(v.normal);
				half3 wTangent = UnityObjectToWorldDir(v.tangent.xyz);
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 wBitangent = cross(wNormal, wTangent) * tangentSign;
				o.tspace0 = half3(wTangent.x, wBitangent.x, wNormal.x);
				o.tspace1 = half3(wTangent.y, wBitangent.y, wNormal.y);
				o.tspace2 = half3(wTangent.z, wBitangent.z, wNormal.z);

				UNITY_TRANSFER_FOG(o,o.pos);
				TRANSFER_SHADOW(o)
				return o;
			}
			
			fixed4 frag (v2f v) : SV_Target
			{
				// sample the texture
				fixed4 mainCol = tex2D(_MainTex, v.uv);
				fixed4 maskCol = tex2D(_MaskTex, v.uv);
				float3 tNormal = normalize(UnpackNormal(tex2D(_NormalTex, v.uv)));
				half3 worldNormal;
				worldNormal.x = dot(v.tspace0, tNormal);
				worldNormal.y = dot(v.tspace1, tNormal);
				worldNormal.z = dot(v.tspace2, tNormal);

				float3 matnormal = normalize(mul((float3x3)UNITY_MATRIX_V, worldNormal));
				float2 matCapUV = matnormal.xy * 0.5 + 0.5;
				fixed3 diffuseCol = (tex2D(_LightTex, matCapUV) * 1.2).xyz * _LightColor.xyz * maskCol.r + mainCol;
				fixed3 albedo = lerp(diffuseCol, mainCol, maskCol.y);
				
				float3 viewDir = normalize(UnityWorldSpaceViewDir(v.worldPos));

				float NdotL = dot(worldNormal, _WorldSpaceLightPos0.xyz) * 0.49 + 0.49;
				float ramColFactor = tex2D(_RampMap, float2(NdotL, 0.5)).r;

				float3 refLight = normalize(reflect(-viewDir, worldNormal)); 
				float specFactor = max(0.0, dot(refLight, _WorldSpaceLightPos0.xyz) * 0.5 + 0.5);

				float shadow = SHADOW_ATTENUATION(v);
				float3 specColor = _SpecColor* (pow(specFactor, _SpecPower) * maskCol.r) * _SpecMultiplier * shadow* 2.0 * albedo;
				float3 diffSpecCol= specColor + albedo;

				float3 rimColor = (saturate(pow(NdotL * saturate(1.0 - dot(viewDir, worldNormal)), _RimPower) * (1.0 + _RimPower)) * _RimColor).rgb;
				float3 finalCol = lerp((diffSpecCol * diffSpecCol), diffSpecCol, ramColFactor) + rimColor;
				finalCol = lerp(albedo * _ShadowColor, finalCol, shadow);
				// apply fog
				UNITY_APPLY_FOG(v.fogCoord, finalCol);
				return fixed4(finalCol , 1.0);
			}
			ENDCG
		}
	}
	Fallback"Diffuse"
}
