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
Shader "FAE/Tree Branch"
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
		//
		[HideInInspector] _TrunkWindSpeed( "_TrunkWindSpeed", float ) = 1.0
		[HideInInspector] _TrunkWindSwinging( "_TrunkWindSwinging", float ) = 1.0
		[HideInInspector] _TrunkWindWeight( "_TrunkWindWeight", float ) = 1.0
		[HideInInspector] _WindAmplitude( "_WindAmplitude", float ) = 1.0
		[HideInInspector] _WindSpeed( "_WindSpeed", float ) = 1.0
		[HideInInspector] _WindStrength( "_WindStrength", float ) = 1.0
		[HideInInspector] _WindDirection( "_WindDirection", Vector) = (0,0,0,0)
		//[HideInInspector] _WindDebug( "_WindDebug", float ) = 1.0
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
    #include "NiloURPSurfaceShaderInclude.hlsl"
    #include "UnityCG.hlsl"

    //__________________________________________[User editable section]__________________________________________\\
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //first, select a lighting function = a .hlsl which contains the concrete body of CalculateSurfaceFinalResultColor(...)
    //you can select any .hlsl you want here, default is NiloPBRLitCelShadeLightingFunction.hlsl, you can always change it
    #include "NiloPBRLitCelShadeLightingFunction.hlsl"
    //#include "../LightingFunctionLibrary/NiloPBRLitLightingFunction.hlsl"
    //#include "..........YourOwnLightingFunction.hlsl" //you can always write your own!

    //put your custom #pragma here as usual
    #pragma shader_feature _NORMALMAP 
    #pragma shader_feature _ _IsSelected



    struct Input
    {
        float3 worldPos;
        float2 uv_texcoord;
        float4 vertexColor : COLOR;
        float2 uv2_texcoord2;
        float4 vertexToFrag332;
    };

    TEXTURE2D(_WindVectors);
    SAMPLER(sampler_WindVectors);
    TEXTURE2D(_BumpMap);
    SAMPLER(sampler_BumpMap);
    TEXTURE2D(_MainTex);
    SAMPLER(sampler_MainTex);
    
    //ST
    float4 _WindVectors_ST;
    
    //you must write all your per material uniforms inside this CBUFFER to make SRP batcher compatible
    CBUFFER_START(UnityPerMaterial)
    //ST

    uniform float _WindAmplitudeMultiplier;
    uniform float _WindAmplitude;
    uniform float _WindSpeed;
    uniform float4 _WindDirection;
    uniform float _UseSpeedTreeWind;
    uniform float _MaxWindStrength;
    uniform float _WindStrength;
    uniform float _TrunkWindSpeed;
    uniform float _TrunkWindSwinging;
    uniform float _TrunkWindWeight;
    uniform float _FlatLighting;
    uniform float _GradientBrightness;
    uniform float4 _HueVariation;
    uniform float4 _TransmissionColor;
    uniform float4 _BaseColor;
    uniform float _Smoothness;
    uniform float _AmbientOcclusion;
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
        float3 ase_worldPos = mul( unity_ObjectToWorld, IN.positionOS.xyz );
        float temp_output_60_0 = ( ( _WindSpeed * 0.05 ) * _Time.w );
        float2 appendResult249 = (float2(_WindDirection.x , _WindDirection.z));
