#include "UnityCG.cginc"

	 sampler2D _MainTex;

	 float4 _MainTex_ST;

	 float4 _OutlineColor;

	 float _MaxOutlineZOffset, _Scale, _OutlineWidth;



      struct appdata
     {
         float4 vertex  : POSITION;
         float4 texcoord : TEXCOORD0;
         float4 tangent : TANGENT;
         float4 color   : COLOR;
         float3 normal	: NORMAL;
     };


        struct v2f
     {
         float4 pos      : SV_POSITION;
         float2 uv       : TEXCOORD0;
         float4 color    : COLOR;
     };


     v2f vert(appdata v)
     {
         v2f o = (v2f)0;

         float3 viewTangent = 0;
         viewTangent.xyz = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
//                 viewTangent.xyz = UnityObjectToViewPos(v.normal);
         viewTangent.z = 0.01;
         viewTangent = normalize(viewTangent);

         float4 viewPos = mul(UNITY_MATRIX_MV, v.vertex);
         viewPos = (viewPos / viewPos.w);
         float DisToCamera = length(_WorldSpaceCameraPos - v.vertex);
         float outlineFactor = pow(((-viewPos.z / unity_CameraProjection[1].y) / _Scale), 0.2);
         float3 deltaViewPos = normalize(viewPos.xyz) * _MaxOutlineZOffset * _Scale * (v.color.b - 0.5) + viewPos.xyz;

         viewPos.xy = _OutlineWidth * _Scale * v.color.a * outlineFactor * viewTangent.xy + deltaViewPos.xy;
         viewPos.z = deltaViewPos.z;
         o.pos = mul(UNITY_MATRIX_P, viewPos);
         o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

         o.color = float4(_OutlineColor.xyz, 1.0);

         return o;
     }

     float4 frag(v2f i) : SV_Target
     {
         float factor = i.color.w + 0.99000001;
         int fi = (int) max(floor(factor), 0.0);
         if (fi == 0){ discard; }

         #if COMPLEX_OUTLINE_MAINTEXCOLOR_ENABLE
     		#define SATURATION_FACTOR 0.6
			#define BRIGHTNESS_FACTOR 0.8
         	
         	float4 MainTexCol = tex2D(_MainTex, i.uv);
         	float  maxDiffuseColor = max(max(MainTexCol.r, MainTexCol.g), MainTexCol.b);
         	maxDiffuseColor -= (1.0/255.0);
         	float3 lerpValue = saturate((MainTexCol.rgb - float3(maxDiffuseColor, maxDiffuseColor, maxDiffuseColor)) * 255.0);
         	float3 newOutlineColor = lerp(SATURATION_FACTOR * MainTexCol.rgb, MainTexCol.rgb, lerpValue);

         	return float4(BRIGHTNESS_FACTOR * newOutlineColor.rgb * MainTexCol.rgb, i.color.a) * _OutlineColor;

         #elif SIMPLE_OUTLINE_MAINTEXCOLOR_ENABLE
          	float4 MainTexCol = tex2D(_MainTex, i.uv);
	        return float4(MainTexCol.rgb * MainTexCol.rgb * _OutlineColor.rgb, i.color.a);
	     #else
             float4 outcolor = 0;
             outcolor.xyz = i.color.xyz * _OutlineColor.xyz;
             outcolor.w = i.color.w;
             return outcolor;
          #endif
     }

	

