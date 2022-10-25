Shader "FAE/Grass"
{
    Properties
    {
        _Test( "_Test", Float ) = 0.5
		_Cutoff( "Mask Clip Value", Float ) = 0.5
		_ColorTop("ColorTop", Color) = (0.3001064,0.6838235,0,1)
		_ColorBottom("Color Bottom", Color) = (0.232,0.5,0,1)
		[NoScaleOffset]_MainTex("MainTex", 2D) = "white" {}
		[NoScaleOffset][Normal]_BumpMap("BumpMap", 2D) = "bump" {}
		_ColorVariation("ColorVariation", Range( 0 , 0.2)) = 0.05
		_AmbientOcclusion("AmbientOcclusion", Range( 0 , 1)) = 0
		_TransmissionSize("Transmission Size", Range( 0 , 20)) = 1
		_TransmissionAmount("Transmission Amount", Range( 0 , 10)) = 2.696819
		_MaxWindStrength("Max Wind Strength", Range( 0 , 1)) = 0.126967
		_WindSwinging("WindSwinging", Range( 0 , 1)) = 0.25
		_WindAmplitudeMultiplier("WindAmplitudeMultiplier", Float) = 1
		_HeightmapInfluence("HeightmapInfluence", Range( 0 , 1)) = 0
		_MinHeight("MinHeight", Range( -1 , 0)) = -0.5
		_MaxHeight("MaxHeight", Range( -1 , 1)) = 0
		_BendingInfluence("BendingInfluence", Range( 0 , 1)) = 0
		_TouchBendingStrength("PushStrength", Range(0, 5)) = 0.5
		_TouchBendingRadius("PushSize", Range(0, 10)) = 1
		_PigmentMapInfluence("PigmentMapInfluence", Range( 0 , 1)) = 0
		_PigmentMapHeight("PigmentMapHeight", Range( 0 , 1)) = 0
		_BendingTint("BendingTint", Range( -0.1 , 0.1)) = -0.05
		_Shadow_Atten("_Shadow_Atten", Range( 0 , 1)) = 0.58
		
		[Toggle(_VS_TOUCHBEND_ON)] _VS_TOUCHBEND("VS_TOUCHBEND", Float) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty("", Int) = 1
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

		
//		struct Input
//		{
//			float3 worldPos;
//			float2 uv_texcoord;
//			float4 vertexColor : COLOR;
//			float2 uv2_texcoord2;
//			float4 vertexToFrag332;
//		};
//
//		struct SurfaceOutputCustomLightingCustom
//		{
//			half3 Albedo;
//			half3 Normal;
//			half3 Emission;
//			half Metallic;
//			half Smoothness;
//			half Occlusion;
//			half Alpha;
//			Input SurfInput;
//			UnityGIInput GIData;
//		};


		uniform float _WindStrength;
		uniform float _WindAmplitude;
		uniform float _WindSpeed;
		uniform float4 _WindDirection;
		uniform float4 _ObstaclePosition;
		uniform float _BendingStrength;
		uniform float _BendingRadius;
		uniform float4 _TerrainUV;
		uniform float _WindDebug;
		float4 _TouchReact_Pos;
		uniform float3 _PlayerPosition;

        TEXTURE2D(_WindVectors);                //LongZhu\LongZhuDemo\Assets\Fantasy Adventure Environment 
        SAMPLER(sampler_WindVectors);
        TEXTURE2D(_PigmentMap);                 //rgb=goundColor; a=HeightMap 
        SAMPLER(sampler_PigmentMap);
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_BumpMap);
        SAMPLER(sampler_BumpMap);
        TEXTURE2D(_TouchReact_Buffer);
        SAMPLER(sampler_TouchReact_Buffer);

    //you must write all your per material uniforms inside this CBUFFER to make SRP batcher compatible
    CBUFFER_START(UnityPerMaterial)
		uniform float _Cutoff = 0.5;
		uniform float _Test = 0.5;
		uniform float4 _ColorTop;
		uniform float4 _ColorBottom;
		uniform float _ColorVariation;
        uniform float _AmbientOcclusion;
        uniform float _TransmissionSize;
        uniform float _TransmissionAmount;
        uniform float _MaxWindStrength;
        uniform float _WindSwinging;
        uniform float _WindAmplitudeMultiplier;
        uniform float _HeightmapInfluence;
        uniform float _MinHeight;
        uniform float _MaxHeight;
        uniform float _BendingInfluence;
        // 草被压倒相关
		uniform float _TouchBendingStrength;
        uniform float _TouchBendingRadius;
        uniform float _PigmentMapInfluence;
        uniform float _PigmentMapHeight;
        uniform float _BendingTint;
        uniform float _Shadow_Atten;
    CBUFFER_END

		// 顶点阶段: 在世界坐标系下，处理草被压倒的偏移，输入草顶点，输出被压后的位置。
		inline float4 CalculateTouchBending(float4 vertex,half height)
		{
			float3 current = _PlayerPosition;
			//current.y += _TouchBendingRadius;

			if (distance(vertex.xyz, current.xyz) < _TouchBendingRadius)
			{
				float WMDistance = 1 - clamp(distance(vertex.xyz, current.xyz) / _TouchBendingRadius, 0, 1);
				float3 posDifferences = normalize(vertex.xyz - current.xyz);

				float3 strengthedDifferences = posDifferences * _TouchBendingStrength * 2;

				float3 resultXZ = WMDistance * strengthedDifferences;

				vertex.xz += resultXZ.xz*height;
				vertex.y -= WMDistance * _TouchBendingStrength*height;

				return vertex;
			}

			return vertex;
		}
		// 该方法也是处理bending的，只不过是在模型空间中计算（默认入参为模型空间中顶点）
        // 该方法在vert和frag中都有应用，vert里是典型的影响物体模型空间Y轴高度；frag中则是控制弯曲时的tint col 
        // TODO: 是否可以和上面的 CalculateTouchBending 一起简并处理 
		float3 TouchReactAdjustVertex(float3 pos) 
		{
		   float3 worldPos = mul(unity_ObjectToWorld, float4(pos,1));
		   float2 tbPos = saturate((float2(worldPos.x,-worldPos.z) - _TouchReact_Pos.xz)/_TouchReact_Pos.w);
		   float2 touchBend  = SAMPLE_TEXTURE2D_LOD(
             _TouchReact_Buffer,
             sampler_TouchReact_Buffer,
              tbPos,
              0
         );
		   touchBend.y *= 1.0 - length(tbPos - 0.5) * 2;
		   if(touchBend.y > 0.01)
		   {
		      worldPos.y = min(worldPos.y, touchBend.x * 10000);
		   }
		
		   float3 changedLocalPos = mul(unity_WorldToObject, float4(worldPos,1)).xyz;
		   return changedLocalPos - pos;
		}
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
    float3 CalculateWind(float3 pos,float3 color)
    {
        float3 worldPos = TransformObjectToWorld(pos);
        float2 windUV = float2(_WindDirection.x , _WindDirection.z);
        float3 WindWithMap = UnpackNormal(
                SAMPLE_TEXTURE2D_LOD(
                    _WindVectors, 
                    sampler_WindVectors,
                    ( ( ( (worldPos).xz * 0.01 ) * _WindAmplitudeMultiplier * _WindAmplitude ) + ( ( ( _WindSpeed * 0.05 ) * _Time.w ) * windUV ) ).xy,
                    0
                ) 
            );
        float3 WindOffset = float3(WindWithMap.x,0,WindWithMap.y);
        return lerp(( _MaxWindStrength * _WindStrength ) * WindOffset,float3( 0,0,0 ) , ( 1.0 - color.r ));
    }

    void UserGeometryDataOutputFunction(Attributes IN, inout UserGeometryOutputData geometryOutputData, bool isExtraCustomPass)
    {
        float3 ase_worldPos = mul( unity_ObjectToWorld, IN.positionOS );
        // float3 WindVector = UnpackNormal(
        //         SAMPLE_TEXTURE2D_LOD(
        //             _WindVectors, 
        //             sampler_WindVectors,  
        //             (ase_worldPos * 0.01 * _WindAmplitudeMultiplier * _WindAmplitude +  _WindSpeed * 0.05 * _Time.w * _WindDirection.xz).xy,            
        //             0
        //         ) 
        //     );
        // float3 WindVectorPlane = float3(WindVector.x , 0.0 , WindVector.y);
        // float3 WindSwingPower = lerp( ((WindVectorPlane + 1) * (float3( 1,1,0 )) / (float3( 1,1,0 ) + 1)) , WindVectorPlane , _WindSwinging);
        // 
        // float3 lerpResult74 = lerp( ( _MaxWindStrength * _WindStrength  * WindSwingPower ) , float3( 0,0,0 ) , ( 1.0 - IN.color.r ));
        
        float3 Wind = CalculateWind(IN.positionOS, IN.color);
        //障碍物的位置_ObstaclePosition

        //从当前几何顶点指向某个全局设置的障碍物坐标点(注意这里不是处理人物挤压) 
        float3 pos2obt = normalize( _ObstaclePosition.xyz - ase_worldPos );

        ///与下面向量相乘后，Y轴数据会被抹去，X和Z轴相当于乘上了固定的强度因子 
        float3 bendingStrengthX0Z = float3(_BendingStrength, 0.0 , _BendingStrength) * 0.1;
        ///弯曲强度 -> 值越小越强
        float revBendingForce = clamp( (distance(_ObstaclePosition.xyz, ase_worldPos ) / max(_BendingRadius, 0.001)), 0.0, 1.0);

        /// X-Z平面上方向投影经过逐轴向的强度影响(* bendingStrengthX0Z) 再乘以 下压强度，最后乘以一个全局的强度因子 
        half bendingFactor = -(pos2obt * bendingStrengthX0Z * (1.0 - revBendingForce) * _BendingInfluence);
        //这是障碍物形成的挤压 
        float3 Bending = IN.color.r * bendingFactor;

        //因为风和障碍物获得的顶点偏移 
        float3 compOffset = Wind + Bending; 


        ///采样大地图贴图
        float2 TerrainUV = (1.0 - _TerrainUV.zw) / _TerrainUV.x + ase_worldPos.xz / _TerrainUV.x; //TODO : rewrite this part! 
        float4 groundCol = SAMPLE_TEXTURE2D_LOD( _PigmentMap, sampler_PigmentMap, TerrainUV, 1); 
  
        float Heightmap = groundCol.a;

        ///对compOffset追加地表高度的影响 
        compOffset = lerp( compOffset, ( compOffset * Heightmap ) , _PigmentMapInfluence);


        float3 ase_vertex3Pos = IN.positionOS.xyz;
        #ifdef _VS_TOUCHBEND_ON
            float TouchBendPos = (TouchReactAdjustVertex(float4( ase_vertex3Pos , 0.0 ).xyz)).y;
        #else
            float TouchBendPos = 0.0;
        #endif

        float Yoffset = lerp( ( saturate( ((1.0 - Heightmap) - TouchBendPos) ) * _MinHeight ) , 0.0 , (1.0 - IN.color.r));
        float Ybias = lerp( _MaxHeight , 0.0 , (1.0 - IN.color.r));
        float GrassLength = Yoffset * _HeightmapInfluence + Ybias;

        float3 VertexOffset = float3(compOffset.x, GrassLength, compOffset.z);

        geometryOutputData.positionOS.xyz += VertexOffset;
        // 此处用于处理人物/角色造成的挤压 
        geometryOutputData.positionOS = mul(unity_WorldToObject, CalculateTouchBending(mul(unity_ObjectToWorld, geometryOutputData.positionOS), IN.color.x));

        geometryOutputData.normalOS = float3(0,1,0);
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
    		//去掉gi补一个参量
    		half ase_lightAtten = 1;
			float2 uv_texcoord = i.uv;
			float2 uv_MainTex = uv_texcoord;

            //采样maintex 
            half4 baseColor_raw = SAMPLE_TEXTURE2D( _MainTex, sampler_MainTex, uv_MainTex );
            //用_WindDebug参数控制镂空，用于观察wind 
            half alphaDebug = lerp(baseColor_raw.a, 1.0, _WindDebug);
            clip(alphaDebug - _Cutoff); 

            //i.color.r 是经过插值后的当前点高度比例 
            half4 colorOnHeight = lerp( _ColorTop , _ColorBottom , ( 1.0 - i.color.r ));
            //BaseColor = 贴图颜色*两个外部颜色的混合
            half4 BaseColor = (colorOnHeight * baseColor_raw);

            ///采样大地图贴图
			float3 ase_worldPos = i.positionWSAndFogFactor.xyz;
			float2 TerrainUV =   (1.0 - _TerrainUV.zw) / _TerrainUV.x  + ase_worldPos.xz / _TerrainUV.x; //TODO : rewrite this part! 
            half4 groundCol = SAMPLE_TEXTURE2D( _PigmentMap, sampler_PigmentMap, TerrainUV );

            //与地表颜色混合 
            half adjusted_height_rate = lerp( ( 1.0 - i.color.r ) , 1.0 , _PigmentMapHeight);
            half4 blendedCol = lerp(_ColorTop, groundCol, adjusted_height_rate);
            half4 PigmentMapColor = lerp(BaseColor, blendedCol, _PigmentMapInfluence);

            //采样风场 
            half2 windUV = ase_worldPos.xz * 0.01 * _WindAmplitudeMultiplier * _WindAmplitude + _WindSpeed * 0.05 * _Time.w * _WindDirection.xz;
            half3 WindVector = UnpackNormal( SAMPLE_TEXTURE2D( _WindVectors, sampler_WindVectors, windUV) );

            half WindTint = saturate( WindVector.x * WindVector.y  * i.color.r  * _ColorVariation * _WindStrength );
            
            //为什么颜色和风要有关系啊 -> 回答你:当然是为了能在"颜色"层面的视觉上也能感受到风的存在啦 
            blendedCol.xyz = PigmentMapColor.rgb + WindTint;

            //Apply simple Lit 
            half3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
            half3 ase_worldlightDir = normalize( UnityWorldSpaceLightDir( ase_worldPos ) );
            half VoL = dot( -ase_worldViewDir , ase_worldlightDir );
            half Heightmap = groundCol.a;
            half SubsurfaceIntensity = saturate( pow( max(VoL, 0.0 ) , _TransmissionSize ) * _TransmissionAmount * i.color.r * Heightmap * ase_lightAtten );
            half3 lited_col = lerp(blendedCol.xyz, (blendedCol.xyz * 2.0 ) , SubsurfaceIntensity);

            //Touch Reaction 
            half3 ase_vertex3Pos = mul( unity_WorldToObject, float4( ase_worldPos , 1 ) ).xyz;
			#ifdef _VS_TOUCHBEND_ON
                half TouchBendPos = (TouchReactAdjustVertex(ase_vertex3Pos).y;
			#else
                half TouchBendPos = 0.0;
			#endif

            half3 bendingTintCol = (TouchBendPos * _BendingTint).xxx;
            half AO = lerp( 1.0 , clamp(i.color.r * 1.33 * _AmbientOcclusion, 0.0, 1.0), _AmbientOcclusion);
            half3 FinalColor = (lited_col - bendingTintCol) * AO;
            
            o.albedo = lerp( FinalColor, WindVector, _WindDebug);
			o.normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D( _BumpMap, sampler_BumpMap, uv_texcoord), 1.0); 
			o.emission = float3( 0,0,0 );
			o.metallic = 0.0;
			o.smoothness = 0.0;
			o.occlusion = 1.0;
            
    }
    
    half4 fragCustomUniversalForward(Varyings IN) : SV_Target
    {
        //re-normalize all directions vector after interpolation
        IN.normalWS = normalize(IN.normalWS);
        IN.tangentWS.xyz = normalize(IN.tangentWS);
        IN.bitangentWS = normalize(IN.bitangentWS);
    
        //use user's surface function to produce final surface data
        UserSurfaceOutputData surfaceData = BuildUserSurfaceOutputData(IN, false);
    
        //do alphaclip as soon as possible
        clip(surfaceData.alpha - surfaceData.alphaClipThreshold); //鉴于在用户自定义的SurfaceData计算阶段已经可以clip了，此处只做备份
    
        //========================================================================
        // build LightingData, pass it to CalculateSurfaceFinalResultColor(...)
        //========================================================================
        FAELightingData lightingData = (FAELightingData)0;
        half3 T = IN.tangentWS.xyz;
        half3 B = IN.bitangentWS;
        half3 N = IN.normalWS;
    
        //TODO: 对于面片草来说，可以去除TBN变换，直接应用纹理采样获得的法线 
        lightingData.normalWS = TransformTangentToWorld(surfaceData.normalTS, half3x3(T,B,N)); 
    
        float3 positionWS = IN.positionWSAndFogFactor.xyz;
        half3 viewDirectionWS = normalize(GetWorldSpaceViewDir(positionWS));
        half3 reflectionDirectionWS = reflect(-viewDirectionWS, lightingData.normalWS);
        
        // shadowCoord is position in shadow light space (must compute in fragment shader after URP 7.X)
        float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
        lightingData.mainDirectionalLight = GetMainLight(shadowCoord);
    
        //将阴影lightingData.mainDirectionalLight.shadowAttenuation 从0-1映射到0.4-0.5,参数直接控制阴影区衰减比例
        lightingData.mainDirectionalLight.shadowAttenuation = lerp(0.4+_Shadow_Atten*0.1,0.5, lightingData.mainDirectionalLight.shadowAttenuation);

        //raw light probe or lightmap color, depends on unity's keyword "LIGHTMAP_ON"
        
        //受环境光影响，关闭环境光对投影的影响 -> 来自lightmap和SH 
        lightingData.bakedIndirectDiffuse = SAMPLE_GI(IN.uv2, SampleSH(lightingData.normalWS), lightingData.normalWS)*0.5;
    
        //raw reflection probe color -> 来自反射探针 
        lightingData.bakedIndirectSpecular = GlossyEnvironmentReflection(reflectionDirectionWS, 1-surfaceData.smoothness, 1);//perceptualRoughness = 1 - smoothness
    
        lightingData.viewDirectionWS = viewDirectionWS;
        lightingData.reflectionDirectionWS = reflectionDirectionWS;
    
        lightingData.additionalLightCount = GetAdditionalLightsCount();
        lightingData.positionWS = positionWS;
    
        //TODO: what if user want postprocess both before fog and after?
        half4 finalColor = CalculateSurfaceFinalResultColor(IN, surfaceData, lightingData);
        FinalPostProcessFrag(IN, surfaceData, lightingData, finalColor);
    
        return finalColor;
    }

    //IMPORTANT: write your final fragment color edit logic here
    //usually for gameplay logic's color override or darken, like "loop: lerp to red" for selectable targets / flash white on taking damage / darken dead units...
    //you can replace this function by a #include "Your_own_hlsl.hlsl" call, to share this function between different surface shaders
    void FinalPostProcessFrag(Varyings IN, UserSurfaceOutputData surfaceData, FAELightingData lightingData, inout half4 inputColor)
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
            ZClip False
            Cull Off

            HLSLPROGRAM
            #pragma vertex vertUniversalForward
            #pragma fragment fragCustomUniversalForward
            ENDHLSL
        }

        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
          
        //ShadowCaster pass, for rendering this shader into URP's shadowmap renderTextures
        //User should not need to edit this pass in most cases
//        Pass
//        {
//            Name "ShadowCaster"
//            Tags { "LightMode"="ShadowCaster" }
//            ColorMask 0 //optimization: ShadowCaster pass don't care fragment shader output value, disable color write to reduce bandwidth usage
//
//            HLSLPROGRAM
//
//            #pragma vertex vertShadowCaster
//            #pragma fragment fragDoAlphaClipOnlyAndEarlyExit
//
//            ENDHLSL
//        }

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