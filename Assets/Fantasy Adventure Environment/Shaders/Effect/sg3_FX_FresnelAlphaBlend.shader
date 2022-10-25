Shader "sg3/Fx/FresnelAlphaBlend" 
{
	Properties 
	{
        _MainTex ("Main Tex",2D) = "white"{}
		[HDR]_TintColor ("Tint Color",Color) = (1,1,1,1)
		[HDR]_FresnelColor ("Fresnel Color",Color) = (1,1,1,1)
		_FresnelRange ("Fresnel Range",Range(0,1)) = 0.5
		_FresnelIntensity("Fresnel Intensity",Range(0,4)) = 1.0
        _AlphaScale ("Alpha Scale", Range(0, 1)) = 1
		_ColorPower ("Color Power", Range(0, 2)) = 1
		[Enum(CullMode)] _CullMode("剔除模式", Float) = 2
	}
	SubShader
	{
		Tags {"RenderPipeline"="UniversalPipeline" "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
		
		Pass 
		{ 
			Tags { "LightMode"="UniversalForward" }

			Blend SrcAlpha OneMinusSrcAlpha
			//Blend One One
			Cull [_CullMode]

			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariablesFunctions.hlsl"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _MaskTex;
            float4 _MaskTex_ST;
			float _FresnelRange;
			float4 _FresnelColor,_TintColor;
			float _FresnelIntensity;
            float _AlphaScale;
			float _ColorPower;
			
			struct a2v 
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
           		float4 color : COLOR;
			};
			
			struct v2f 
			{
				float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				float3 worldViewDir : TEXCOORD2;
                float4 clr : COLOR;
			};
			
			v2f vert(a2v v) 
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex);
//				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(v.normal);
                o.worldNormal = vertexNormalInput.normalWS;
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldViewDir = GetWorldSpaceNormalizeViewDir(worldPos);
				o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord,_MaskTex);
                o.clr = v.color;
				return o;
			}
			
			float4 frag(v2f i) : SV_Target 
			{
				float3 worldNormal = normalize(i.worldNormal);	
				float3 worldViewDir = normalize(i.worldViewDir);		
 			    float fresnel = pow(1-saturate(dot(worldNormal,worldViewDir)),lerp(0,11,_FresnelRange));
				float3 fresnelColor = fresnel * _FresnelColor.rgb * _FresnelIntensity;
                float fresnelAlpha = _FresnelColor.a * fresnel * _FresnelIntensity;
                float4 albedo = tex2D(_MainTex,i.uv.xy);
				float4 result = float4 ((albedo * _TintColor.rgb + fresnelColor)*_ColorPower, albedo.a * _AlphaScale * _TintColor.a);
				result *= i.clr;
				return result;
			}
			ENDHLSL
		}
	}
    FallBack "Babeltime/Diffuse"  
}
