Shader "sg3/Scene/Grass"
{
	Properties
	{
		_Color("Color", color) = (1, 1, 1, 1)
		_MainTex ("Texture", 2D) = "white" {}
		_MiddleX("MiddleX", range(-1, 1)) = 0
		_MiddleZ("MiddleZ", range(0, 1)) = 0.25
		_XPower("XPower", range(-1, 1)) = 0.25
		_ZPower("ZPower", range(-1, 1)) = 0.25
		_XSpeed("XSpeed", range(0, 5)) = 0.25
		_ZSpeed("ZSpeed", range(0, 5)) = 0.25
		_YParam("YParam", range(-2, 2)) = 1.0
		_CutOff("CutOff", range(0.01, 1.0)) = 0.1
	}
	SubShader
	{
		Tags {"RenderPipeline"="UniversalPipeline"  "Queue" = "AlphaTest" "RenderType"="TransparentCutout" "IgnoreProjector"="True"}
		LOD 200

		Pass
		{
			Tags{"LightMode" = "UniversalForward"}

//			Blend SrcAlpha OneMinusSrcAlpha
			cull off
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			#pragma exclude_renderers xboxone ps4 psp2 n3ds wiiu

			#include "UnityCG.cginc"
			//#include "Common.cginc"
			sampler2D _MainTex;
			float4 _MainTex_ST, _Color;
			float _MiddleX, _MiddleZ, _XPower, _ZPower, _XSpeed, _ZSpeed, _YParam, _CutOff;  

			struct appdata
			{
				float4 vertex : POSITION;
				float4 color  : COLOR;
				float2 uv : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 color  : COLOR;
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				UNITY_VERTEX_OUTPUT_STEREO
			};

			v2f vert (appdata v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				UNITY_SETUP_INSTANCE_ID(V);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(O);
				fixed swing = v.color.z * 3.14;
				float3 modPos;
				modPos.x = v.vertex.x + ((_MiddleX + sin(_Time.y * _XSpeed + swing) * _XPower) * v.color.w);
				modPos.z = v.vertex.z + ((_MiddleZ + sin(_Time.y * _ZSpeed + swing) * _ZPower) * v.color.w);
				float offsetX = modPos.x - v.vertex.x;
				float offsetZ = modPos.z - v.vertex.z;
				modPos.y = v.vertex.y - sqrt(offsetX * offsetX + offsetZ * offsetZ) * _YParam;
				o.vertex = UnityObjectToClipPos(float4(modPos, 1));
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.color = v.color;
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				col *= _Color;
				clip(col.w - _CutOff);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				//col.rgb = EncodeColor(col.rgb);
				return col;
			}
			ENDHLSL
		}
	}
	Fallback "Render Pipeline/Liteline/Lit"
}
