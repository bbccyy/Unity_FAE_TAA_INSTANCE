Shader "FAE/Tree Branch New"
{
    Properties
    {
		_Cutoff( "Mask Clip Value", Float ) = 0.5
		[NoScaleOffset]_MainTex("MainTex", 2D) = "white" {}
		[HDR]_BaseColor("BaseColor", Color) = (1,1,1,1)
		_HueVariation("Hue Variation", Color) = (1,0.5,0,0.184)
		[NoScaleOffset]_BumpMap("BumpMap", 2D) = "bump" {}
		_TransmissionColor("Transmission Color", Color) = (1,1,1,0)
		_AmbientOcclusion("AmbientOcclusion", Range( 0 , 1)) = 0
		_MaxWindStrength("MaxWindStrength", Range( 0 , 1)) = 0.1164738
		_FlatLighting("FlatLighting", Range( 0 , 1)) = 0
		_WindAmplitudeMultiplier("WindAmplitudeMultiplier", Float) = 1
		_GradientBrightness("GradientBrightness", Range( 0 , 2)) = 1
		_Smoothness("Smoothness", Range( 0 , 1)) = 0
		[Toggle]_UseSpeedTreeWind("UseSpeedTreeWind", Float) = 0
		[HideInInspector] _texcoord2( "", 2D ) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1

		[HideInInspector] _TrunkWindSpeed( "_TrunkWindSpeed", float ) = 1.0
		[HideInInspector] _TrunkWindSwinging( "_TrunkWindSwinging", float ) = 1.0
		[HideInInspector] _TrunkWindWeight( "_TrunkWindWeight", float ) = 1.0
		[HideInInspector] _WindAmplitude( "_WindAmplitude", float ) = 1.0
		[HideInInspector] _WindSpeed( "_WindSpeed", float ) = 1.0
		[HideInInspector] _WindStrength( "_WindStrength", float ) = 1.0
		[HideInInspector] _WindDirection( "_WindDirection", Vector) = (0,0,0,0)
		//[HideInInspector] _WindDebug( "_WindDebug", float ) = 1.0
    }

    HLSLINCLUDE

    // Pragmas
    #pragma prefer_hlslcc gles
    #pragma exclude_renderers d3d11_9x
    #pragma target 2.0
    #pragma multi_compile_fog
    #pragma multi_compile_instancing

    // Keywords
    #pragma shader_feature _ LIGHTMAP_ON
    #pragma shader_feature _ DIRLIGHTMAP_COMBINED
    #pragma shader_feature _ _MAIN_LIGHT_SHADOWS
    #pragma shader_feature _ _MAIN_LIGHT_SHADOWS_CASCADE
    #pragma shader_feature _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
    #pragma shader_feature _ _ADDITIONAL_LIGHT_SHADOWS
    #pragma shader_feature _ _SHADOWS_SOFT
    #pragma shader_feature _ _MIXED_LIGHTING_SUBTRACTIVE

    //the core .hlsl of the whole URP surface shader structure, must be included
    #include "NiloURPSurfaceShaderInclude.hlsl"
    #include "UnityCG.hlsl"

    #include "NiloPBRLitCelShadeLightingFunction.hlsl"

    #pragma shader_feature _NORMALMAP 
    #pragma shader_feature _ _IsSelected

    TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
    TEXTURE2D(_BumpMap);        SAMPLER(sampler_BumpMap);
    TEXTURE2D(_WindVectors);        SAMPLER(sampler_WindVectors);
    
    //ST
    float4 _WindVectors_ST;
    

    CBUFFER_START(UnityPerMaterial)

    uniform float _WindAmplitudeMultiplier, _WindAmplitude, _WindSpeed;
    uniform float4 _WindDirection;
    uniform float _UseSpeedTreeWind;
    uniform float _MaxWindStrength, _WindStrength;
    uniform float _TrunkWindSpeed, _TrunkWindSwinging, _TrunkWindWeight;
    uniform float _FlatLighting;
    uniform float _GradientBrightness;
    uniform float4 _HueVariation;
    uniform float4 _BaseColor, _TransmissionColor;
    uniform float _Smoothness, _AmbientOcclusion;
    uniform float _Cutoff = 0.5;

    CBUFFER_END
    
    uniform float _WindDebug;

    //IMPORTANT: write your surface shader's vertex logic here
    //you ONLY need to re-write things that you want to change, you don't need to fill in all data inside UserGeometryOutputData!
    //All unedited data inside UserGeometryOutputData will always use it's default value, just like shader graph's master node's default values.
    //see struct UserGeometryOutputData inside NiloURPSurfaceShaderInclude.hlsl for all editable data and default values
    //copy the whole UserGeometryOutputData struct here for your reference
    /*
    //100% same as URP PBR shader graph's vertex input
    struct UserGeometryOutputData
    {
        float3 positionOS;
        float3 normalOS;
        float4 tangentOS;
    };
    */
    void UserGeometryDataOutputFunction(Attributes IN, inout UserGeometryOutputData geometryOutputData, bool isExtraCustomPass)
    {
        float3 positionWS = mul(unity_ObjectToWorld, IN.positionOS.xyz);
        float windTimeOffset = ((_WindSpeed * 0.05) * _Time.w);
        float2 windDirectionXZ = (float2(_WindDirection.x , _WindDirection.z));

        float3 windVectors = UnpackNormal(
            SAMPLE_TEXTURE2D_LOD( 
                _WindVectors,
                sampler_WindVectors,
                (_WindAmplitudeMultiplier * _WindAmplitude * (positionWS.xz * 0.01) +  windTimeOffset * windDirectionXZ).xy,
                0
            )
        );

        float3 objectScale = float3(length(unity_ObjectToWorld[0].xyz), length(unity_ObjectToWorld[1].xyz), length(unity_ObjectToWorld[2].xyz));
        float3 windDirectionX0Z = (float3(_WindDirection.x , 0.0 , _WindDirection.z));
        float3 _Vector2 = float3(1,1,1);
        // 关掉顶点色alpha通道对摆动的影响
        float3 windSwingOffset = (((float3(0,0,0) + (sin(((windTimeOffset * (_TrunkWindSpeed / objectScale)) * windDirectionX0Z)) - (float3(-1,-1,-1) + _TrunkWindSwinging)) * (_Vector2 - float3(0,0,0)) / (_Vector2 - (float3(-1,-1,-1) + _TrunkWindSwinging ))) * _TrunkWindWeight ) * lerp(0, (IN.uv2.y * 0.01 ), _UseSpeedTreeWind));
        float3 windSwingOffsetX0Z = (float3(windSwingOffset.x , 0.0 , windSwingOffset.z));
        float3 windOffset = (((windVectors * lerp(IN.color.g, IN.uv3.x, _UseSpeedTreeWind)) * _MaxWindStrength * _WindStrength) + windSwingOffsetX0Z);
        geometryOutputData.positionOS.xyz += windOffset;

        float3 normalOS = IN.normalOS.xyz;
        float3 _Vector0 = float3(0,1,0);
        float3 lerpNormal = lerp(normalOS , _Vector0 , _FlatLighting);
        geometryOutputData.normalOS = lerpNormal;
    
        float3 worldLightDir = normalize(UnityWorldSpaceLightDir(positionWS));
        float3 worldViewDir = normalize(UnityWorldSpaceViewDir(positionWS));
        float LdotV = dot(worldLightDir, (1.0 - worldViewDir));
        float4 lightColor = _MainLightColor;
        geometryOutputData.uv34 = ((((0.0 + (LdotV - -1.0) * (1.0 - 0.0) / (1.0 - -1.0)) * IN.color.b) * _TransmissionColor.a) * (_TransmissionColor * lightColor));
    }

    //MOST IMPORTANT: write your surface shader's fragment logic here
    //you ONLY need re-write things that you want to change, you don't need to fill in all data inside UserSurfaceOutputData!
    //All unedited data inside UserSurfaceOutputData will always use it's default value, just like shader graph's master node's default values.
    //see struct UserSurfaceOutputData inside NiloURPSurfaceShaderInclude.hlsl for all editable data and their default values 
    //copy the whole UserSurfaceOutputData struct here for your reference
    /*
    //100% same as URP PBR shader graph's fragment input
    struct UserSurfaceOutputData
    {
        half3   albedo;             
        half3   normalTS;          
        half3   emission;     
        half    metallic;
        half    smoothness;
        half    occlusion;                
        half    alpha;          
        half    alphaClipThreshold;
    };
    */
    void UserSurfaceOutputDataFunction(Varyings i, inout UserSurfaceOutputData o, bool isExtraCustomPass)
    {
        float2 uv = i.uv;
        float2 uv2 = i.uv2;
        o.normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uv));
        float4 mainColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, uv) * _BaseColor;
        float4 lerpColor = lerp((_GradientBrightness * mainColor), mainColor, lerp(saturate((i.color.a * 10.0)), (0.1 * uv2.y), _UseSpeedTreeWind));
        float4 positionWS_0 = mul(unity_ObjectToWorld, float4(0,0,0,1));
        float4 colorResult = saturate(lerp(lerpColor , _HueVariation , ( _HueVariation.a * frac(((positionWS_0.x + positionWS_0.y) + positionWS_0.z)))));
        float3 positionWS = i.positionWSAndFogFactor.xyz;

        float windTimeOffset = (( _WindSpeed * 0.05) * _Time.w);
        float2 windDirectionXZ = (float2(_WindDirection.x , _WindDirection.z));
        float3 windVectors = UnpackNormal( SAMPLE_TEXTURE2D( _WindVectors, sampler_WindVectors, (( _WindAmplitudeMultiplier * _WindAmplitude * ((positionWS).xz * 0.01 )) + (windTimeOffset * windDirectionXZ))));
        float4 debugTemp = lerp(colorResult, float4(windVectors, 0.0) , _WindDebug);
        o.albedo = debugTemp.rgb;
        float4 sss = i.uv34;
        o.emission = sss.rgb;
        o.smoothness = _Smoothness;
        float ao = lerp(1.0, 0.0, (_AmbientOcclusion * (1.0 - i.color.r)));
        o.occlusion = ao;
        o.alpha = 1;
        float mainAlpha = mainColor.a;
        float debugAlpha = lerp(mainAlpha, 1.0, _WindDebug);
        clip(debugAlpha - _Cutoff);
    }

    //IMPORTANT: write your final fragment color edit logic here
    //usually for gameplay logic's color override or darken, like "loop: lerp to red" for selectable targets / flash white on taking damage / darken dead units...
    //you can replace this function by a #include "Your_own_hlsl.hlsl" call, to share this function between different surface shaders
    void FinalPostProcessFrag(Varyings IN, UserSurfaceOutputData surfaceData, FAELightingData lightingData, inout half4 inputColor)
    {
//#if _IsSelected
//        inputColor.rgb = lerp(inputColor.rgb,_SelectedLerpColor.rgb, _SelectedLerpColor.a * (sin(_Time.y * 5) * 0.5 + 0.5));
//#endif
    }

    ENDHLSL

    SubShader
    {
        Tags 
        { 
            "RenderPipeline"="UniversalRenderPipeline"
            "RenderType" = "Opaque"
            "Queue" = "AlphaTest+0" 
            "IsEmissive" = "true"
        }

        //UniversalForward pass
        Pass
        {
            Name "Universal Forward"
            Tags { "LightMode"="UniversalForward" }

            //__________________________________________[User editable section]__________________________________________\\
            ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
            //You can edit per Pass Render State here as usual
            //doc: https://docs.unity3d.com/Manual/SL-Pass.html
            
            Cull Off
            ZTest LEqual

            HLSLPROGRAM
            #pragma vertex vertUniversalForward
            #pragma fragment fragUniversalForward
            ENDHLSL
        }

 
        //__________________________________________[User editable section]__________________________________________\\
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
        //User can insert 1 extra custom passes here.
        //For example, an outline pass this time

        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
          
        //ShadowCaster pass, for rendering this shader into URP's shadowmap renderTextures
        //User should not need to edit this pass in most cases
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }
            ColorMask 0 //optimization: ShadowCaster pass don't care fragment shader output value, disable color write to reduce bandwidth usage

            HLSLPROGRAM

            #pragma vertex vertShadowCaster
            #pragma fragment fragDoAlphaClipOnlyAndEarlyExit

            ENDHLSL
        }

        //DepthOnly pass, for rendering this shader into URP's _CameraDepthTexture
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode"="DepthOnly" }
            ColorMask 0 //optimization: DepthOnly pass don't care fragment shader output value, disable color write to reduce bandwidth usage

            HLSLPROGRAM

            //__________________________________________[User editable section]__________________________________________\\
            ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
            //not using vertUniversalForward function due to outline pass edited positionOS by bool isExtraCustomPass in UserGeometryDataOutputFunction(...)
            //#pragma vertex vertUniversalForward

            //we use this instead, this will inlcude positionOS change in UserGeometryDataOutputFunction, include isExtraCustomPass(outlinePass)'s vertex logic.
            //we only do this due to the fact that this shader's extra pass is an opaque outline pass
            //where opaque outline should affacet depth write also
            #pragma vertex vertExtraCustomPass
            ///////////////////////////////////////////////////////////////////////////////////////////////////////////////

            #pragma fragment fragDoAlphaClipOnlyAndEarlyExit

            ENDHLSL
        }
    }
}