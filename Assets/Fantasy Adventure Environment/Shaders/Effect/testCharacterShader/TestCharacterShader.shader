Shader "sg3/TestCharacter/Character" 
{
    Properties 
    {
         _Color ("Main Color", Color) = (1,1,1,1)
         _Scale ("Scale Compared to Maya", Range(0,1)) = 0.01
        // [HideInInspector]  _Scale ("Scale Compared to Maya", Float) = 0.01
         _BloomFactor ("Bloom Factor", Float) = 1
         _MainTex ("Main Tex (RGB)", 2D) = "white" { }
         _LightMapTex ("Light Map Tex (RGB)", 2D) = "gray" { }
         _LightSpecColor ("Light Specular Color", Color) = (1,1,1,1)

         _LightArea ("Light Area Threshold", Range(0,1)) = 0.51
         _SecondShadow ("Second Shadow Threshold", Range(0,1)) = 0.51

         _SecondShadowMultColor ("Second Shadow Multiply Color", Color) = (0.75,0.6,0.65,1)
         _Shininess ("Specular Shininess", Range(0.1,1000)) = 10
         _SpecMulti ("Specular Multiply Factor", Range(0,1)) = 0.1
         _OutlineWidth ("Outline Width", Range(0,1)) = 0.2
         _OutlineColor ("Outline Color", Color) = (0,0,0,1)
         _MaxOutlineZOffset ("Max Outline Z Offset", Range(0,100)) = 1
                          
         _AnisotropicFactor ("anisotropic",Range(0,10)) = 0.5
         _CubeReflect("Reflect (CUBE)", CUBE) = "black" {}
         _ReflectFactor("Reflect Factor", Float) = 1 
         _ShadowTexture ("ShadowTexture(RGB)", 2D ) = "black" { }

        [HideInInspector]  _Opaqueness ("Opaqueness", Range(0,1)) = 1
        [HideInInspector]  _VertexAlphaFactor ("Alpha From Vertex Factor (0: not use)", Range(0,1)) = 0
    }

    SubShader 
    { 
        LOD 200
        Tags { "QUEUE"="Geometry" "IGNOREPROJECTOR"="true" "RenderType"="Opaque" "Distortion"="None" "OutlineType"="Complex" "Reflected"="Reflected" }

        // cel-shading pass
        Pass 
        {
            Name "COMPLEX"
            Tags { "LIGHTMODE"="ForwardBase" "QUEUE"="Geometry" "IGNOREPROJECTOR"="true" "RenderType"="Opaque" "Distortion"="None" "OutlineType"="Complex" "Reflected"="Reflected" }

            Cull Back
            ZTest LEqual

            CGPROGRAM
            #include "UnityCG.cginc"
              
            #pragma vertex vert
            #pragma fragment frag
//            #pragma fragmentoption ARB_precision_hint_fastest 

            
     		float4 _MainTex_ST;

            struct appdata
            {
                float4 vertex   : POSITION;
                float3 normal   : NORMAL;
                float4 texcoord : TEXCOORD0;
                float4  color    : COLOR0;
            };

            struct v2f
            {
                float4 pos      : SV_POSITION;
                float4 color    : COLOR0;
                float  light    : COLOR1;
                float2 uv       : TEXCOORD0;
                float3 normal   : TEXCOORD1;
                float3 wPos     : TEXCOORD2;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.color = v.color;    
//                o.normal = normalize(mul(unity_WorldToObject, v.normal));
                o.normal = UnityObjectToWorldNormal(v.normal);
                float NdotL = dot(o.normal, _WorldSpaceLightPos0.xyz);
                o.light = NdotL * 0.497500002 + 0.5; // 0.0025 ~ 0.9975

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.wPos = worldPos.xyz / worldPos.w;

                return o;
            }


            uniform     fixed4 _Color;
            uniform 	float _LightArea;
            uniform 	float _SecondShadow;
            uniform 	float3 _SecondShadowMultColor;
            uniform 	float _Shininess;
            uniform 	float _SpecMulti;
            uniform 	float3 _LightSpecColor;
            uniform 	float4 _LightColor0;
            uniform 	float _BloomFactor;
            uniform     sampler2D _LightMapTex;
            uniform     sampler2D _MainTex;
            			float _AnisotropicFactor;           	
		    sampler2D   _ShadowTexture;
		    samplerCUBE _CubeReflect;
		    float	 	_ReflectFactor;
		                // 根据f的大小得到，两极值之一
            inline float3 floorStep(float f, float3 a, float3 b)
            {
                return (int(max(floor(f), 0.0)) != 0) ? a : b;
            }

            inline float floorStep(float f, float a, float b)
            {
                return (int(max(floor(f), 0.0)) != 0) ? a : b;
            }

           	static float2 texsize = float2(1024.0f, 1024.0f);
           

            float4 frag(v2f i) : SV_Target
            {    
                // 顶点颜色的R通道里，加入[阴的倾向权重参数]。
                fixed4 lightMap = tex2D(_LightMapTex, i.uv);
                float shadowFactor = lightMap.g * i.color.r; // shadow factor. [0, 1];
                float2 shadowValueVec2 = shadowFactor * float2(1.20000005, 1.25) - float2(0.100000001, 0.125);
                float shadowValue = floorStep(1.5 - shadowFactor, shadowValueVec2.y, shadowValueVec2.x);

                // i.light [0.0025, 0.9975]
                float3 diffcol = tex2D(_MainTex, i.uv.xy).rgb;    

                //shadow part
                #define SHADOWTEXTURE
	                #ifdef SHADOWTEXTURE
	                	float3 shadowTexture = tex2D(_ShadowTexture, i.uv).rgb;
	                	_SecondShadowMultColor = shadowTexture * _SecondShadowMultColor;
	                #endif

                //anti-aliasing
//                float3 n = normalize(i.normal);
//                float ndotl = dot(n, _WorldSpaceLightPos0.xyz) * 0.497500002 + 0.5;
//                float shadowColor1Factor = (shadowValue + ndotl) * 0.5 - _LightArea + 1.0;
//
//               	float dds = fwidth(shadowColor1Factor) * 2;
//                float3 shadowColor1 = 0;
//                if (shadowColor1Factor > 1.0 - dds && shadowColor1Factor < 1.0 + dds)
//                {
//                	float s = smoothstep(1.0 - dds, 1.0 + dds, shadowColor1Factor);
//                	shadowColor1 = lerp(diffcol, diffcol * shadowTexture, 1.0 - s);
//                }
//                else
//                {
//                 	 shadowColor1 = floorStep(shadowColor1Factor, diffcol, diffcol * shadowTexture);
//                }

				// _FirstShadow Color
				float shadowColor1Factor = (shadowValue + i.light) * 0.5 - _LightArea + 1.0;
                float3 shadowColor1 = floorStep(shadowColor1Factor, diffcol, diffcol * shadowTexture * 1.25);

                // _SecondShadow Color
                float shadowColor2Factor = (shadowFactor + i.light) * 0.5 - _SecondShadow + 1.0;
                float3 shadowColor2 = floorStep(shadowColor2Factor, diffcol * shadowTexture, diffcol * _SecondShadowMultColor);

                // Main tint Shadow Color
                float shadowColorFactor = shadowFactor + 0.909999967;
                float3 diffuseTintShadowColor = floorStep(shadowColorFactor, shadowColor1, shadowColor2);

                // Specular Color
                float3 eyeVec = normalize(_WorldSpaceCameraPos - i.wPos);
                float3 halfVec = normalize(eyeVec + _WorldSpaceLightPos0);
                float3 normal = normalize(i.normal);
                float specularColorFactor = (1.0 - lightMap.b) - pow(max(dot(halfVec, normal), 0.0), _Shininess) + 1.0;

                float3 specularColor = lightMap.r * (_SpecMulti * _LightSpecColor).rgb;
                specularColor = floorStep(specularColorFactor, float3(0.0, 0.0, 0.0), specularColor);

                //anisotropic Specular Color
                float3 tangent = normalize(cross(normal, eyeVec)); 
                float LdotT = dot(_WorldSpaceLightPos0.xyz, tangent);
                float VdotT = dot(eyeVec, tangent);
                float brdfFactor = sqrt(1-pow(LdotT, 2.0)) * sqrt(1-pow(VdotT, 2.0)) - LdotT * VdotT;
                float brdf = _AnisotropicFactor * pow(brdfFactor, _Shininess);
                //calculate Environment Reflect
                float refl = reflect(-eyeVec, normal);
                float4 reflectColor = texCUBE(_CubeReflect, refl) * _ReflectFactor * lightMap.r;

                float3 anisotropic_specularColor = brdf * (reflectColor.rgb + _LightSpecColor.rgb) * i.light * lightMap.a ;



                float3 finalSpecular = specularColor * (1 - lightMap.a) + anisotropic_specularColor;
                // compose Diffuse Shadow Specular color.
                float3 finalcol = (diffuseTintShadowColor + specularColor) * _Color.xyz;
//            	float3 finalcol = (diffuseTintShadowColor + finalSpecular) * _Color.xyz;

                return float4(finalcol, _BloomFactor);
            }
            ENDCG
        }

        // outline pass 有问题
         Pass 
         {
             Name "COMPLEX"
             Tags { "LIGHTMODE"="ForwardBase" "QUEUE"="Geometry" "IGNOREPROJECTOR"="true" "RenderType"="Opaque" "Distortion"="None" "OutlineType"="Complex" "Reflected"="Reflected" }
             Cull Front
            
             CGPROGRAM
             #include "UnityCG.cginc"

             #pragma vertex vert
             #pragma fragment frag

             sampler2D _MainTex;
             float4 _MainTex_ST;
             uniform float4 _Color;
             uniform float _MaxOutlineZOffset;
             uniform float _Scale;
             uniform float4 _OutlineColor;
             uniform float _OutlineWidth;
             float4 _LightColor0;

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
//                 viewTangent = mul((float3x3)UNITY_MATRIX_MV, v.tangent.xyz);
                 viewTangent.xyz = mul((float3x3)UNITY_MATRIX_MV, v.normal);
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

//                 float4 outcolor = 0;
//                 outcolor.xyz = i.color.xyz * _Color.xyz;
//                 outcolor.w = i.color.w;
//                 return outcolor;
//            	 #define SIMPLE_OUTLINE_MAINTEXCOLOR
            	 #define COMPLEX_OUTLINE_MAINTEXCOLOR


					#ifdef	SIMPLE_OUTLINE_MAINTEXCOLOR
			             float4 MainTexCol = tex2D(_MainTex, i.uv);
			             return float4(MainTexCol.rgb * MainTexCol.rgb * _OutlineColor.rgb, i.color.w);
	                #endif
                 
                 	#ifdef	COMPLEX_OUTLINE_MAINTEXCOLOR

						#define SATURATION_FACTOR 0.6
						#define BRIGHTNESS_FACTOR 0.8
	                 	
	                 	float4 MainTexCol = tex2D(_MainTex, i.uv);
	                 	float  maxDiffuseColor = max(max(MainTexCol.r, MainTexCol.g), MainTexCol.b);
	                 	maxDiffuseColor -= (1.0/255.0);
	                 	float3 lerpValue = saturate((MainTexCol.rgb - float3(maxDiffuseColor, maxDiffuseColor, maxDiffuseColor)) * 255.0);
	                 	float3 newOutlineColor = lerp(SATURATION_FACTOR * MainTexCol.rgb, MainTexCol.rgb, lerpValue);

	                 	return float4(BRIGHTNESS_FACTOR * newOutlineColor.rgb * MainTexCol.rgb, i.color.w) * _OutlineColor * _LightColor0;
              		#endif
             }
             ENDCG
         }
    }
}
