//see doc here: https://github.com/ColinLeung-NiloCat/UnityURP-SurfaceShaderSolution

//In user's perspective, this "URP surface shader" .shader file: 
//- must be just one regular .shader file
//- must be as short as possible, user should only need to care & write surface function, no lighting related code should be exposed to user
//- must not contain any lighting related concrete code in this file, user should only need to "edit one line" selecting a reusable lighting function .hlsl.
//- must be always SRP batcher compatible if user write uniforms in CBUFFER correctly
//- must be able to do everything that shader graph can already do
//- must support DepthOnly & ShadowCaster pass with minimum code
//- must support atleast 1 extra custom pass(e.g. outline pass) with minimum code
//- must be "very easy to use & flexible", even if performance cost is higher
//- (future update)this file must be a template file that can be created using unity's editor GUI (right click in project window, Create/Shader/URPSurfaceShader)

//*** Inside this file, user should only care sections with [User editable section] tag, other code can be ignored by user in most cases ***

//__________________________________________[User editable section]__________________________________________\\
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//change this line to any unique path you like, so you can pick this shader in material's shader dropdown menu
Shader "Babeitime/Scene/AnimatedFire"
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
{
    Properties
    {
        //__________________________________________[User editable section]__________________________________________\\
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
        //-Write all per material settings here, just like a regular .shader.
        //-In order to make SRP batcher compatible,
        //make sure to match all uniforms inside CBUFFER_START(UnityPerMaterial) in the next [User editable section]
        
        //below are just some example use case Properties, you can write whatever you want here
//        [Header(BaseColor)]
//        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)
//        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
//
//        [Header(Alpha)]
//        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
//
//        //Metallic workflow
//        [Header(Metallic)]
//        [Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
//
//        [Header(Smoothness)]
//        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
//
//        [Header(NormalMap)]
//        [Toggle(_NORMALMAP)]_NORMALMAP("_NORMALMAP?", Float) = 1
//        _BumpMap("Normal Map", 2D) = "bump" {}
//        _BumpScale("Scale", Float) = 1.0
//
//        [Header(SharedDataTexture)]
//        _MetallicR_OcclusionG_SmoothnessA_Tex("_MetallicR_OcclusionG_SmoothnessA_Tex", 2D) = "white" {}
//
//        [Header(Emission)]
//        [HDR]_EmissionColor("Color", Color) = (0,0,0)
//        _EmissionMap("Emission", 2D) = "white" {}

        //==================================================
        // custom data
        //==================================================
//        [Header(Example_GameplayUse_FinalColorOverride)]
//        [Toggle(_IsSelected)]_IsSelected("_IsSelected?", Float) = 0
//        [HDR]_SelectedLerpColor("_SelectedLerpColor", Color) = (1,0,0,0.8)
//
//        [Header(VertAnim)]
//        _NoiseStrength("_NoiseStrength", Range(-4,4)) = 1
//        [Header(Outline)]
//        _OutlineWidthOS("_OutlineWidthOS", Range(0,4)) = 1
        _Albedo("Albedo", 2D) = "white" {}
        _Normals("Normals", 2D) = "bump" {}
        _Specular("Specular", 2D) = "white" {}
        _Mask("Mask", 2D) = "white" {}
		_TileableFire("TileableFire", 2D) = "white" {}
		_FireIntensity("FireIntensity", Range( 0 , 5)) = 0
		_Smoothness("Smoothness", Float) = 1
		_TileSpeed("TileSpeed", Vector) = (0,0,0,0)
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    }

    HLSLINCLUDE

    //this section are shader_feature keywords set by unity:
    //-Sadly there seems to be no way to hide #pragma from user, 
    // so shader_feature must be copied to every .shader due to shaderlab's design,
    // which makes updating this section in future almost impossible once users already produced lots of .shader files
    //-The good part is exposing multi_compiles which makes editing by user possible, 
    // but it contradict with the goal of surface shader - "hide lighting implementation from user"
    //==================================================================================================================
    //copied URP shader_feature note from Felipe Lira's UniversalPipelineTemplateShader.shader
    //https://gist.github.com/phi-lira/225cd7c5e8545be602dca4eb5ed111ba

    // Universal Render Pipeline keywords
    // When doing custom shaders you most often want to copy and paste these #pragmas,
    // These shader_feature variants are stripped from the build depending on:
    // 1) Settings in the URP Asset assigned in the GraphicsSettings at build time
    // e.g If you disable AdditionalLights in the asset then all _ADDITIONA_LIGHTS variants
    // will be stripped from build
    // 2) Invalid combinations are stripped. e.g variants with _MAIN_LIGHT_SHADOWS_CASCADE
    // but not _MAIN_LIGHT_SHADOWS are invalid and therefore stripped.

    //100% copied from URP PBR shader graph's generated code
    // Pragmas
    #pragma prefer_hlslcc gles
    #pragma exclude_renderers d3d11_9x
    #pragma target 2.0
    #pragma multi_compile_fog
    #pragma multi_compile_instancing

    //100% copied from URP PBR shader graph's generated code
    // Keywords
    #pragma shader_feature _ LIGHTMAP_ON
    #pragma shader_feature _ DIRLIGHTMAP_COMBINED
    #pragma shader_feature _ _MAIN_LIGHT_SHADOWS
    #pragma shader_feature _ _MAIN_LIGHT_SHADOWS_CASCADE
    #pragma shader_feature _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
    #pragma shader_feature _ _ADDITIONAL_LIGHT_SHADOWS
    #pragma shader_feature _ _SHADOWS_SOFT
    #pragma shader_feature _ _MIXED_LIGHTING_SUBTRACTIVE
    //==================================================================================================================


    //the core .hlsl of the whole URP surface shader structure, must be included
    #include "../NiloURPSurfaceShaderInclude.hlsl"


    //__________________________________________[User editable section]__________________________________________\\
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //first, select a lighting function = a .hlsl which contains the concrete body of CalculateSurfaceFinalResultColor(...)
    //you can select any .hlsl you want here, default is NiloPBRLitCelShadeLightingFunction.hlsl, you can always change it
    #include "../NiloPBRLitCelShadeLightingFunction.hlsl"
    //#include "../LightingFunctionLibrary/NiloPBRLitLightingFunction.hlsl"
    //#include "..........YourOwnLightingFunction.hlsl" //you can always write your own!

    //put your custom #pragma here as usual
    #pragma shader_feature _NORMALMAP 
    #pragma shader_feature _ _IsSelected

		
    TEXTURE2D(_Albedo);
    SAMPLER(sampler_Albedo);
    TEXTURE2D(_Normals);
    SAMPLER(sampler_Normals);
    TEXTURE2D(_Specular);
    SAMPLER(sampler_Specular);
    TEXTURE2D(_Mask);
    SAMPLER(sampler_Mask);
    TEXTURE2D(_TileableFire);
    SAMPLER(sampler_TileableFire);
    TEXTURE2D(_texcoord);
    SAMPLER(sampler_texcoord);


    

    //you must write all your per material uniforms inside this CBUFFER to make SRP batcher compatible
    CBUFFER_START(UnityPerMaterial)
    float4 _Albedo_ST;
    float4 _TileSpeed;
    float _FireIntensity;
    float4 _Specular_ST;
//    half _Metallic;
    half _Smoothness;
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
        float2 uv = TRANSFORM_TEX(IN.uv, _Albedo);
        half4 color = SAMPLE_TEXTURE2D(_Albedo, sampler_Albedo, uv) * half4(0,0,0,1);
        surfaceData.albedo = color.rgb;
        surfaceData.alpha = color.a;
        surfaceData.normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_Albedo, sampler_Albedo, uv), 1);
        float2 panner16 = ( _Time.w * _TileSpeed + IN.uv);
        surfaceData.emission = ( ( SAMPLE_TEXTURE2D( _Mask, sampler_Mask, uv ) * SAMPLE_TEXTURE2D( _TileableFire,sampler_TileableFire, panner16 ) ) * ( _FireIntensity * ( unity_DeltaTime.x + 1.5 ) ) ).rgb;
        float2 uv_Specular = IN.uv * _Specular_ST.xy + _Specular_ST.zw;
        surfaceData.specular = SAMPLE_TEXTURE2D( _Specular,sampler_Specular, uv_Specular ).rgb;
        surfaceData.smoothness = _Smoothness;
        surfaceData.alpha = 1;

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
            "Queue" = "Geometry+0" 
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
            
            Cull Back
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