//        float3 WindVectors99 = float3(0,0,0);
        float3 WindVectors99 = UnpackNormal(
            SAMPLE_TEXTURE2D_LOD( 
                _WindVectors,
                sampler_WindVectors,
                (_WindAmplitudeMultiplier * _WindAmplitude * ( ase_worldPos.xz * 0.01 ) +  temp_output_60_0 * appendResult249).xy,
                0
            )
        );

        float3 ase_objectScale = float3( length( unity_ObjectToWorld[ 0 ].xyz ), length( unity_ObjectToWorld[ 1 ].xyz ), length( unity_ObjectToWorld[ 2 ].xyz ) );
        float3 appendResult250 = (float3(_WindDirection.x , 0.0 , _WindDirection.z));
        float3 _Vector2 = float3(1,1,1);
        //float3 break282 = ( ( (float3( 0,0,0 ) + (sin( ( ( temp_output_60_0 * ( _TrunkWindSpeed / ase_objectScale ) ) * appendResult250 ) ) - ( float3(-1,-1,-1) + _TrunkWindSwinging )) * (_Vector2 - float3( 0,0,0 )) / (_Vector2 - ( float3(-1,-1,-1) + _TrunkWindSwinging ))) * _TrunkWindWeight ) * lerp(IN.color.a,( IN.uv2.y * 0.01 ),_UseSpeedTreeWind) );
        // 关掉顶点色alpha通道对摆动的影响
        float3 break282 = ( ( (float3( 0,0,0 ) + (sin( ( ( temp_output_60_0 * ( _TrunkWindSpeed / ase_objectScale ) ) * appendResult250 ) ) - ( float3(-1,-1,-1) + _TrunkWindSwinging )) * (_Vector2 - float3( 0,0,0 )) / (_Vector2 - ( float3(-1,-1,-1) + _TrunkWindSwinging ))) * _TrunkWindWeight ) * lerp(0,( IN.uv2.y * 0.01 ),_UseSpeedTreeWind) );
        float3 appendResult283 = (float3(break282.x , 0.0 , break282.z));
        float3 Wind17 = ( ( ( WindVectors99 * lerp(IN.color.g,IN.uv3.x,_UseSpeedTreeWind) ) * _MaxWindStrength * _WindStrength ) + appendResult283 );
        geometryOutputData.positionOS.xyz += Wind17;
        float3 ase_vertexNormal = IN.normalOS.xyz;
        float3 _Vector0 = float3(0,1,0);
        float3 lerpResult94 = lerp( ase_vertexNormal , _Vector0 , _FlatLighting);
        geometryOutputData.normalOS = lerpResult94;
        float3 ase_worldlightDir = normalize( UnityWorldSpaceLightDir( ase_worldPos ) );
        float3 normalizeResult236 = normalize( ase_worldlightDir );
        float3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
        float dotResult36 = dot( normalizeResult236 , ( 1.0 - ase_worldViewDir ) );
        float4 ase_lightColor = _MainLightColor;
        geometryOutputData.uv34 = ( ( ( (0.0 + (dotResult36 - -1.0) * (1.0 - 0.0) / (1.0 - -1.0)) * IN.color.b ) * _TransmissionColor.a ) * ( _TransmissionColor * ase_lightColor ) );
//        geometryOutputData.positionOS += sin(_Time.y * dot(float3(1,1,1),geometryOutputData.positionOS) * 10) * _NoiseStrength * 0.0125; //random sin() vertex anim
//
//        if(isExtraCustomPass)
//        {
//            geometryOutputData.positionOS += geometryOutputData.normalOS *_OutlineWidthOS * 0.025; //outline pass needs to enlarge mesh
//        }

        //No need to write all other geometryOutputData.XXX if you don't want to edit them.
        //They will use default value instead
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
        float2 uv_texcoord = i.uv;
        float2 uv2_texcoord2 = i.uv2;
        float2 uv_BumpMap62 = uv_texcoord;
        o.normalTS = UnpackNormal( SAMPLE_TEXTURE2D( _BumpMap,sampler_BumpMap, uv_BumpMap62 ) );
        float2 uv_MainTex19 = uv_texcoord;
        float4 tex2DNode19 = SAMPLE_TEXTURE2D( _MainTex,sampler_MainTex, uv_MainTex19 )*_BaseColor;
        float4 lerpResult246 = lerp( ( _GradientBrightness * tex2DNode19 ) , tex2DNode19 , lerp(saturate( ( i.color.a * 10.0 ) ),( 0.1 * uv2_texcoord2.y ),_UseSpeedTreeWind));
        float4 transform204 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
        float4 lerpResult20 = lerp( lerpResult246 , _HueVariation , ( _HueVariation.a * frac( ( ( transform204.x + transform204.y ) + transform204.z ) ) ));
        float4 Color56 = saturate( lerpResult20 );
        float3 ase_worldPos = i.positionWSAndFogFactor.xyz;
        float temp_output_60_0 = ( ( _WindSpeed * 0.05 ) * _Time.w );
        float2 appendResult249 = (float2(_WindDirection.x , _WindDirection.z));
        float3 WindVectors99 = UnpackNormal( SAMPLE_TEXTURE2D( _WindVectors,sampler_WindVectors, ( ( _WindAmplitudeMultiplier * _WindAmplitude * ( (ase_worldPos).xz * 0.01 ) ) + ( temp_output_60_0 * appendResult249 ) ) ) );
        float4 lerpResult97 = lerp( Color56 , float4( WindVectors99 , 0.0 ) , _WindDebug);
        o.albedo = lerpResult97.rgb;
        float4 SSS45 = i.uv34;
        o.emission = SSS45.rgb;
        o.smoothness = _Smoothness;
        float lerpResult53 = lerp( 1.0 , 0.0 , ( _AmbientOcclusion * ( 1.0 - i.color.r ) ));
        float AmbientOcclusion218 = lerpResult53;
        o.occlusion = AmbientOcclusion218;
        o.alpha = 1;
        float Alpha31 = tex2DNode19.a;
        float lerpResult101 = lerp( Alpha31 , 1.0 , _WindDebug);
        clip( lerpResult101 - _Cutoff );

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
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////

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