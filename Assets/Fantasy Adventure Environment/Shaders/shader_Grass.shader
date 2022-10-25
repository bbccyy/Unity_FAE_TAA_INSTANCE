Shader "Test/shader_Grass"
{
    Properties
    {
        _Cutoff("Mask Clip Value", Float) = 0.5
        _Color("Color", Color) = (1,1,1,1)
        _ColorTop("ColorTop", Color) = (0.3001064,0.6838235,0,1)
        _ColorBottom("Color Bottom", Color) = (0.232,0.5,0,1)
        [NoScaleOffset]_MainTex("MainTex", 2D) = "white" {}
        [NoScaleOffset][Normal]_BumpMap("BumpMap", 2D) = "bump" {}
        _ColorVariation("ColorVariation", Range(0 , 0.2)) = 0.05
        _AmbientOcclusion("AmbientOcclusion", Range(0 , 1)) = 0
        _TransmissionSize("Transmission Size", Range(0 , 20)) = 1
        _TransmissionAmount("Transmission Amount", Range(0 , 10)) = 2.696819
        _MaxWindStrength("Max Wind Strength", Range(0 , 1)) = 0.126967
        _WindSwinging("WindSwinging", Range(0 , 1)) = 0.25
        _WindAmplitudeMultiplier("WindAmplitudeMultiplier", Float) = 1
        _HeightmapInfluence("HeightmapInfluence", Range(0 , 1)) = 0
        _MinHeight("MinHeight", Range(-1 , 0)) = -0.5
        _MaxHeight("MaxHeight", Range(-1 , 1)) = 0
        _BendingInfluence("BendingInfluence", Range(0 , 1)) = 0
        _TouchBendingStrength("PushStrength", Range(0, 5)) = 0.5
        _TouchBendingRadius("PushSize", Range(0, 10)) = 1
        _PigmentMapInfluence("PigmentMapInfluence", Range(0 , 1)) = 0
        _PigmentMapHeight("PigmentMapHeight", Range(0 , 1)) = 0
        _BendingTint("BendingTint", Range(-0.1 , 0.1)) = -0.05
        _Shadow_Atten("_Shadow_Atten", Range(0 , 1)) = 0.58

        [Toggle(_VS_TOUCHBEND_ON)] _VS_TOUCHBEND("VS_TOUCHBEND", Float) = 0
    }

    HLSLINCLUDE

    #pragma prefer_hlslcc gles
    #pragma exclude_renderers d3d11_9x
    #pragma target 2.0
    #pragma multi_compile_fog
    #pragma multi_compile_instancing

    //100% copied from URP PBR shader graph's generated code
    // Keywords
    //#pragma shader_feature _ LIGHTMAP_ON
    #pragma shader_feature _ DIRLIGHTMAP_COMBINED
    #pragma shader_feature _ _MAIN_LIGHT_SHADOWS
    #pragma shader_feature _ _MAIN_LIGHT_SHADOWS_CASCADE
    //#pragma shader_feature _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
    //#pragma shader_feature _ _ADDITIONAL_LIGHT_SHADOWS
    #pragma shader_feature _ _SHADOWS_SOFT
    //#pragma shader_feature _ _MIXED_LIGHTING_SUBTRACTIVE
#define UNITY_INSTANCING_ENABLED   //I dont know why, but sometimes if i skip this line, unity won't open Instance related Marco even if i do include "multi_compile_instancing" pragma tag@wyz 

    //the core .hlsl of the whole URP surface shader structure, must be included
    #include "NiloURPSurfaceShaderInclude.hlsl"
    #include "UnityCG.hlsl"

    //first, select a lighting function = a .hlsl which contains the concrete body of CalculateSurfaceFinalResultColor(...)
    //you can select any .hlsl you want here, default is NiloPBRLitCelShadeLightingFunction.hlsl, you can always change it
    #include "NiloPBRLitCelShadeLightingFunction.hlsl"
    //#include "../LightingFunctionLibrary/NiloPBRLitLightingFunction.hlsl"
    //#include "..........YourOwnLightingFunction.hlsl" //you can always write your own!

    //put your custom #pragma here as usual
    #pragma shader_feature _NORMALMAP 
    #pragma shader_feature _ _IsSelected
    #pragma multi_compile_instancing
    #pragma instancing_options assumeuniformscaling nolodfade nolightmap nolightprobe 

    //parameters 
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

    uniform float _Cutoff = 0.5;
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
    // �ݱ�ѹ�����
    uniform float _TouchBendingStrength;
    uniform float _TouchBendingRadius;
    uniform float _PigmentMapInfluence;
    uniform float _PigmentMapHeight;
    uniform float _BendingTint;
    uniform float _Shadow_Atten;

    uniform int _TotalNum;
    uniform int _BatchNum;

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

    CBUFFER_START(myBufferData)  //TODO: ����ʹ��CBUFFER�ؼ��ʺͲ�ʹ�õ��������� (�����ϲ�ʹ�û����) 
                                 //https://forum.unity.com/threads/multiple-cbuffer-in-custom-instanced-shader.438866/ 
        Buffer<half4> _InputConstData; //����ʹ��half4���������壬ȷ����ʵ�����GPU�ڴ��е����ݱ�CPU����Ľ�ʡ�ռ� 
    CBUFFER_END

    //Buffer<half4> _InputConstData;   //TODO:���Բ�ʹ��CBUFFER�궨�� 


    UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
    UNITY_INSTANCING_BUFFER_END(Props)


    // ����׶�: ����������ϵ�£�����ݱ�ѹ����ƫ�ƣ�����ݶ��㣬�����ѹ���λ�á�
    inline float4 CalculateTouchBending(float4 vertex, half height)
    {
        float3 current = _PlayerPosition;
        //current.y += _TouchBendingRadius;

        if (distance(vertex.xyz, current.xyz) < _TouchBendingRadius)
        {
            float WMDistance = 1 - clamp(distance(vertex.xyz, current.xyz) / _TouchBendingRadius, 0, 1);
            float3 posDifferences = normalize(vertex.xyz - current.xyz);

            float3 strengthedDifferences = posDifferences * _TouchBendingStrength * 2;

            float3 resultXZ = WMDistance * strengthedDifferences;

            vertex.xz += resultXZ.xz * height;
            vertex.y -= WMDistance * _TouchBendingStrength * height;

            return vertex;
        }
        return vertex;
    }

    // �÷���Ҳ�Ǵ���bending�ģ�ֻ��������ģ�Ϳռ��м��㣨Ĭ�����Ϊģ�Ϳռ��ж��㣩
    // �÷�����vert��frag�ж���Ӧ�ã�vert���ǵ��͵�Ӱ������ģ�Ϳռ�Y��߶ȣ�frag�����ǿ�������ʱ��tint col 
    // TODO: �Ƿ���Ժ������ CalculateTouchBending һ��򲢴��� 
    float3 TouchReactAdjustVertex(float3 pos)
    {
        float3 worldPos = mul(unity_ObjectToWorld, float4(pos, 1));
        float2 tbPos = saturate((float2(worldPos.x, -worldPos.z) - _TouchReact_Pos.xz) / _TouchReact_Pos.w);
        float2 touchBend = SAMPLE_TEXTURE2D_LOD(
            _TouchReact_Buffer,
            sampler_TouchReact_Buffer,
            tbPos,
            0
        );
        touchBend.y *= 1.0 - length(tbPos - 0.5) * 2;
        if (touchBend.y > 0.01)
        {
            worldPos.y = min(worldPos.y, touchBend.x * 10000);
        }

        float3 changedLocalPos = mul(unity_WorldToObject, float4(worldPos, 1)).xyz;
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
    float3 CalculateWind(float3 pos, float3 color)
    {
        float3 worldPos = TransformObjectToWorld(pos);
        float2 windUV = float2(_WindDirection.x, _WindDirection.z);
        float3 WindWithMap = UnpackNormal(
            SAMPLE_TEXTURE2D_LOD(
                _WindVectors,
                sampler_WindVectors,
                ((((worldPos).xz * 0.01) * _WindAmplitudeMultiplier * _WindAmplitude) + (((_WindSpeed * 0.05) * _Time.w) * windUV)).xy,
                0
            )
        );
        float3 WindOffset = float3(WindWithMap.x, 0, WindWithMap.y);
        return lerp((_MaxWindStrength * _WindStrength) * WindOffset, float3(0, 0, 0), (1.0 - color.r));
    }

    void UserGeometryDataOutputFunction(Attributes IN, inout UserGeometryOutputData geometryOutputData, bool isExtraCustomPass)
    {
        float3 ase_worldPos = mul(unity_ObjectToWorld, IN.positionOS);
        
        float3 Wind = CalculateWind(IN.positionOS, IN.color);
        //�ϰ����λ��_ObstaclePosition

        //�ӵ�ǰ���ζ���ָ��ĳ��ȫ�����õ��ϰ��������(ע�����ﲻ�Ǵ������Ｗѹ) 
        float3 pos2obt = normalize(_ObstaclePosition.xyz - ase_worldPos);

        ///������������˺�Y�����ݻᱻĨȥ��X��Z���൱�ڳ����˹̶���ǿ������ 
        float3 bendingStrengthX0Z = float3(_BendingStrength, 0.0, _BendingStrength) * 0.1;
        ///����ǿ�� -> ֵԽСԽǿ
        float revBendingForce = clamp((distance(_ObstaclePosition.xyz, ase_worldPos) / max(_BendingRadius, 0.001)), 0.0, 1.0);

        /// X-Zƽ���Ϸ���ͶӰ�����������ǿ��Ӱ��(* bendingStrengthX0Z) �ٳ��� ��ѹǿ�ȣ�������һ��ȫ�ֵ�ǿ������ 
        half bendingFactor = -(pos2obt * bendingStrengthX0Z * (1.0 - revBendingForce) * _BendingInfluence);
        //�����ϰ����γɵļ�ѹ 
        float3 Bending = IN.color.r * bendingFactor;

        //��Ϊ����ϰ����õĶ���ƫ�� 
        float3 compOffset = Wind + Bending;


        ///�������ͼ��ͼ
        float2 TerrainUV = (1.0 - _TerrainUV.zw) / _TerrainUV.x + ase_worldPos.xz / _TerrainUV.x; //TODO : rewrite this part! 
        float4 groundCol = SAMPLE_TEXTURE2D_LOD(_PigmentMap, sampler_PigmentMap, TerrainUV, 1);

        float Heightmap = groundCol.a;

        ///��compOffset׷�ӵر�߶ȵ�Ӱ�� 
        compOffset = lerp(compOffset, (compOffset * Heightmap), _PigmentMapInfluence);


        float3 ase_vertex3Pos = IN.positionOS.xyz;
#ifdef _VS_TOUCHBEND_ON
        float TouchBendPos = (TouchReactAdjustVertex(float4(ase_vertex3Pos, 0.0).xyz)).y;
#else
        float TouchBendPos = 0.0;
#endif

        float Yoffset = lerp((saturate(((1.0 - Heightmap) - TouchBendPos)) * _MinHeight), 0.0, (1.0 - IN.color.r));
        float Ybias = lerp(_MaxHeight, 0.0, (1.0 - IN.color.r));
        float GrassLength = Yoffset * _HeightmapInfluence + Ybias;

        float3 VertexOffset = float3(compOffset.x, GrassLength, compOffset.z);

        geometryOutputData.positionOS.xyz += VertexOffset;
        // �˴����ڴ�������/��ɫ��ɵļ�ѹ 
        geometryOutputData.positionOS = mul(unity_WorldToObject, CalculateTouchBending(mul(unity_ObjectToWorld, geometryOutputData.positionOS), IN.color.x));

        geometryOutputData.normalOS = float3(0, 1, 0);
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
        //ȥ��gi��һ������
        half ase_lightAtten = 1;
        float2 uv_texcoord = i.uv;
        float2 uv_MainTex = uv_texcoord;

        //����maintex 
        half4 baseColor_raw = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv_MainTex);
        //��_WindDebug���������οգ����ڹ۲�wind 
        half alphaDebug = lerp(baseColor_raw.a, 1.0, _WindDebug);
        clip(alphaDebug - _Cutoff);

        //i.color.r �Ǿ�����ֵ��ĵ�ǰ��߶ȱ��� 
        half4 colorOnHeight = lerp(_ColorTop, _ColorBottom, (1.0 - i.color.r));
        //BaseColor = ��ͼ��ɫ*�����ⲿ��ɫ�Ļ��
        half4 BaseColor = (colorOnHeight * baseColor_raw);

        ///�������ͼ��ͼ
        float3 ase_worldPos = i.positionWSAndFogFactor.xyz;
        float2 TerrainUV = (1.0 - _TerrainUV.zw) / _TerrainUV.x + ase_worldPos.xz / _TerrainUV.x; //TODO : rewrite this part! 
        half4 groundCol = SAMPLE_TEXTURE2D(_PigmentMap, sampler_PigmentMap, TerrainUV);

        //��ر���ɫ��� 
        half adjusted_height_rate = lerp((1.0 - i.color.r), 1.0, _PigmentMapHeight);
        half4 blendedCol = lerp(_ColorTop, groundCol, adjusted_height_rate);
        half4 PigmentMapColor = lerp(BaseColor, blendedCol, _PigmentMapInfluence);

        //�����糡 
        half2 windUV = ase_worldPos.xz * 0.01 * _WindAmplitudeMultiplier * _WindAmplitude + _WindSpeed * 0.05 * _Time.w * _WindDirection.xz;
        half3 WindVector = UnpackNormal(SAMPLE_TEXTURE2D(_WindVectors, sampler_WindVectors, windUV));

        half WindTint = saturate(WindVector.x * WindVector.y * i.color.r * _ColorVariation * _WindStrength);

        //Ϊʲô��ɫ�ͷ�Ҫ�й�ϵ�� -> �ش���:��Ȼ��Ϊ������"��ɫ"������Ӿ���Ҳ�ܸ��ܵ���Ĵ����� 
        blendedCol.xyz = PigmentMapColor.rgb + WindTint;

        //Apply simple Lit 
        half3 ase_worldViewDir = normalize(UnityWorldSpaceViewDir(ase_worldPos));
        half3 ase_worldlightDir = normalize(UnityWorldSpaceLightDir(ase_worldPos));
        half VoL = dot(-ase_worldViewDir, ase_worldlightDir);
        half Heightmap = groundCol.a;
        half SubsurfaceIntensity = saturate(pow(max(VoL, 0.0), _TransmissionSize) * _TransmissionAmount * i.color.r * Heightmap * ase_lightAtten);
        half3 lited_col = lerp(blendedCol.xyz, (blendedCol.xyz * 2.0), SubsurfaceIntensity);

        //Touch Reaction 
        half3 ase_vertex3Pos = mul(unity_WorldToObject, float4(ase_worldPos, 1)).xyz;
#ifdef _VS_TOUCHBEND_ON
        half TouchBendPos = (TouchReactAdjustVertex(ase_vertex3Pos).y;
#else
        half TouchBendPos = 0.0;
#endif

        half3 bendingTintCol = (TouchBendPos * _BendingTint).xxx;
        half AO = lerp(1.0, clamp(i.color.r * 1.33 * _AmbientOcclusion, 0.0, 1.0), _AmbientOcclusion);
        half3 FinalColor = (lited_col - bendingTintCol) * AO;

        o.albedo = lerp(FinalColor, WindVector, _WindDebug);
        o.normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uv_texcoord), 1.0);
        o.emission = float3(0, 0, 0);
        o.metallic = 0.0;
        o.smoothness = 0.0;
        o.occlusion = 1.0;
    }

    half4 fragCustomUniversalForward(Varyings IN) : SV_Target
    {
        UNITY_SETUP_INSTANCE_ID(IN);

        half4 instanc_Color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color); 

        //re-normalize all directions vector after interpolation
        IN.normalWS = normalize(IN.normalWS);
        //IN.tangentWS.xyz = normalize(IN.tangentWS);
        //IN.bitangentWS = normalize(IN.bitangentWS);

        //use user's surface function to produce final surface data
        UserSurfaceOutputData surfaceData = BuildUserSurfaceOutputData(IN, false);

        //do alphaclip as soon as possible
        clip(surfaceData.alpha - surfaceData.alphaClipThreshold); //�������û��Զ����SurfaceData����׶��Ѿ�����clip�ˣ��˴�ֻ������

        //========================================================================
        // build LightingData, pass it to CalculateSurfaceFinalResultColor(...)
        //========================================================================
        FAELightingData lightingData = (FAELightingData)0;
        //half3 T = IN.tangentWS.xyz;
        //half3 B = IN.bitangentWS;
        //half3 N = IN.normalWS;          //TODO: �ɵ�TBN 

        //TODO: ������Ƭ����˵������ȥ��TBN�任��ֱ��Ӧ�����������õķ��� 
        //lightingData.normalWS = TransformTangentToWorld(surfaceData.normalTS, half3x3(T,B,N)); 
        lightingData.normalWS = IN.normalWS;
        //lightingData.normalWS = half3(0,1,0);

        float3 positionWS = IN.positionWSAndFogFactor.xyz;
        half3 viewDirectionWS = normalize(GetWorldSpaceViewDir(positionWS));
        half3 reflectionDirectionWS = reflect(-viewDirectionWS, lightingData.normalWS);

        // shadowCoord is position in shadow light space (must compute in fragment shader after URP 7.X)
        float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
        lightingData.mainDirectionalLight = GetMainLight(shadowCoord);

        //����ӰlightingData.mainDirectionalLight.shadowAttenuation ��0-1ӳ�䵽0.4-0.5,����ֱ�ӿ�����Ӱ��˥������
        lightingData.mainDirectionalLight.shadowAttenuation = lerp(0.4 + _Shadow_Atten * 0.1,0.5, lightingData.mainDirectionalLight.shadowAttenuation);

        //raw light probe or lightmap color, depends on unity's keyword "LIGHTMAP_ON"

        //�ܻ�����Ӱ�죬�رջ������ͶӰ��Ӱ�� -> ����lightmap��SH 
        //lightingData.bakedIndirectDiffuse = SAMPLE_GI(IN.uv2, SampleSH(lightingData.normalWS), lightingData.normalWS) * 0.5;

        //raw reflection probe color -> ���Է���̽�� 
        //lightingData.bakedIndirectSpecular = GlossyEnvironmentReflection(reflectionDirectionWS, 1 - surfaceData.smoothness, 1);//perceptualRoughness = 1 - smoothness

        lightingData.viewDirectionWS = viewDirectionWS;
        lightingData.reflectionDirectionWS = reflectionDirectionWS;

        lightingData.additionalLightCount = GetAdditionalLightsCount();
        lightingData.positionWS = positionWS;

        //TODO: what if user want postprocess both before fog and after?
        half4 finalColor = CalculateSurfaceFinalResultColor(IN, surfaceData, lightingData);
        //FinalPostProcessFrag(IN, surfaceData, lightingData, finalColor);

        return finalColor * instanc_Color;
    }

    //TODO: ȥ��uv2 -> û��ʹ��lightmap 
    Varyings vertUniversalForwardInstancing(Attributes IN)
    {
        Varyings OUT = (Varyings)0;

        UNITY_SETUP_INSTANCE_ID(IN);
        UNITY_TRANSFER_INSTANCE_ID(IN, OUT);

        UserGeometryOutputData geometryData = BuildUserGeometryOutputData(IN, false); //TODO: ��root�ڵ��posWS����ȡ���� 

        // VertexPositionInputs contains position in multiple spaces (world, view, homogeneous clip space)
        // The compiler will strip all unused references.
        // Therefore there is more flexibility at no additional cost with this struct.

        uint id = UNITY_GET_INSTANCE_ID(IN); 
        //uint instanceIdx = (uint)UNITY_ACCESS_INSTANCED_PROP(Props, _InstanceIdx);  //���ֵ�������id��һ���ģ�TODO:ȥ�� 
        uint tableIndex = id * _BatchNum + (uint)floor(IN.color.g * _BatchNum); 

        if (tableIndex >= _TotalNum)
        {
            return OUT;
        }

        half4 matrix_V_r1 = _InputConstData[tableIndex * 3];
        half4 matrix_V_r2 = _InputConstData[tableIndex * 3 + 1];
        half4 matrix_V_r3 = _InputConstData[tableIndex * 3 + 2];
        half4x4 matrix_V = half4x4(
            matrix_V_r1,
            matrix_V_r2,
            matrix_V_r3,
            half4(0, 0, 0, 1)
            );
        //float2 tmpXY = _InputConstData[id];

        float4 posWS = mul(matrix_V, float4(geometryData.positionOS.xyz, 1));
        //float4 posWS = mul(unity_ObjectToWorld, geometryData.positionOS);
        //posWS.xy = posWS.xy + half2(matrix_V_r1.w, matrix_V_r2.w);
        // 
        //Pre View culling -> ������㲻����٣��������ؽ׶λᱻ��դ�����˵� 
        float4 pCS = TransformWorldToHClip(posWS);
        if (pCS.z > pCS.w  * 1.2|| pCS.y > pCS.w * 1.7 || pCS.x > pCS.w * 1.5)
        {
            return OUT;
        }

        float4 posOS = mul(unity_WorldToObject, posWS);

        VertexPositionInputs vertexInput = GetVertexPositionInputs(posOS.xyz);
        //VertexPositionInputs vertexInput = GetVertexPositionInputs(geometryData.positionOS.xyz);

        // Similar to VertexPositionInputs, VertexNormalInputs will contain normal, tangent and bitangent
        // in world space. If not used it will be stripped.
        VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(geometryData.normalOS, geometryData.tangentOS);

        OUT.uv = IN.uv;
#if LIGHTMAP_ON
        OUT.uv2 = IN.uv2.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#else
        OUT.uv2 = IN.uv2; 
#endif
        OUT.uv34 = geometryData.uv34;
        OUT.uv56 = geometryData.uv56;
        OUT.uv78 = geometryData.uv78;

        OUT.color = IN.color;

        // Computes fog factor per-vertex.
        float fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
        OUT.positionWSAndFogFactor = float4(vertexInput.positionWS, fogFactor); //pack together

        OUT.normalWS = vertexNormalInput.normalWS;
        OUT.tangentWS = vertexNormalInput.tangentWS;
        OUT.bitangentWS = vertexNormalInput.bitangentWS;

        OUT.positionCS = vertexInput.positionCS;

        return OUT;
    }

    //IMPORTANT: write your final fragment color edit logic here
    //usually for gameplay logic's color override or darken, like "loop: lerp to red" for selectable targets / flash white on taking damage / darken dead units...
    //you can replace this function by a #include "Your_own_hlsl.hlsl" call, to share this function between different surface shaders
    void FinalPostProcessFrag(Varyings IN, UserSurfaceOutputData surfaceData, FAELightingData lightingData, inout half4 inputColor)
    {
        return;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////


    ENDHLSL


    SubShader
    {
         Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            "RenderType" = "Opaque"
            "Queue" = "Geometry+0"
            "IsEmissive" = "true"
        }

        //UniversalForward pass
        Pass
        {
            Name "Universal Forward"
            Tags { "LightMode" = "UniversalForward" }
            //ZClip False
            Cull Off

            HLSLPROGRAM
            #pragma vertex vertUniversalForwardInstancing 
            #pragma fragment fragCustomUniversalForward
            ENDHLSL
        }

         Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }
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
