Shader "Babeitime/Scene/ Mirror"
{
    Properties
    {
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
		_BlendLevel("Main Material Blend Level",Range(0,1))=1
		_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		_Shininess ("Shininess", Range (0.03, 1)) = 0.078125
		_BumpMap ("Normalmap", 2D) = "bump" {}
		_Bumpness ("Bump Rate",Range(0,1))= 0.5
		_Ref ("For Mirror reflection,don't set it!", 2D) = "white" {}
		_RefColor("Reflection Color",Color) = (1,1,1,1)
		_RefRate ("Reflective Rate", Range (0, 1)) = 1
		_Distortion ("Reflective Distortion", Range (0, 1)) = 0
    }

    HLSLINCLUDE

    #pragma prefer_hlslcc gles
    #pragma exclude_renderers d3d11_9x
    #pragma target 2.0
    #pragma multi_compile_fog
    #pragma multi_compile_instancing

    #pragma shader_feature _ LIGHTMAP_ON
    #pragma shader_feature _ DIRLIGHTMAP_COMBINED
    #pragma shader_feature _ _MAIN_LIGHT_SHADOWS
    #pragma shader_feature _ _MAIN_LIGHT_SHADOWS_CASCADE
    #pragma shader_feature _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
    #pragma shader_feature _ _ADDITIONAL_LIGHT_SHADOWS
    #pragma shader_feature _ _SHADOWS_SOFT
    #pragma shader_feature _ _MIXED_LIGHTING_SUBTRACTIVE


    #include "../NiloURPSurfaceShaderInclude.hlsl"
    #include "../NiloPBRLitCelShadeLightingFunction.hlsl"
    //#include "../LightingFunctionLibrary/NiloPBRLitLightingFunction.hlsl"
    //#include "..........YourOwnLightingFunction.hlsl" //you can always write your own!

    //put your custom #pragma here as usual
    #pragma shader_feature _NORMALMAP 
    #pragma shader_feature _ _IsSelected

    //define texture & sampler as usual
    TEXTURE2D(_MainTex);
    SAMPLER(sampler_MainTex);
    TEXTURE2D(_BumpMap);
    SAMPLER(sampler_BumpMap);
    TEXTURE2D(_Ref);
    SAMPLER(sampler_Ref);


    //you must write all your per material uniforms inside this CBUFFER to make SRP batcher compatible
    CBUFFER_START(UnityPerMaterial)
    float4 _MainTex_ST;
    float4 _BumpMap_ST;
    float4 _Ref_ST;
    half4 _Color;
    half _Shininess;
    half _RefRate;
    half _Bumpness;
    half _BlendLevel;
    half _Distortion;
    half4 _RefColor;
//    float4 _BaseMap_ST;
//    half4 _BaseColor;
//    half _Metallic;
//    half _Smoothness;
//    half _BumpScale;
//    half4 _EmissionColor;
//    half _Cutoff;
//    float _OutlineWidthOS;
//    half4 _SelectedLerpColor;
//    float _NoiseStrength;
    CBUFFER_END

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
        VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS.xyz);
        geometryOutputData.uv34 = ComputeScreenPos (vertexInput.positionCS);
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
    void UserSurfaceOutputDataFunction(Varyings IN, inout UserSurfaceOutputData surfaceData, bool isExtraCustomPass)
    {
        float2 uv_BumpMap = TRANSFORM_TEX(IN.uv, _BumpMap);
		half3 nor = UnpackNormal (SAMPLE_TEXTURE2D(_BumpMap,sampler_BumpMap, uv_BumpMap));
        float2 uv_MainTex = TRANSFORM_TEX(IN.uv, _MainTex);
		half4 tex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, uv_MainTex);
		float2 screenUV = IN.uv34.xy / IN.uv34.w;
		screenUV += nor.xy * _Distortion;
		half4 ref = SAMPLE_TEXTURE2D(_Ref,sampler_Ref, screenUV);
		surfaceData.albedo = tex.rgb * _Color.rgb * _BlendLevel;
		surfaceData.emission = ref.rgb * _RefColor.rgb * _RefRate;
		surfaceData.normalTS = nor.rgb * _Bumpness;
        surfaceData.smoothness = tex.a;
		surfaceData.alpha = tex.a * _Color.a;
		surfaceData.specular = _Shininess;
    }

    //IMPORTANT: write your final fragment color edit logic here
    //usually for gameplay logic's color override or darken, like "loop: lerp to red" for selectable targets / flash white on taking damage / darken dead units...
    //you can replace this function by a #include "Your_own_hlsl.hlsl" call, to share this function between different surface shaders
    void FinalPostProcessFrag(Varyings IN, UserSurfaceOutputData surfaceData, LightingData lightingData, inout half4 inputColor)
    {

    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////

    ENDHLSL

    SubShader
    {
        Tags 
        { 
            "RenderPipeline"="UniversalRenderPipeline"
            "RenderType" = "Opaque"
        }

        Pass
        {
            Name "Universal Forward"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vertUniversalForward
            #pragma fragment fragUniversalForward
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }
            ColorMask 0 
            HLSLPROGRAM

            #pragma vertex vertShadowCaster
            #pragma fragment fragDoAlphaClipOnlyAndEarlyExit

            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode"="DepthOnly" }
            ColorMask 0 
            HLSLPROGRAM
            #pragma vertex vertExtraCustomPass
            #pragma fragment fragDoAlphaClipOnlyAndEarlyExit

            ENDHLSL
        }
    }
}