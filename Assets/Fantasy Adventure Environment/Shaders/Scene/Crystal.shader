Shader "Babeitime/Character/Crystal" 
{
	Properties
	{
		//主颜色
		_MainColor("Main Color", Color) = (1.0, 1.0, 1.0, 1.0)
		//细节纹理深度偏移
		_DetailTexDepthOffset("Detail Textrue Depth Offset", Float) = 1.0
		//Material Capture纹理
		_MatCap("MatCap", 2D) = "white" {}
		[Header(Outline)]//Inspector显示分类标题
        _OutlineVal("Outline value",Range(0.,1)) = 0.01//自定义描边大小
        _OutlineCol("Outline color",Color) = (1.,1.,1.,1)//描边颜色
		//UI遮罩
		_StencilComp ("Stencil Comparison", Float) = 8
		_Stencil ("Stencil ID", Float) = 0
		_StencilOp ("Stencil Operation", Float) = 0
		_StencilWriteMask ("Stencil Write Mask", Float) = 255
		_StencilReadMask ("Stencil Read Mask", Float) = 255
		[HDR] _ColorToMulti ("Color to multiply", Color) = (0.5,0.5,0.5,1)
		[HideInInspector] _SrcBlend ("_SrcBlend", Float) = 1
		[HideInInspector] _DstBlend ("_DstBlend", Float) = 0
		//
		[HideInInspector] _ReflectionStrength ("_ReflectionStrength", Float) = 0
		[HideInInspector] _DetailColor("_DetailColor", Color) = (1.0, 1.0, 1.0, 1.0)
	
	}
 
	SubShader
	{
		Tags
		{
		    "RenderPipeline"="UniversalPipeline"
			"Queue" = "Geometry"
			"RenderType" = "Opaque"
			//"LightMode" = "Always"
		}
		
		HLSLINCLUDE
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        
        CBUFFER_START (UnityPerMaterial)  
            float4 _MainColor;
            float4 _DetailColor;
            float _DetailTexDepthOffset;
            float _ReflectionStrength;
            float4 _ColorToMulti;
            float _OutlineVal;
            half4 _OutlineCol;
        CBUFFER_END
        
        float4 _ReflectionColor;
        float4 _DiffuseColor;
        //
        float4 _DiffuseTex_ST;
        float4 _DetailTex_ST;
        
        TEXTURE2D(_MatCap);
		SAMPLER(sampler_MatCap);
		TEXTURE2D(_DiffuseTex);
		SAMPLER(sampler_DiffuseTex);
		TEXTURE2D(_DetailTex);
		SAMPLER(sampler_DetailTex);
        TEXTURECUBE(_ReflectionMap);
		SAMPLER(sampler_ReflectionMap);
        ENDHLSL
		
		//UI遮罩
        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp] 
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }
		
         Pass//第一个pass设置描边轮廓和颜色
        {
        	Name "OUTLINE"
			Tags {"LightMode" = "SRPDefaultUnlit"}
   			Blend [_SrcBlend] [_DstBlend]
            Cull Front
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            // make fog work
            #pragma multi_compile_fog
   
            struct appdata_base
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };
            
            struct v2f
            {
                float4 pos : SV_POSITION;
            };
            

            v2f vert (appdata_base v)
            {
                v2f o;
                //将顶点转到裁剪空间
                o.pos = TransformObjectToHClip(v.vertex);
                //将法线转到相机空间
                float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV,v.normal);
                //裁剪空间计算法线的值
                normal.x *= UNITY_MATRIX_P[0][0];
                normal.y *= UNITY_MATRIX_P[1][1];
                //根据法线和描边大小缩放模型
                o.pos.xy += _OutlineVal * normal.xy;
                return o;
            }
            
            half4 frag (v2f i) : SV_Target
            {
				half4 col = _OutlineCol;
				col.a = saturate(sign(_ColorToMulti.a - 0.95));
				return col;
            }
            ENDHLSL
			}
			Pass
			{
			Tags{"LightMode" = "UniversalForward"}
//			Blend Off
   			Blend [_SrcBlend] [_DstBlend]
			Cull Back
			ZWrite On
 
			HLSLPROGRAM

			#pragma fragment frag
			#pragma vertex vert
            
			//顶点输入结构
			struct VertexInput
			{
				float3 normal : NORMAL;
				float4 position : POSITION;
				float2 UVCoordsChannel1: TEXCOORD0;
			};
 
			//顶点输出(片元输入)结构
			struct VertexToFragment
			{
				float3 detailUVCoordsAndDepth : TEXCOORD0;
				float4 diffuseUVAndMatCapCoords : TEXCOORD1;
				float4 position : SV_POSITION;
				float3 worldSpaceReflectionVector : TEXCOORD2;
			};
 
			//------------------------------------------------------------
			// 顶点着色器
			//------------------------------------------------------------
			VertexToFragment vert(VertexInput input)
			{
				VertexToFragment output;
 
				//漫反射UV坐标准备：存储于TEXCOORD1的前两个坐标xy。
				output.diffuseUVAndMatCapCoords.xy = TRANSFORM_TEX(input.UVCoordsChannel1, _DiffuseTex);
 
				//MatCap坐标准备：将法线从模型空间转换到观察空间，存储于TEXCOORD1的后两个纹理坐标zw
				output.diffuseUVAndMatCapCoords.z = dot(normalize(UNITY_MATRIX_IT_MV[0].xyz), normalize(input.normal));
				output.diffuseUVAndMatCapCoords.w = dot(normalize(UNITY_MATRIX_IT_MV[1].xyz), normalize(input.normal));
				//归一化的法线值区间[-1,1]转换到适用于纹理的区间[0,1]
				output.diffuseUVAndMatCapCoords.zw = output.diffuseUVAndMatCapCoords.zw * 0.5 + 0.5;
 
				//坐标变换
				output.position = TransformObjectToHClip(input.position);
 
				//细节纹理准备准备UV,存储于TEXCOORD0的前两个坐标xy
				output.detailUVCoordsAndDepth.xy = TRANSFORM_TEX(input.UVCoordsChannel1, _DetailTex);
				
				//深度信息准备,存储于TEXCOORD0的第三个坐标z
				output.detailUVCoordsAndDepth.z = output.position.z;
 
				//世界空间位置
				float3 worldSpacePosition = mul(unity_ObjectToWorld, input.position).xyz;
 
				//世界空间法线
				float3 worldSpaceNormal = normalize(mul((float3x3)unity_ObjectToWorld, input.normal));
 
				//世界空间反射向量
				output.worldSpaceReflectionVector = reflect(worldSpacePosition - _WorldSpaceCameraPos.xyz, worldSpaceNormal);
				
				return output;
			}
 
			//------------------------------------------------------------
			// 片元着色器
			//------------------------------------------------------------
			float4 frag(VertexToFragment input) : COLOR
			{
				//镜面反射颜色
				float3 reflectionColor = SAMPLE_TEXTURECUBE(_ReflectionMap, sampler_ReflectionMap,input.worldSpaceReflectionVector).rgb * _ReflectionColor.rgb;
 
				//漫反射颜色
				float4 diffuseColor = SAMPLE_TEXTURE2D(_DiffuseTex, sampler_DiffuseTex, input.diffuseUVAndMatCapCoords.xy) * _DiffuseColor;
 
				//主颜色
				float3 mainColor = lerp(lerp(_MainColor.rgb, diffuseColor.rgb, diffuseColor.a), reflectionColor, _ReflectionStrength);
 
				//细节纹理
				float3 detailMask = SAMPLE_TEXTURE2D(_DetailTex, sampler_DetailTex,input.detailUVCoordsAndDepth.xy).rgb;
 
				//细节颜色
				float3 detailColor = lerp(_DetailColor.rgb, mainColor, detailMask);
 
				//细节颜色和主颜色进行插值，成为新的主颜色
				mainColor = lerp(detailColor, mainColor, saturate(input.detailUVCoordsAndDepth.z * _DetailTexDepthOffset));
 
				//从提供的MatCap纹理中，提取出对应光照信息
				float3 matCapColor = SAMPLE_TEXTURE2D(_MatCap, sampler_MatCap,input.diffuseUVAndMatCapCoords.zw).rgb;
 
				//最终颜色
				float4 finalColor=float4(mainColor * matCapColor * 2.0, _MainColor.a);

 				finalColor *= _ColorToMulti;
				return finalColor;
			}
 
			ENDHLSL
		}
	}
 
	Fallback "VertexLit"
}