Shader "sg3/Fx/SpaceWarp_01" 
{
	Properties 
	{
		_RefractMap("Refraction Map",2D) = "white"{}
		_MaskTex("Mask Texture",2D) = "white"{}
		_Uspeed("U Offset Speed",Float) = 0
		_Vspeed("V Offset Speed",Float) = 0
		_Distortion("Distortion",Float) = 0.5
		//[HideInInspector] _SrcBlend ("_SrcBlend", Float) = 1
		//[HideInInspector] _DstBlend ("_DstBlend", Float) = 0
	}

	SubShader 
	{
		Tags {"RenderPipeline"="UniversalPipeline" "Queue" = "Transparent"}
		
		ZWrite Off  
        Lighting Off 
		Cull Off
        Blend SrcAlpha OneMinusSrcAlpha
        
		Pass 
		{
			Tags{ "LightMode"="BabidiWarp" }
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag	
			#pragma multi_compile UNITY_UV_STARTS_AT_TOP
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			CBUFFER_START(UnityPerMaterial)
			float4 _RefractMap_ST;
			float4 _MaskTex_ST;
			float4 _CameraColorTexture_TexelSize;
			float _Distortion;
			float _Uspeed;
			float _Vspeed;
			CBUFFER_END
            TEXTURE2D(_WarpTexture);   	 	SAMPLER(sampler_WarpTexture);
			TEXTURE2D(_RefractMap);       			SAMPLER(sampler_RefractMap);
			TEXTURE2D(_MaskTex); 					SAMPLER(sampler_MaskTex);
			

			struct appdata
            {
				half4 vertex : POSITION;
				half2 texcoord : TEXCOORD0;
				half4 color: COLOR;
            };

			struct v2f 
			{
				float4 vertex : SV_POSITION;
				float4 uvRefrMask : TEXCOORD0;
				float4 a : TEXCOORD1;
				half4 color : COLOR;
			};

			v2f vert (appdata v)
			{
				v2f o;
				VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex);
				o.vertex = vertexInput.positionCS;


				o.uvRefrMask.xy = TRANSFORM_TEX(v.texcoord, _RefractMap);
				o.uvRefrMask.x += _Uspeed * _Time.y;
				o.uvRefrMask.y += _Vspeed * _Time.y;
				o.uvRefrMask.zw = TRANSFORM_TEX(v.texcoord, _MaskTex);
				o.a = o.vertex;
				o.color = v.color;
				return o;
			}

			half4 frag(v2f i) : SV_Target
			{	
				float2 uvgrab = i.a .xy / i.a.w;
				uvgrab = uvgrab * 0.5+0.5;

			 	half2 refraction = SAMPLE_TEXTURE2D(_RefractMap,sampler_RefractMap,i.uvRefrMask.xy).rg;
				half2 refractionFix = SAMPLE_TEXTURE2D(_RefractMap,sampler_RefractMap,i.uvRefrMask.xy + float2(0.002,-0.002)).rg;
				half mask = SAMPLE_TEXTURE2D(_MaskTex,sampler_MaskTex,i.uvRefrMask.zw).r;
				float2 offset = (refractionFix - 0.5) * refraction * _Distortion * 2.0 
								* _CameraColorTexture_TexelSize.xy * i.vertex.w * mask;
				uvgrab.xy += offset;
				half4 col = SAMPLE_TEXTURE2D(_WarpTexture,sampler_WarpTexture,uvgrab);
				//col = float4(1.0, 0, 0, 1);
				return col;
			}
			ENDHLSL
		}
	}
}
