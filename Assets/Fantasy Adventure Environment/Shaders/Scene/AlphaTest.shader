Shader "Babeitime/Scene/AlphaTest"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _AlphaScale ("Alpha Scale", Range(0, 1)) = 1
    }
    SubShader
    {
        // 透明度混合队列为Transparent，所以Queue=Transparent
        // RenderType标签让Unity把这个Shader归入提前定义的组中，以指明该Shader是一个使用了透明度混合的Shader
        // IgonreProjector为True表明此Shader不受投影器（Projectors）影响
        Tags
        { 
            "RenderPipeline"="UniversalPipeline"
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
        }
        Pass
        {
            Tags { "LightMode"="UniversalForward" }

            // 关闭深度写入
            ZWrite Off
            // 开启混合模式，并设置混合因子为SrcAlpha和OneMinusSrcAlpha
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

//            #include "UnityCG.cginc"
//            #include "Lighting.cginc"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariablesFunctions.hlsl"

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half4 _Color;
            // 用于决定调用clip函数时进行的透明度测试使用的判断条件
            half _AlphaScale;

            v2f vert (a2v v)
            {
                v2f o;

                o.pos = TransformObjectToHClip(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(v.normal);
                o.worldNormal = vertexNormalInput.normalWS;
//                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half3 worldNormal = normalize(i.worldNormal);
                half3 worldPos = normalize(i.worldPos);
                half3 worldLightDir = normalize(_MainLightPosition.xyz);
                // 纹素值
                half4 texColor = tex2D(_MainTex, i.uv);
                // 反射率
                half3 albedo =  texColor.rgb * _Color.rgb;
                // 环境光
                half3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;
                // 漫反射
                half3 diffuse = _MainLightColor.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
                // 返回颜色，透明度部分乘以我们设定的值
                return half4(ambient + diffuse, texColor.a * _AlphaScale);
            }
            ENDHLSL
        }
    }
}