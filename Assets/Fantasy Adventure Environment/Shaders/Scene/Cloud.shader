Shader "Babeitime/Scene/Cloud"
{   
	Properties {
		_MainTex ("Base Layer (RGBA)", 2D) = "white" {}
		_DetailTex ("2nd Layer (RGBA)", 2D) = "white" {}
		_ScrollX ("Base layer Scroll Speed", Float) = 1.0
		_Scroll2X ("2nd layer Scroll Speed", Float) = 1.0
		_Scroll21 ("Base layer Scroll Speed 2", Float) = 1.0
		_Scroll22 ("2nd layer Scroll Speed 2", Float) = 1.0
		_Multiplier ("Layer Multiplier", Float) = 1
		_Multiplier2 ("Layer Multiplier", Float) = 1
		_ClrToMulti ("Color to multi (RGBA)", Color) = (1, 1, 1, 1)
		_ClrToMulti2 ("Color to multi (RGBA)", Color) = (1, 1, 1, 1)
	}
	SubShader {
		Tags {"RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Transparent"}
		
		Pass { 
			Tags { "LightMode"="UniversalForward" }
			Blend SrcAlpha OneMinusSrcAlpha
			
			HLSLPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
           
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			
			sampler2D _MainTex;
			sampler2D _DetailTex;
			float4 _MainTex_ST;
			float4 _DetailTex_ST;
			float _ScrollX;
			float _Scroll2X;
			float _Scroll21;
			float _Scroll22;
			float _Multiplier;
			float _Multiplier2;
			float4 _ClrToMulti;
			float4 _ClrToMulti2;
			
			struct a2v {
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float4 uv2 : TEXCOORD1;
			};
			
			v2f vert (a2v v) {
				v2f o;
				//将顶点坐标从模型空间转换到裁剪空间
				o.pos = TransformObjectToHClip(v.vertex);
				////将纹理坐标映射到顶点上以及zw偏移,并用ScrollX对x轴坐标进行偏移
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex) + frac(float2(_ScrollX, 0.0) * _Time.y);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _DetailTex) + frac(float2(_Scroll2X, 0.0) * _Time.y);
				o.uv2.xy = TRANSFORM_TEX(v.texcoord, _MainTex) + frac(float2(_Scroll21, 0.0) * _Time.y);
				o.uv2.zw = TRANSFORM_TEX(v.texcoord, _DetailTex) + frac(float2(_Scroll22, 0.0) * _Time.y);
				
				return o;
			}
			
			half4 frag (v2f i) : SV_Target {
				//纹理采样
				half4 firstLayer = tex2D(_MainTex, i.uv.xy) * _ClrToMulti;
				half4 secondLayer = tex2D(_DetailTex, i.uv.zw) * _ClrToMulti2;
				//纹理混合
				half4 c = lerp(firstLayer, secondLayer, secondLayer.a);
				c.rgb *= _Multiplier;

				firstLayer = tex2D(_MainTex, i.uv2.xy);
				secondLayer = tex2D(_DetailTex, i.uv2.zw);
				half4 c2 = lerp(firstLayer, secondLayer, secondLayer.a);
				c2 *= _Multiplier2;

				c = c * (1 - c2.a) + c2 * c2.a;

				return c;
			}
			
			ENDHLSL
		}
	}
	FallBack "Babeltime/Diffuse"
}