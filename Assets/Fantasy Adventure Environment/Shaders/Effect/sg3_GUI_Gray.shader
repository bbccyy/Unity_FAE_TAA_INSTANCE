Shader "sg3/UI/GUI_Gray"
{
	Properties
	{
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		//_Brightness ("Brightness", Float) = 1        // 亮度系数  
        _Saturation ("饱和度", Float) = 1        // 饱和度系数 
        _Contrast ("对比度", Float) = 1			//对比度系数

		_StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255

        _ColorMask ("Color Mask", Float) = 15

        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
	}
	SubShader
	{
		Tags{"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" "CanUseSpriteAtlas"="True"}

		 Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

		Cull Off
        Lighting Off
        ZWrite Off
		ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
		ColorMask [_ColorMask]

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#pragma shader_feature __ UNITY_UI_CLIP_RECT
			#pragma shader_feature __ UNITY_UI_ALPHACLIP
			//#pragma shader_feature __ UNITY_UI_ALPHACLIP
			#include "UnityCG.cginc"
			#include "UnityUI.cginc"

			struct appdata
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

		    struct v2f
            {
                float4 pos   : SV_POSITION;
                fixed4 color    : COLOR;
                float2 texcoord  : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

			sampler2D _MainTex;
			fixed4 _Color;
            fixed4 _TextureSampleAdd;
            float4 _ClipRect;
			fixed _Brightness, _Saturation, _Contrast;
			
			v2f vert (appdata v)
			{
				v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.worldPosition = v.vertex;
                OUT.pos = UnityObjectToClipPos(OUT.worldPosition);

                OUT.texcoord = v.texcoord;

                OUT.color = v.color;
                return OUT;
			}
		
			fixed4 frag (v2f i) : SV_Target
			{
				half4 col = (tex2D(_MainTex, i.texcoord) + _TextureSampleAdd) * i.color;
				//apply saturation
				fixed luminance = 0.2125 * col.r + 0.7154 * col.g + 0.721 * col.b;
				fixed3 luminaceColor = luminance;
				col.rgb = lerp(luminaceColor, col.rgb, _Saturation);
				//apply Contrast
				fixed3 avgColor = fixed3(0.5,0.5,0.5);               
            	col.rgb = lerp(avgColor, col.rgb, _Contrast);

				#ifdef UNITY_UI_CLIP_RECT
                col.a *= UnityGet2DClipping(i.worldPosition.xy, _ClipRect);
				#endif

                #ifdef UNITY_UI_ALPHACLIP
                clip (col.a - 0.001);
                #endif

                return col;
			}
			ENDCG
		}
	}
}
