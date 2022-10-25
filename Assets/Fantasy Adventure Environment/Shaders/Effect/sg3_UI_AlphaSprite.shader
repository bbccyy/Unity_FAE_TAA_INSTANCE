Shader "sg3/UI/AlphaSprite" 
{  
    Properties 
    {  
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}

        _Color ("Tint", Color) = (1,1,1,1)
		_ImageTex("_ImageTex", 2D) = "white" {}
    }
    
    SubShader 
    {
        Tags
        { 
            "Queue"="Transparent" 
            "IgnoreProjector"="True" 
            "RenderType"="Transparent" 
            "PreviewType"="Plane"
        }
        

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
		Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {         
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            #include "UnityUI.cginc"
            
            #pragma shader_feature __ UNITY_UI_ALPHACLIP

            struct a2v
            {
                fixed2 uv : TEXCOORD0;
                half4 vertex : POSITION;
            };

            struct v2f
            {
                fixed4 uv : TEXCOORD0;
                half4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _ImageTex;
            fixed4 _Color;
			fixed4 _UVAlphaRect = fixed4(0, 0, 1, 1);	//Alpha图集中的起点和宽度
			fixed4 _UVShowRect = fixed4(0, 0, 1, 1);	//显示区域在图集的起点和宽度

            v2f vert (a2v i)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(i.vertex);

				o.uv.zw = i.uv;

				fixed2 normalized_uv = (i.uv - _UVAlphaRect.xy) / _UVAlphaRect.zw;

				o.uv.xy = _UVShowRect.zw * normalized_uv + _UVShowRect.xy;

                return o;
            }
            
            fixed4 frag (v2f i) : COLOR
            {
                half4 color = tex2D(_ImageTex, i.uv.xy) * _Color;
				color.a *= tex2D(_MainTex, i.uv.zw).r;
                return color;
				//return i.uv.xyzw, 0, 1;
				//return float4(i.uv.y, 0, 0, 1);
				//return float4(i.uv.zw, 0, 1);
				//return tex2D(_MainTex, i.uv.zw);
            }
            ENDCG
        }  
    }   
}