Shader "Particles/Full Screen"
{
    Properties
    {
        _MainTex("Albedo", 2D) = "white" {}
        _Color("Color", Color) = (1,1,1,1)

        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        _BumpScale("Scale", Float) = 1.0
        _BumpMap("Normal Map", 2D) = "bump" {}

        _EmissionColor("Color", Color) = (0,0,0)
        _EmissionMap("Emission", 2D) = "white" {}

        _DistortionStrength("Strength", Float) = 1.0
        _DistortionBlend("Blend", Range(0.0, 1.0)) = 0.5

        _SoftParticlesNearFadeDistance("Soft Particles Near Fade", Float) = 0.0
        _SoftParticlesFarFadeDistance("Soft Particles Far Fade", Float) = 1.0
        _CameraNearFadeDistance("Camera Near Fade", Float) = 1.0
        _CameraFarFadeDistance("Camera Far Fade", Float) = 2.0

        // Hidden properties
        [HideInInspector] _Mode ("__mode", Float) = 0.0
        [HideInInspector] _ColorMode ("__colormode", Float) = 0.0
        [HideInInspector] _FlipbookMode ("__flipbookmode", Float) = 0.0
        [HideInInspector] _LightingEnabled ("__lightingenabled", Float) = 0.0
        [HideInInspector] _DistortionEnabled ("__distortionenabled", Float) = 0.0
        [HideInInspector] _EmissionEnabled ("__emissionenabled", Float) = 0.0
        [HideInInspector] _BlendOp ("__blendop", Float) = 0.0
        [HideInInspector] _SrcBlend ("__src", Float) = 1.0
        [HideInInspector] _DstBlend ("__dst", Float) = 0.0
        [HideInInspector] _ZWrite ("__zw", Float) = 1.0
        [HideInInspector] _Cull ("__cull", Float) = 2.0
        [HideInInspector] _SoftParticlesEnabled ("__softparticlesenabled", Float) = 0.0
        [HideInInspector] _CameraFadingEnabled ("__camerafadingenabled", Float) = 0.0
        [HideInInspector] _SoftParticleFadeParams ("__softparticlefadeparams", Vector) = (0,0,0,0)
        [HideInInspector] _CameraFadeParams ("__camerafadeparams", Vector) = (0,0,0,0)
        [HideInInspector] _ColorAddSubDiff ("__coloraddsubdiff", Vector) = (0,0,0,0)
        [HideInInspector] _DistortionStrengthScaled ("__distortionstrengthscaled", Float) = 0.0
    }

    Category
    {
        SubShader
        {
            Tags {"RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "IgnoreProjector"="True" "PreviewType"="Plane" "PerformanceChecks"="False" }

            BlendOp [_BlendOp]
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            Cull [_Cull]
            ColorMask RGB
//TODO：URP 不支持 GrabPass
//            GrabPass
//            {
//                Tags { "LightMode" = "SRPDefaultUnlit" }
//                "_GrabTexture"
//            }
/*
            Pass
            {
                Name "ShadowCaster"
                Tags { "LightMode" = "ShadowCaster" }

                BlendOp Add
                Blend One Zero
                ZWrite On
                Cull Off

                CGPROGRAM
                #pragma target 2.5

                #pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON _ALPHAMODULATE_ON
                #pragma shader_feature _ _COLOROVERLAY_ON _COLORCOLOR_ON _COLORADDSUBDIFF_ON
                #pragma shader_feature _REQUIRE_UV2
                #pragma multi_compile_shadowcaster
                #pragma multi_compile_instancing
                #pragma instancing_options procedural:vertInstancingSetup

                #pragma vertex vertParticleShadowCaster
                #pragma fragment fragParticleShadowCaster

                #include "UnityStandardParticleShadow.cginc"
                ENDCG
            }
*/
            Pass
            {
                Name "SceneSelectionPass"
                Tags { "LightMode" = "SceneSelectionPass" }

                BlendOp Add
                Blend One Zero
                ZWrite On
                Cull Off

                HLSLPROGRAM
                #pragma target 2.5

                #pragma shader_feature _ _ALPHATEST_ON
                #pragma shader_feature _REQUIRE_UV2
                #pragma multi_compile_instancing
                #pragma instancing_options procedural:vertInstancingSetup

                //#pragma vertex vertEditorPass
                #pragma vertex vertEditorPassFullScreen
                #pragma fragment fragSceneHighlightPass

                #include "UnityStandardParticleEditor.cginc"
                void vertEditorPassFullScreen(VertexInput v, out VertexOutput o, out float4 opos : SV_POSITION)
                {
                    UNITY_SETUP_INSTANCE_ID(v);

                    //opos = UnityObjectToClipPos(v.vertex);
                    opos = float4(v.texcoords.x * 2 - 1, 1 - v.texcoords.y * 2, 1, 1);

                    #ifdef _FLIPBOOK_BLENDING
                        #ifdef UNITY_PARTICLE_INSTANCING_ENABLED
                            vertInstancingUVs(v.texcoords.xy, o.texcoord, o.texcoord2AndBlend);
                        #else
                            o.texcoord = v.texcoords.xy;
                            o.texcoord2AndBlend.xy = v.texcoords.zw;
                            o.texcoord2AndBlend.z = v.texcoordBlend;
                        #endif
                    #else
                        #ifdef UNITY_PARTICLE_INSTANCING_ENABLED
                            vertInstancingUVs(v.texcoords.xy, o.texcoord);
                            o.texcoord = TRANSFORM_TEX(o.texcoord, _MainTex);
                        #else
                            o.texcoord = TRANSFORM_TEX(v.texcoords.xy, _MainTex);
                        #endif
                    #endif
                    o.color = v.color;
                }
                ENDHLSL
            }

            Pass
            {
                Name "ScenePickingPass"
                Tags{ "LightMode" = "Picking" }

                BlendOp Add
                Blend One Zero
                ZWrite On
                Cull Off

                HLSLPROGRAM
                #pragma target 2.5

                #pragma shader_feature _ _ALPHATEST_ON
                #pragma shader_feature _REQUIRE_UV2
                #pragma multi_compile_instancing
                #pragma instancing_options procedural:vertInstancingSetup

                #pragma vertex vertEditorPassFullScreen
                #pragma fragment fragScenePickingPass

                #include "UnityStandardParticleEditor.cginc"
                void vertEditorPassFullScreen(VertexInput v, out VertexOutput o, out float4 opos : SV_POSITION)
                {
                    UNITY_SETUP_INSTANCE_ID(v);

                    //opos = UnityObjectToClipPos(v.vertex);
                    opos = float4(v.texcoords.x * 2 - 1, 1 - v.texcoords.y * 2, 1, 1);

                    #ifdef _FLIPBOOK_BLENDING
                        #ifdef UNITY_PARTICLE_INSTANCING_ENABLED
                            vertInstancingUVs(v.texcoords.xy, o.texcoord, o.texcoord2AndBlend);
                        #else
                            o.texcoord = v.texcoords.xy;
                            o.texcoord2AndBlend.xy = v.texcoords.zw;
                            o.texcoord2AndBlend.z = v.texcoordBlend;
                        #endif
                    #else
                        #ifdef UNITY_PARTICLE_INSTANCING_ENABLED
                            vertInstancingUVs(v.texcoords.xy, o.texcoord);
                            o.texcoord = TRANSFORM_TEX(o.texcoord, _MainTex);
                        #else
                            o.texcoord = TRANSFORM_TEX(v.texcoords.xy, _MainTex);
                        #endif
                    #endif
                    o.color = v.color;
                }
                ENDHLSL
            }

            Pass
            {
                Tags { "LightMode"="UniversalForward" }

                HLSLPROGRAM
                #pragma shader_feature __ SOFTPARTICLES_ON
                //#pragma multi_compile_fog
                #pragma target 2.5

                #pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON _ALPHAMODULATE_ON
                #pragma shader_feature _ _COLOROVERLAY_ON _COLORCOLOR_ON _COLORADDSUBDIFF_ON
                #pragma shader_feature _NORMALMAP
                #pragma shader_feature _EMISSION
                #pragma shader_feature _FADING_ON
                #pragma shader_feature _REQUIRE_UV2
                #pragma shader_feature EFFECT_BUMP

                #pragma vertex vertParticleUnlitFullScreen
                #pragma fragment fragParticleUnlit
                #pragma multi_compile_instancing
                #pragma instancing_options procedural:vertInstancingSetup

                #include "UnityStandardParticles.cginc"
                
                void vertParticleUnlitFullScreen (appdata_particles v, out VertexOutput o)
                {
                    UNITY_SETUP_INSTANCE_ID(v);

                    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                    //float4 clipPosition = UnityObjectToClipPos(v.vertex);
                    float4 clipPosition = float4(v.texcoords.x * 2 - 1, 1 - v.texcoords.y * 2, 1, 1);
                    o.vertex = clipPosition;
                    o.color = v.color;

                    vertColor(o.color);
                    vertTexcoord(v, o);
                    vertFading(o);
                    vertDistortion(o);

//                    UNITY_TRANSFER_FOG(o, o.vertex);
                }
                ENDHLSL
            }
        }
    }

    Fallback "Render Pipeline/Liteline/Lit"
    CustomEditor "StandardParticlesShaderGUI"
}
