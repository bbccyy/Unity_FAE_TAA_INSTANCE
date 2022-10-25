Shader "Babeitime/Character/glass"
{
	Properties
	{
		_Color("Color",color) = (1,1,1,1)
		_SpecColor("Specular Color",color) = (1,1,1,1)
		_Fresnel("Fresnel",Range(0,1)) = 0.5
		_Smoothness("Smoothness",Range(0.05,1)) = 0.5
		_MainTex("Texture", 2D) = "white" {}
		_NormalTex("Normal",2D) = "bump"{}
		_Reflect("Reflect",cube) = ""{}
		//UI遮罩
		_StencilComp ("Stencil Comparison", Float) = 8
		_Stencil ("Stencil ID", Float) = 0
		_StencilOp ("Stencil Operation", Float) = 0
		_StencilWriteMask ("Stencil Write Mask", Float) = 255
		_StencilReadMask ("Stencil Read Mask", Float) = 255
		[HDR] _ColorToMulti ("Color to multiply", Color) = (1,1,1,1)
	}
	SubShader
	{
		Tags {"RenderPipeline"="UniversalPipeline" "RenderType" = "Transparent"  "Queue"	=	"Transparent"}

		
        //UI遮罩
        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp] 
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }
		
		Pass
		{

			Zwrite on
			Blend SrcAlpha OneMinusSrcAlpha
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
//			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
//			#include "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariablesFunctions.hlsl"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float fogCoord : TEXCOORD0;
				float2 uv[2] : TEXCOORD1;
				float3 normal : TEXCOORD3;
				float4 wPos : TEXCOORD4;
			};
			uniform half4 _Color;
			uniform half4 _SpecColor;
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			uniform sampler2D _NormalTex;
			uniform float4 _NormalTex_ST;
			uniform float _Fresnel;
			uniform samplerCUBE _Reflect;
			uniform float _Smoothness;
			
            float4 _ColorToMulti;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = TransformObjectToHClip(v.vertex);
				o.uv[0] = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv[1] = TRANSFORM_TEX(v.uv, _NormalTex);
				VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(v.normal);
                o.normal = vertexNormalInput.normalWS;
				o.wPos = mul(unity_ObjectToWorld, v.vertex);
				o.fogCoord = ComputeFogFactor(o.vertex.z);
				return o;
			}

			half4 frag(v2f i) : SV_Target
			{
				float4 tex = tex2D(_MainTex, i.uv[0]);
				float3 nor = UnpackNormal(tex2D(_NormalTex, i.uv[1]));
				nor = normalize(i.normal + nor.xxy);
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.wPos);
				
				float3 lightDir = normalize(_MainLightPosition.xyz - TransformObjectToWorld(i.wPos));
				float spec = max(0, dot(nor, normalize(viewDir + lightDir)));
				spec = pow(spec, _Smoothness * _Smoothness * 200);
				spec *= tex.a;
				float rim = 1 - pow(max(0,dot(nor,viewDir)), _Fresnel * 6);
				rim *= tex.a;
				half4 refl = texCUBE(_Reflect, -reflect(viewDir,nor));
				half4 col = tex*_Color;
				col.rgb += _SpecColor * spec;
				col.rgb += rim *refl.rgb;
				col.a = max(rim, max(spec, col.a));
//				UNITY_APPLY_FOG(i.fogCoord, col);
				col.rgb = MixFog(col.rgb, i.fogCoord);
				col.a *= _ColorToMulti.a;
				return col;
			}
			ENDHLSL
		}
	}
	Fallback "VertexLit"
}