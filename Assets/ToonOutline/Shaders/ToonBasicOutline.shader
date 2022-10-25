Shader "Toon/Basic Outline" 
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}

		_OutlineColor("Outline Color", Color) = (0,0,0,1)
		_Outline("Outline Width", Range(0,0.01)) = 0.002

		_Direction("Direction",Vector) =(0,0,0,0)
		_TimeScale("TimeScale",float) = 1
		_TimeDelay("_TimeDelay",float) = 0

		[HDR] _ColorToMulti ("Color to multiply", Color) = (1,1,1,1)
		[HideInInspector] _SrcBlend ("_SrcBlend", Float) = 1
		[HideInInspector] _DstBlend ("_DstBlend", Float) = 0
		[HideInInspector] _ModelScale ("_ModelScale", Float) = 1
	}
	
	SubShader 
	{
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            CBUFFER_START(UnityPerMaterial)
                float4 _ColorToMulti;
                float4 _MainTex_ST;
   
                uniform float _ModelScale;
                half _Outline;
                half4 _OutlineColor;
   
                half4 _Direction;
                half _TimeScale;
                half _TimeDelay;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);
		ENDHLSL	
		
		Pass
        {
            Name "OUTLINE"
            Tags {"LightMode" = "SRPDefaultUnlit"}
            Blend [_SrcBlend] [_DstBlend]
            Cull Front
            ZWrite On
   
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                half4 color : COLOR;
                float4 tangent : TANGENT;
                float2 texCoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                half2 uv : TEXCOORD0;

            };


            inline float4 OutlineProcess(float3 vPos, float3 dir, float amount)
            {
                float4 pos = mul(UNITY_MATRIX_MV, float4(vPos,1));
                float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, dir);
                float dis2Cam = length(pos.xyz);
                dis2Cam = lerp(dis2Cam, 3, UNITY_MATRIX_P[3][3]);
                float _characterFOVFactor = 1;	 //FOV对沟边的影响
                amount *= _characterFOVFactor;
                pos.xy += (normalize(normal).xyz*_ModelScale * amount * pow(dis2Cam / 3,0.5)).xy;	// 这里根据相机距离做了一个曲线处理，让勾边随镜头推进变细
                pos = mul(UNITY_MATRIX_P, pos);
                return pos;
            }

            v2f vert(appdata v)
            {
                v2f o;
                half time = (_Time.y + _TimeDelay) * _TimeScale;
                v.vertex.xyz += v.color * (sin(time) * cos(time * 2 / 3) + 1) * _Direction.xyz;	//核心，动态顶点变换
                o.pos = OutlineProcess(v.vertex, normalize(v.tangent.xyz), _Outline/* * v.color.a*/);
                o.uv.xy = TRANSFORM_TEX(v.texCoord.xy, _MainTex);
                
                return o;
            }
            half4 frag(v2f i) : SV_Target
            {
                half4 col = _OutlineColor;
                col.a = saturate(sign(_ColorToMulti.a - 0.95));
                return col;

            }
            ENDHLSL
         }
	}
}
