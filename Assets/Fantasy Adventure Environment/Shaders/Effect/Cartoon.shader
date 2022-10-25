// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "sg3/Fx/Cartoon"
{
	Properties
	{
		[HDR]_LightColor("Light Color",color) = (1,1,1,1)
		_LightProperty("xyz:Light Position w:intentsity",vector) = (0,1,0,1)
		_MainTex("Texture", 2D) = "white" {}
		_Step("Step,",float) = 3.0
	}
		SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 100
		cull off

		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			struct a2v
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal :NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 wPos : TEXCOORD1;
				float3 normal : TEXCOORD2;
			};

			sampler2D _MainTex;
			
			float4 _MainTex_ST;
			half4 _AmbintColor;			
			half4 _LightColor;
			float4 _LightProperty;
			float _Step;
			v2f vert(a2v v)
			{
				v2f o;
				VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
                o.pos = vertexInput.positionCS;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.wPos = mul(unity_ObjectToWorld,v.vertex);
				VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(v.normal);
                o.normal = vertexNormalInput.normalWS;
				return o;
			}

			half4 frag(v2f i) : SV_Target
			{
				float3 lightDir = normalize(_LightProperty.xyz - i.wPos);
				float atten = max(0,dot(lightDir,i.normal));
				atten = ((int)(atten * _Step))/ _Step;
				atten = atten * _LightProperty.w;
				half4 tex = tex2D(_MainTex, i.uv);
				half4 col = tex * _LightColor * atten;
				col.rgb += tex.rgb * UNITY_LIGHTMODEL_AMBIENT.rgb;
				return col;
			}
			ENDHLSL
		}
	}
}