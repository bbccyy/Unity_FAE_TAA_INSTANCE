Shader "Babeitime/Scene/SkyboxWithSun"
{
	Properties
	{
		[Gamma][Header(Cubemap)]_TintColor("Tint Color", Color) = (0.5,0.5,0.5,1)
		_Exposure("Exposure", Range( 0 , 8)) = 1
		[NoScaleOffset]_Tex("Cubemap (HDR)", CUBE) = "black" {}
		[Header(Rotation)][Toggle(_ENABLEROTATION_ON)] _EnableRotation("Enable Rotation", Float) = 0
		[IntRange]_Rotation("Rotation", Range( 0 , 360)) = 0
		_RotationSpeed("Rotation Speed", Float) = 1
		[Header(Fog)][Toggle(_ENABLEFOG_ON)] _EnableFog("Enable Fog", Float) = 0
		_FogHeight("Fog Height", Range( 0 , 1)) = 1
		_FogSmoothness("Fog Smoothness", Range( 0.01 , 1)) = 0.01
		_FogFill("Fog Fill", Range( 0 , 1)) = 0.5
		[HideInInspector]_Tex_HDR("DecodeInstructions", Vector) = (0,0,0,0)
		[HideInInspector] __dirty( "", Int ) = 1
		
	    [Header(Sun)][KeywordEnum(None, Simple, High Quality)] _SunDisk ("Sun Type", Int) = 2
        _SunSize ("Sun Size", Range(0,1)) = 0.04
		[HDR]_sunColor("Sun Color", color) = (1, 1, 1, 1)
		_SunCullRange("Sun Cull Range", Range( 0 , 8)) = 0.5
	}

	SubShader
	{
		Tags{ "RenderType" = "Background"  "Queue" = "Background+0" "IgnoreProjector" = "True" "ForceNoShadowCasting" = "True" "IsEmissive" = "true"  "PreviewType"="Skybox" }
		Cull Off
		ZWrite Off
		CGPROGRAM
		#include "UnityCG.cginc"
		#pragma target 2.0
		#pragma shader_feature _ENABLEFOG_ON
		#pragma shader_feature _ENABLEROTATION_ON
		#pragma surface surf Unlit keepalpha noshadow noambient novertexlights nolightmap  nodynlightmap nodirlightmap nofog nometa noforwardadd vertex:vertexDataFunc
//        #pragma shader_feature _SUNDISK_NONE _SUNDISK_SIMPLE _SUNDISK_HIGH_QUALITY
        #pragma shader_feature _SUNDISK_NONE _SUNDISK_SIMPLE _SUNDISK_HIGH_QUALITY
        
        // sun disk rendering:
        // no sun disk - the fastest option
        #define SKYBOX_SUNDISK_NONE 0
        // simplistic sun disk - without mie phase function
        #define SKYBOX_SUNDISK_SIMPLE 1
        // full calculation - uses mie phase function
        #define SKYBOX_SUNDISK_HQ 2

        
    #ifndef SKYBOX_SUNDISK
        #if defined(_SUNDISK_NONE)
            #define SKYBOX_SUNDISK SKYBOX_SUNDISK_NONE
        #elif defined(_SUNDISK_SIMPLE)
            #define SKYBOX_SUNDISK SKYBOX_SUNDISK_SIMPLE
        #else
            #define SKYBOX_SUNDISK SKYBOX_SUNDISK_HQ
        #endif
    #endif

    #ifndef SKYBOX_COLOR_IN_TARGET_COLOR_SPACE
        #if defined(SHADER_API_MOBILE)
            #define SKYBOX_COLOR_IN_TARGET_COLOR_SPACE 1
        #else
            #define SKYBOX_COLOR_IN_TARGET_COLOR_SPACE 0
        #endif
    #endif

		struct Input
		{
			float3 vertexToFrag774;
			float3 worldPos;
			
		#if SKYBOX_SUNDISK == SKYBOX_SUNDISK_HQ
            // for HQ sun disk, we need vertex itself to calculate ray-dir per-pixel
            half3   vertex          : TEXCOORD0;
        #elif SKYBOX_SUNDISK == SKYBOX_SUNDISK_SIMPLE
            half3   rayDir          : TEXCOORD0;
        #else
            // as we dont need sun disk we need just rayDir.y (sky/ground threshold)
            half    skyGroundFactor : TEXCOORD0;
        #endif

		};

		uniform half4 _Tex_HDR;
		uniform samplerCUBE _Tex;
		uniform half _Rotation;
		uniform fixed _RotationSpeed;
		uniform fixed4 _TintColor;
		uniform half _Exposure;
		uniform fixed _FogHeight;
		uniform fixed _FogSmoothness;
		uniform fixed _FogFill;
		
        uniform half _SunSize;
        uniform half _SunCullRange;
        uniform half4 _sunColor;

    #if defined(UNITY_COLORSPACE_GAMMA)
        #define GAMMA 2
        #define COLOR_2_GAMMA(color) color
        #define COLOR_2_LINEAR(color) color*color
        #define LINEAR_2_OUTPUT(color) sqrt(color)
    #else
        #define GAMMA 2.2
        // HACK: to get gfx-tests in Gamma mode to agree until UNITY_ACTIVE_COLORSPACE_IS_GAMMA is working properly
        #define COLOR_2_GAMMA(color) ((unity_ColorSpaceDouble.r>2.0) ? pow(color,1.0/GAMMA) : color)
        #define COLOR_2_LINEAR(color) color
        #define LINEAR_2_LINEAR(color) color
    #endif
        #define kSUN_BRIGHTNESS 20.0    // Sun brightness
        static const half kSunScale = 400.0 * kSUN_BRIGHTNESS;
        #define MIE_G (-0.990)
        #define MIE_G2 0.9801

        #define SKY_GROUND_THRESHOLD 0.02
        
		inline half3 DecodeHDR1189( half4 Data )
		{
			return DecodeHDR(Data, _Tex_HDR);
		}


		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			float3 ase_worldPos = mul( unity_ObjectToWorld, v.vertex );
			float lerpResult268 = lerp( 1.0 , ( unity_OrthoParams.y / unity_OrthoParams.x ) , unity_OrthoParams.w);
			fixed CAMERA_MODE300 = lerpResult268;
			float3 appendResult1129 = (float3(ase_worldPos.x , ( ase_worldPos.y * CAMERA_MODE300 ) , ase_worldPos.z));
			float3 normalizeResult1130 = normalize( appendResult1129 );
			float3 appendResult56 = (float3(cos( radians( ( _Rotation + ( _Time.y * _RotationSpeed ) ) ) ) , 0.0 , ( sin( radians( ( _Rotation + ( _Time.y * _RotationSpeed ) ) ) ) * -1.0 )));
			float3 appendResult266 = (float3(0.0 , CAMERA_MODE300 , 0.0));
			float3 appendResult58 = (float3(sin( radians( ( _Rotation + ( _Time.y * _RotationSpeed ) ) ) ) , 0.0 , cos( radians( ( _Rotation + ( _Time.y * _RotationSpeed ) ) ) )));
			float3 normalizeResult247 = normalize( ase_worldPos );
			#ifdef _ENABLEROTATION_ON
				float3 staticSwitch1164 = mul( float3x3(appendResult56, appendResult266, appendResult58), normalizeResult247 );
			#else
				float3 staticSwitch1164 = normalizeResult1130;
			#endif
			o.vertexToFrag774 = staticSwitch1164;
			
            float3 eyeRay = normalize(mul((float3x3)unity_ObjectToWorld, v.vertex.xyz));
        #if SKYBOX_SUNDISK == SKYBOX_SUNDISK_HQ
            o.vertex          = -v.vertex;
        #elif SKYBOX_SUNDISK == SKYBOX_SUNDISK_SIMPLE
            o.rayDir          = half3(-eyeRay);
        #else
            o.skyGroundFactor = -eyeRay.y / SKY_GROUND_THRESHOLD;
        #endif

		}

        // Calculates the Mie phase function
        half getMiePhase(half eyeCos, half eyeCos2)
        {
            half temp = 1.0 + MIE_G2 - 2.0 * MIE_G * eyeCos;
            temp = pow(temp, pow(_SunSize,0.65) * 10);
            temp = max(temp,1.0e-4); // prevent division by zero, esp. in half precision
            temp = 1.5 * ((1.0 - MIE_G2) / (2.0 + MIE_G2)) * (1.0 + eyeCos2) / temp;
            #if defined(UNITY_COLORSPACE_GAMMA) && SKYBOX_COLOR_IN_TARGET_COLOR_SPACE
                temp = pow(temp, .454545);
            #endif
            return temp;
        }

        half calcSunSpot(half3 vec1, half3 vec2)
        {
            half3 delta = vec1 - vec2;
            half dist = length(delta);
            half spot = 1.0 - smoothstep(0.0, _SunSize, dist);
            return kSunScale * spot * spot;
        }
        
		inline fixed4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return fixed4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			half4 Data1189 = texCUBE( _Tex, i.vertexToFrag774 );
			half3 localDecodeHDR1189 = DecodeHDR1189( Data1189 );
			fixed4 CUBEMAP222 = ( float4( localDecodeHDR1189 , 0.0 ) * unity_ColorSpaceDouble * _TintColor * _Exposure );
			float3 ase_worldPos = i.worldPos;
			float3 normalizeResult319 = normalize( ase_worldPos );
			float lerpResult678 = lerp( saturate( pow( (0.0 + (abs( normalizeResult319.y ) - 0.0) * (1.0 - 0.0) / (_FogHeight - 0.0)) , ( 1.0 - _FogSmoothness ) ) ) , 0.0 , _FogFill);
			fixed FOG_MASK359 = lerpResult678;
			float4 lerpResult317 = lerp( unity_FogColor , CUBEMAP222 , FOG_MASK359);
			#ifdef _ENABLEFOG_ON
				float4 staticSwitch1179 = lerpResult317;
			#else
				float4 staticSwitch1179 = CUBEMAP222;
			#endif
			o.Emission = staticSwitch1179.rgb;
			o.Alpha = 1;
			
		#if SKYBOX_SUNDISK == SKYBOX_SUNDISK_HQ
            half3 ray = normalize(mul((float3x3)unity_ObjectToWorld, i.vertex));
            half y = ray.y / SKY_GROUND_THRESHOLD;
        #elif SKYBOX_SUNDISK == SKYBOX_SUNDISK_SIMPLE
            half3 ray = i.rayDir.xyz;
            half y = ray.y / SKY_GROUND_THRESHOLD;
        #else
            half y = i.skyGroundFactor;
        #endif

        half3 col = half3(1, 1, 1);
        
        #if SKYBOX_SUNDISK != SKYBOX_SUNDISK_NONE
            if(y < 0.0)
            {
            #if SKYBOX_SUNDISK == SKYBOX_SUNDISK_SIMPLE
                half mie = calcSunSpot(_WorldSpaceLightPos0.xyz, -ray);
            #else // SKYBOX_SUNDISK_HQ
                half eyeCos = dot(_WorldSpaceLightPos0.xyz, ray);
                half eyeCos2 = eyeCos * eyeCos;
                half mie = getMiePhase(eyeCos, eyeCos2);
            #endif
//                col += mie * IN.sunColor;
                col += mie * _sunColor;
            }
        #endif

        #if defined(UNITY_COLORSPACE_GAMMA) && !SKYBOX_COLOR_IN_TARGET_COLOR_SPACE
            col = LINEAR_2_OUTPUT(col);
        #endif
            o.Emission += saturate(col * 0.5 - _SunCullRange);
		}

		ENDCG
	}
}