// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Babeltime/Scene/MeshGrass"
{
	Properties
	{
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
		[Toggle(_VS_TOUCHBEND_ON)] _VS_TOUCHBEND("VS_TOUCHBEND", Float) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty("", Int) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry" }
		Blend Off
		Cull Off
		ZTest Lequal
		ZClip False
		CGPROGRAM
		#include "UnityPBSLighting.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityCG.cginc"
		#include "UnityStandardUtils.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#pragma multi_compile_instancing
		#pragma shader_feature _VS_TOUCHBEND_ON
		#pragma shader_feature GPU_FRUSTUM_ON __
//		#pragma instancing_options assumeuniformscaling lodfade maxcount:50 procedural:setupScale
		#pragma exclude_renderers xbox360 psp2 n3ds wiiu 
		#pragma surface surf StandardCustomLighting keepalpha vertex:vertexDataFunc 
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float3 worldPos;
			float2 uv_texcoord;
			float3 worldNormal;
			INTERNAL_DATA
			float4 vertexColor : COLOR;
		};

		struct SurfaceOutputCustomLightingCustom
		{
			half3 Albedo;
			half3 Normal;
			half3 Emission;
			half Metallic;
			half Smoothness;
			half Occlusion;
			half Alpha;
			Input SurfInput;
			UnityGIInput GIData;
		};

		uniform float _MaxWindStrength;
		uniform float _WindStrength;
		uniform sampler2D _WindVectors;
		uniform float _WindAmplitudeMultiplier;
		uniform float _WindAmplitude;
		uniform float _WindSpeed;
		uniform float4 _WindDirection;
		uniform float _WindSwinging;
		uniform float4 _ObstaclePosition;
		uniform float _BendingStrength;
		uniform float _BendingRadius;
		uniform float _BendingInfluence;
		uniform sampler2D _PigmentMap;
		uniform float4 _TerrainUV;
		uniform float _PigmentMapInfluence;
		uniform float _MinHeight;
		uniform float _HeightmapInfluence;
		uniform float _MaxHeight;
		uniform sampler2D _MainTex;
		uniform float _WindDebug;
		uniform float4 _ColorTop;
		uniform float4 _ColorBottom;
		uniform float _PigmentMapHeight;
		uniform float _ColorVariation;
		uniform float _TransmissionSize;
		uniform float _TransmissionAmount;
		uniform float _BendingTint;
		uniform float _AmbientOcclusion;
		uniform sampler2D _BumpMap;
		uniform float _Cutoff = 0.5;

		// 草被压倒相关
		uniform float _TouchBendingStrength;
		uniform float _TouchBendingRadius;
		uniform float3 _PlayerPosition;

		// 草被压倒计算。输入草顶点，输出被压的位置。
		inline float4 CalculateTouchBending(float4 vertex)
		{
			float3 current = _PlayerPosition;
			//current.y += _TouchBendingRadius;

			if (distance(vertex.xyz, current.xyz) < _TouchBendingRadius)
			{
				float WMDistance = 1 - clamp(distance(vertex.xyz, current.xyz) / _TouchBendingRadius, 0, 1);
				float3 posDifferences = normalize(vertex.xyz - current.xyz);

				float3 strengthedDifferences = posDifferences * _TouchBendingStrength * 2;

				float3 resultXZ = WMDistance * strengthedDifferences;

				vertex.xz += resultXZ.xz;
				vertex.y -= WMDistance * _TouchBendingStrength;

				return vertex;
			}

			return vertex;
		}


		sampler2D	_TouchReact_Buffer;
		float4 _TouchReact_Pos;
		 
		float3 TouchReactAdjustVertex(float3 pos)
		{
		   float3 worldPos = mul(unity_ObjectToWorld, float4(pos,1));
		   float2 tbPos = saturate((float2(worldPos.x,-worldPos.z) - _TouchReact_Pos.xz)/_TouchReact_Pos.w);
		   float2 touchBend  = tex2Dlod(_TouchReact_Buffer, float4(tbPos,0,0));
		   touchBend.y *= 1.0 - length(tbPos - 0.5) * 2;
		   if(touchBend.y > 0.01)
		   {
		      worldPos.y = min(worldPos.y, touchBend.x * 10000);
		   }
		
		   float3 changedLocalPos = mul(unity_WorldToObject, float4(worldPos,1)).xyz;
		   return changedLocalPos - pos;
		}


		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			float WindStrength522 = _WindStrength;
			float3 ase_worldPos = mul( unity_ObjectToWorld, v.vertex );
			float2 appendResult469 = (float2(_WindDirection.x , _WindDirection.z));
			float3 WindVector91 = UnpackNormal( tex2Dlod( _WindVectors, float4( ( ( ( (ase_worldPos).xz * 0.01 ) * _WindAmplitudeMultiplier * _WindAmplitude ) + ( ( ( _WindSpeed * 0.05 ) * _Time.w ) * appendResult469 ) ), 0, 0.0) ) );
			float3 break277 = WindVector91;
			float3 appendResult495 = (float3(break277.x , 0.0 , break277.y));
			float3 temp_cast_0 = (-1.0).xxx;
			float3 lerpResult249 = lerp( (float3( 0,0,0 ) + (appendResult495 - temp_cast_0) * (float3( 1,1,0 ) - float3( 0,0,0 )) / (float3( 1,1,0 ) - temp_cast_0)) , appendResult495 , _WindSwinging);
			float3 lerpResult74 = lerp( ( ( _MaxWindStrength * WindStrength522 ) * lerpResult249 ) , float3( 0,0,0 ) , ( 1.0 - v.color.r ));
			float3 Wind84 = lerpResult74;
			float3 temp_output_571_0 = (_ObstaclePosition).xyz;
			float3 normalizeResult184 = normalize( ( temp_output_571_0 - ase_worldPos ) );
			float temp_output_186_0 = ( _BendingStrength * 0.1 );
			float3 appendResult468 = (float3(temp_output_186_0 , 0.0 , temp_output_186_0));
			float clampResult192 = clamp( ( distance( temp_output_571_0 , ase_worldPos ) / _BendingRadius ) , 0.0 , 1.0 );
			float3 Bending201 = ( v.color.r * -( ( ( normalizeResult184 * appendResult468 ) * ( 1.0 - clampResult192 ) ) * _BendingInfluence ) );
			float3 temp_output_203_0 = ( Wind84 + Bending201 );
			float2 appendResult483 = (float2(_TerrainUV.z , _TerrainUV.w));
			float2 TerrainUV324 = ( ( ( 1.0 - appendResult483 ) / _TerrainUV.x ) + ( ( _TerrainUV.x / ( _TerrainUV.x * _TerrainUV.x ) ) * (ase_worldPos).xz ) );
			float4 PigmentMapTex320 = tex2Dlod( _PigmentMap, float4( TerrainUV324, 0, 1.0) );
			float temp_output_467_0 = (PigmentMapTex320).a;
			float Heightmap518 = temp_output_467_0;
			float PigmentMapInfluence528 = _PigmentMapInfluence;
			float3 lerpResult508 = lerp( temp_output_203_0 , ( temp_output_203_0 * Heightmap518 ) , PigmentMapInfluence528);
			float3 break437 = lerpResult508;
			float3 ase_vertex3Pos = v.vertex.xyz;
			#ifdef _VS_TOUCHBEND_ON
				float staticSwitch659 = (TouchReactAdjustVertex(float4( ase_vertex3Pos , 0.0 ).xyz)).y;
			#else
				float staticSwitch659 = 0.0;
			#endif
			float TouchBendPos613 = staticSwitch659;
			float temp_output_499_0 = ( 1.0 - v.color.r );
			float lerpResult344 = lerp( ( saturate( ( ( 1.0 - temp_output_467_0 ) - TouchBendPos613 ) ) * _MinHeight ) , 0.0 , temp_output_499_0);
			float lerpResult388 = lerp( _MaxHeight , 0.0 , temp_output_499_0);
			float GrassLength365 = ( ( lerpResult344 * _HeightmapInfluence ) + lerpResult388 );
			float3 appendResult391 = (float3(break437.x , GrassLength365 , break437.z));
			float3 VertexOffset330 = appendResult391;
			v.vertex.xyz += VertexOffset330;
			// 算挤压
			v.vertex = mul(unity_WorldToObject, CalculateTouchBending(mul(unity_ObjectToWorld, v.vertex)));

			v.normal = float3(0,1,0);
		}

		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			#ifdef UNITY_PASS_FORWARDBASE
			float ase_lightAtten = data.atten;
			if( _LightColor0.a == 0)
			ase_lightAtten = 0;
			#else
			float3 ase_lightAttenRGB = gi.light.color / ( ( _LightColor0.rgb ) + 0.000001 );
			float ase_lightAtten = max( max( ase_lightAttenRGB.r, ase_lightAttenRGB.g ), ase_lightAttenRGB.b );
			#endif
			#if defined(HANDLE_SHADOWS_BLENDING_IN_GI)
			half bakedAtten = UnitySampleBakedOcclusion(data.lightmapUV.xy, data.worldPos);
			float zDist = dot(_WorldSpaceCameraPos - data.worldPos, UNITY_MATRIX_V[2].xyz);
			float fadeDist = UnityComputeShadowFadeDistance(data.worldPos, zDist);
			ase_lightAtten = UnityMixRealtimeAndBakedShadows(data.atten, bakedAtten, UnityComputeShadowFade(fadeDist));
			#endif
			float2 uv_MainTex97 = i.uv_texcoord;
			float4 tex2DNode97 = tex2D( _MainTex, uv_MainTex97 );
			float Alpha98 = tex2DNode97.a;
			float lerpResult313 = lerp( Alpha98 , 1.0 , _WindDebug);
			SurfaceOutputStandard s592 = (SurfaceOutputStandard ) 0;
			float4 lerpResult363 = lerp( _ColorTop , _ColorBottom , ( 1.0 - i.vertexColor.r ));
			float4 BaseColor551 = ( lerpResult363 * tex2DNode97 );
			float4 TopColor549 = _ColorTop;
			float2 appendResult483 = (float2(_TerrainUV.z , _TerrainUV.w));
			float3 ase_worldPos = i.worldPos;
			float2 TerrainUV324 = ( ( ( 1.0 - appendResult483 ) / _TerrainUV.x ) + ( ( _TerrainUV.x / ( _TerrainUV.x * _TerrainUV.x ) ) * (ase_worldPos).xz ) );
			float4 PigmentMapTex320 = tex2D( _PigmentMap, TerrainUV324 );
			float lerpResult416 = lerp( ( 1.0 - i.vertexColor.r ) , 1.0 , _PigmentMapHeight);
			float4 lerpResult376 = lerp( TopColor549 , PigmentMapTex320 , lerpResult416);
			float4 lerpResult290 = lerp( BaseColor551 , lerpResult376 , _PigmentMapInfluence);
			float4 PigmentMapColor526 = lerpResult290;
			float2 appendResult469 = (float2(_WindDirection.x , _WindDirection.z));
			float3 WindVector91 = UnpackNormal( tex2D( _WindVectors, ( ( ( (ase_worldPos).xz * 0.01 ) * _WindAmplitudeMultiplier * _WindAmplitude ) + ( ( ( _WindSpeed * 0.05 ) * _Time.w ) * appendResult469 ) ) ) );
			float3 break240 = WindVector91;
			float WindStrength522 = _WindStrength;
			float WindTint523 = saturate( ( ( ( break240.x * break240.y ) * i.vertexColor.r ) * _ColorVariation * WindStrength522 ) );
			float3 Color161 = ( (PigmentMapColor526).rgb + WindTint523 );
			float3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			float3 ase_worldlightDir = 0;
			#else //aseld
			float3 ase_worldlightDir = normalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			float dotResult141 = dot( -ase_worldViewDir , ase_worldlightDir );
			float temp_output_467_0 = (PigmentMapTex320).a;
			float Heightmap518 = temp_output_467_0;
			float Subsurface153 = saturate( ( ( ( ( pow( max( dotResult141 , 0.0 ) , _TransmissionSize ) * _TransmissionAmount ) * i.vertexColor.r ) * Heightmap518 ) * ase_lightAtten ) );
			float3 lerpResult106 = lerp( Color161 , ( Color161 * 2.0 ) , Subsurface153);
			float3 ase_vertex3Pos = mul( unity_WorldToObject, float4( i.worldPos , 1 ) );
			#ifdef _VS_TOUCHBEND_ON
				float staticSwitch659 = (TouchReactAdjustVertex(float4( ase_vertex3Pos , 0.0 ).xyz)).y;
			#else
				float staticSwitch659 = 0.0;
			#endif
			float TouchBendPos613 = staticSwitch659;
			float3 temp_cast_1 = (( TouchBendPos613 * _BendingTint )).xxx;
			float clampResult302 = clamp( ( ( i.vertexColor.r * 1.33 ) * _AmbientOcclusion ) , 0.0 , 1.0 );
			float lerpResult115 = lerp( 1.0 , clampResult302 , _AmbientOcclusion);
			float AmbientOcclusion207 = lerpResult115;
			float3 FinalColor205 = ( ( lerpResult106 - temp_cast_1 ) * AmbientOcclusion207 );
			float3 lerpResult310 = lerp( FinalColor205 , WindVector91 , _WindDebug);
			s592.Albedo = lerpResult310;
			float2 uv_BumpMap172 = i.uv_texcoord;
			float3 Normals174 = UnpackScaleNormal( tex2D( _BumpMap, uv_BumpMap172 ), 1.0 );
			s592.Normal = WorldNormalVector( i , Normals174 );
			s592.Emission = float3( 0,0,0 );
			s592.Metallic = 0.0;
			s592.Smoothness = 0.0;
			s592.Occlusion = 1.0;

			data.light = gi.light;

			UnityGI gi592 = gi;
			#ifdef UNITY_PASS_FORWARDBASE
			Unity_GlossyEnvironmentData g592 = UnityGlossyEnvironmentSetup( s592.Smoothness, data.worldViewDir, s592.Normal, float3(0,0,0));
			gi592 = UnityGlobalIllumination( data, s592.Occlusion, s592.Normal, g592 );
			#endif

			float3 surfResult592 = LightingStandard ( s592, viewDir, gi592 ).rgb;
			surfResult592 += s592.Emission;

			c.rgb = surfResult592;
			c.a = 1;
			clip( lerpResult313 - _Cutoff );
			return c;
		}

		inline void LightingStandardCustomLighting_GI( inout SurfaceOutputCustomLightingCustom s, UnityGIInput data, inout UnityGI gi )
		{
			s.GIData = data;
		}

		void surf( Input i , inout SurfaceOutputCustomLightingCustom o )
		{
			o.SurfInput = i;
			o.Normal = float3(0,0,1);
		}

		ENDCG
			}
//	Fallback "Diffuse"
}