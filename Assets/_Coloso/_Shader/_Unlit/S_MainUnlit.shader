// Made with Amplify Shader Editor v1.9.2.1
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Coloso/Unlit/S_MainUnlit"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[Enum(Additive,1,AlphaBlend,10,Premultiply,6)]_BlendMode("BlendMode", Float) = 0
		[Enum(UnityEngine.Rendering.CullMode)]_CullMode("CullMode", Float) = 0
		[Enum(LessEqual,4,Always,8)]_ZTest("ZTest", Float) = 0
		[Toggle]_Use_Custom_DissUV1("Use_Custom_Diss/UV1", Float) = 0
		[Toggle]_Use_Custom_OffsetUV2("Use_Custom_Offset/UV2", Float) = 0
		[HDR]_Tint_Color("Tint_Color", Color) = (1,1,1,1)
		_MainTex("MainTex", 2D) = "white" {}
		[Toggle(_USE_MAINALPHA_ON)] _Use_MainAlpha("Use_MainAlpha", Float) = 0
		_Main_XYCount("Main_X/YCount", Vector) = (0,0,0,0)
		_Main_XYPan("Main_X/YPan", Vector) = (0,0,0,0)
		_Main_Intensity("Main_Intensity", Float) = 1
		_Main_Opacity("Main_Opacity", Float) = 1
		_SecondTex("SecondTex", 2D) = "white" {}
		[Toggle(_USE_SECONDALPHA_ON)] _Use_SecondAlpha("Use_SecondAlpha", Float) = 0
		_Second_XYCount("Second_X/YCount", Vector) = (0,0,0,0)
		_Second_XYPan("Second_X/YPan", Vector) = (0,0,0,0)
		_DissolveTex("DissolveTex", 2D) = "white" {}
		_Dissolve("Dissolve", Range( -1 , 1)) = 1
		[Toggle]_Use_DissolveMask("Use_DissolveMask", Float) = 1
		[Toggle]_D_UV_Mask_Switch("D_U/V_Mask_Switch", Float) = 0
		[Toggle]_D_UReverse_Mask("D_UReverse_Mask", Float) = 1
		_D_UMask_Count("D_UMask_Count", Range( -1 , 1)) = 0
		[Toggle]_D_VReverse_Mask("D_VReverse_Mask", Float) = 0
		_D_VMask_Count("D_VMask_Count", Range( -1 , 1)) = 0
		_D_Mask_Value("D_Mask_Value", Range( 0 , 5)) = 1
		[Toggle]_Use_AlphaMask("Use_AlphaMask", Float) = 0
		[Toggle]_A_UV_Mask_Switch("A_U/V_Mask_Switch", Float) = 0
		[Toggle]_Use_A_Gradiant_Mask("Use_A_Gradiant_Mask", Float) = 0
		[Toggle]_A_UReverse_Mask("A_UReverse_Mask", Float) = 0
		_A_UMask_Count("A_UMask_Count", Range( -1 , 1)) = 0
		[Toggle]_A_VReverse_Mask("A_VReverse_Mask", Float) = 0
		_A_VMask_Count("A_VMask_Count", Range( -1 , 1)) = 0
		_A_Mask_Value("A_Mask_Value", Range( 0 , 5)) = 1
		_A_GradiantMask_Value("A_GradiantMask_Value", Float) = 2
		[Toggle]_Use_DepthFade("Use_DepthFade", Float) = 0
		_Depth_Value("Depth_Value", Float) = 1


		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25

		[HideInInspector] _QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector] _QueueControl("_QueueControl", Float) = -1

        [HideInInspector][NoScaleOffset] unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}

		[HideInInspector][ToggleOff] _ReceiveShadows("Receive Shadows", Float) = 1.0
	}

	SubShader
	{
		LOD 0

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" "UniversalMaterialType"="Unlit" }

		Cull [_CullMode]
		AlphaToMask Off

		

		HLSLINCLUDE
		#pragma target 4.5
		#pragma prefer_hlslcc gles
		// ensure rendering platforms toggle list is visible

		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"

		#ifndef ASE_TESS_FUNCS
		#define ASE_TESS_FUNCS
		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}

		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		#endif //ASE_TESS_FUNCS
		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForwardOnly" }

			Blend SrcAlpha [_BlendMode], One OneMinusSrcAlpha
			ZWrite Off
			ZTest [_ZTest1]
			Offset 0 , 0
			ColorMask RGBA

			

			HLSLPROGRAM

			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_SRP_VERSION 140010
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF

			#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
			#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3

			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile_fragment _ DEBUG_DISPLAY
			#pragma multi_compile_fragment _ _WRITE_RENDERING_LAYERS

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_UNLIT

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceData.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature_local _USE_MAINALPHA_ON
			#pragma shader_feature_local _USE_SECONDALPHA_ON


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				half4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 positionWS : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				#ifdef ASE_FOG
					float fogFactor : TEXCOORD2;
				#endif
				float4 ase_color : COLOR;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				float4 ase_texcoord6 : TEXCOORD6;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			half4 _Tint_Color;
			half4 _MainTex_ST;
			half4 _SecondTex_ST;
			half4 _DissolveTex_ST;
			half2 _Main_XYPan;
			half2 _Second_XYCount;
			half2 _Main_XYCount;
			half2 _Second_XYPan;
			half _BlendMode;
			half _D_UMask_Count;
			half _D_VReverse_Mask;
			half _D_VMask_Count;
			half _A_UReverse_Mask;
			half _Use_A_Gradiant_Mask;
			half _A_Mask_Value;
			half _A_UMask_Count;
			half _A_GradiantMask_Value;
			half _A_VReverse_Mask;
			half _A_UV_Mask_Switch;
			half _D_Mask_Value;
			half _Use_Custom_DissUV1;
			half _D_UV_Mask_Switch;
			half _Dissolve;
			half _A_VMask_Count;
			half _Use_DissolveMask;
			half _Main_Opacity;
			half _Use_AlphaMask;
			half _Use_DepthFade;
			half _Main_Intensity;
			half _Use_Custom_OffsetUV2;
			half _ZTest;
			half _CullMode;
			half _D_UReverse_Mask;
			half _Depth_Value;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _MainTex;
			sampler2D _SecondTex;
			sampler2D _DissolveTex;
			uniform float4 _CameraDepthTexture_TexelSize;


			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 ase_clipPos = TransformObjectToHClip((v.positionOS).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord6 = screenPos;
				
				o.ase_color = v.ase_color;
				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				o.ase_texcoord4 = v.ase_texcoord2;
				o.ase_texcoord5 = v.ase_texcoord1;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.positionWS = positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				#ifdef ASE_FOG
					o.fogFactor = ComputeFogFactor( positionCS.z );
				#endif

				o.positionCS = positionCS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				half4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_color = v.ase_color;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord2 = v.ase_texcoord2;
				o.ase_texcoord1 = v.ase_texcoord1;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord2 = patch[0].ase_texcoord2 * bary.x + patch[1].ase_texcoord2 * bary.y + patch[2].ase_texcoord2 * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag ( VertexOutput IN
				#ifdef _WRITE_RENDERING_LAYERS
				, out float4 outRenderingLayers : SV_Target1
				#endif
				 ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.positionWS;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				half2 appendResult71 = (half2(_Main_XYPan.x , _Main_XYPan.y));
				half2 uv_MainTex = IN.ase_texcoord3.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				half2 appendResult68 = (half2((( _Use_Custom_OffsetUV2 )?( IN.ase_texcoord4.x ):( _Main_XYCount.x )) , (( _Use_Custom_OffsetUV2 )?( IN.ase_texcoord4.y ):( _Main_XYCount.y ))));
				half2 panner70 = ( 1.0 * _Time.y * appendResult71 + ( uv_MainTex + appendResult68 ));
				half4 tex2DNode10 = tex2D( _MainTex, panner70 );
				
				half4 temp_cast_1 = (tex2DNode10.a).xxxx;
				#ifdef _USE_MAINALPHA_ON
				half4 staticSwitch125 = temp_cast_1;
				#else
				half4 staticSwitch125 = tex2DNode10;
				#endif
				half4 temp_cast_2 = (0.0).xxxx;
				half4 temp_cast_3 = (1.0).xxxx;
				half2 appendResult78 = (half2(_Second_XYPan.x , _Second_XYPan.y));
				half2 uv_SecondTex = IN.ase_texcoord3.xy * _SecondTex_ST.xy + _SecondTex_ST.zw;
				half2 appendResult81 = (half2((( _Use_Custom_OffsetUV2 )?( IN.ase_texcoord4.z ):( _Second_XYCount.x )) , (( _Use_Custom_OffsetUV2 )?( IN.ase_texcoord4.w ):( _Second_XYCount.y ))));
				half2 panner77 = ( 1.0 * _Time.y * appendResult78 + ( uv_SecondTex + appendResult81 ));
				half4 tex2DNode31 = tex2D( _SecondTex, panner77 );
				half4 temp_cast_4 = (tex2DNode31.a).xxxx;
				#ifdef _USE_SECONDALPHA_ON
				half4 staticSwitch126 = temp_cast_4;
				#else
				half4 staticSwitch126 = tex2DNode31;
				#endif
				half4 temp_cast_5 = (0.0).xxxx;
				half4 temp_cast_6 = (1.0).xxxx;
				half2 uv_DissolveTex = IN.ase_texcoord3.xy * _DissolveTex_ST.xy + _DissolveTex_ST.zw;
				half4 smoothstepResult130 = smoothstep( temp_cast_5 , temp_cast_6 , ( tex2D( _DissolveTex, uv_DissolveTex ) + (( _Use_Custom_DissUV1 )?( IN.ase_texcoord5.x ):( _Dissolve )) ));
				half4 temp_cast_7 = (-1.0).xxxx;
				half4 temp_output_24_0 = ( ( staticSwitch126 + (( _Use_Custom_DissUV1 )?( IN.ase_texcoord5.x ):( _Dissolve )) ) * ( smoothstepResult130 - temp_cast_7 ) );
				half4 temp_cast_8 = (-1.0).xxxx;
				half2 texCoord40 = IN.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				half temp_output_55_0 = texCoord40.x;
				half temp_output_56_0 = texCoord40.y;
				half4 temp_cast_9 = ((( _D_UV_Mask_Switch )?( (( _D_VReverse_Mask )?( ( ( ( 1.0 - temp_output_56_0 ) * _D_Mask_Value ) + _D_VMask_Count ) ):( ( ( temp_output_56_0 * _D_Mask_Value ) + _D_VMask_Count ) )) ):( (( _D_UReverse_Mask )?( ( ( ( 1.0 - temp_output_55_0 ) * _D_Mask_Value ) + _D_UMask_Count ) ):( ( ( temp_output_55_0 * _D_Mask_Value ) + _D_UMask_Count ) )) ))).xxxx;
				half4 smoothstepResult33 = smoothstep( temp_cast_2 , temp_cast_3 , (( _Use_DissolveMask )?( ( temp_output_24_0 - temp_cast_9 ) ):( temp_output_24_0 )));
				half4 temp_output_32_0 = ( ( staticSwitch125 * _Main_Opacity ) * saturate( smoothstepResult33 ) );
				half2 texCoord88 = IN.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				half temp_output_89_0 = ( ( texCoord88.x * _A_Mask_Value ) + _A_UMask_Count );
				half temp_output_114_0 = ( ( ( 1.0 - texCoord88.x ) * _A_Mask_Value ) + _A_UMask_Count );
				half temp_output_91_0 = ( ( texCoord88.y * _A_Mask_Value ) + _A_VMask_Count );
				half temp_output_117_0 = ( ( ( 1.0 - texCoord88.y ) * _A_Mask_Value ) + _A_VMask_Count );
				half4 temp_output_21_0 = ( IN.ase_color.a * (( _Use_AlphaMask )?( ( temp_output_32_0 * saturate( (( _A_UV_Mask_Switch )?( (( _Use_A_Gradiant_Mask )?( ( temp_output_91_0 * temp_output_117_0 * _A_GradiantMask_Value ) ):( (( _A_VReverse_Mask )?( temp_output_117_0 ):( temp_output_91_0 )) )) ):( (( _Use_A_Gradiant_Mask )?( ( temp_output_89_0 * temp_output_114_0 * _A_GradiantMask_Value ) ):( (( _A_UReverse_Mask )?( temp_output_114_0 ):( temp_output_89_0 )) )) )) ) ) ):( temp_output_32_0 )) );
				float4 screenPos = IN.ase_texcoord6;
				half4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float screenDepth133 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				half distanceDepth133 = abs( ( screenDepth133 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _Depth_Value ) );
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = ( IN.ase_color * ( _Tint_Color * ( tex2DNode10 * _Main_Intensity ) ) ).rgb;
				float Alpha = saturate( (( _Use_DepthFade )?( ( temp_output_21_0 * saturate( distanceDepth133 ) ) ):( temp_output_21_0 )) ).r;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					clip( Alpha - AlphaClipThreshold );
				#endif

				#if defined(_DBUFFER)
					ApplyDecalToBaseColor(IN.positionCS, Color);
				#endif

				#if defined(_ALPHAPREMULTIPLY_ON)
				Color *= Alpha;
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.positionCS );
				#endif

				#ifdef ASE_FOG
					Color = MixFog( Color, IN.fogFactor );
				#endif

				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4( EncodeMeshRenderingLayer( renderingLayers ), 0, 0, 0 );
				#endif

				return half4( Color, Alpha );
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask 0
			AlphaToMask Off

			HLSLPROGRAM

			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_SRP_VERSION 140010
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature_local _USE_MAINALPHA_ON
			#pragma shader_feature_local _USE_SECONDALPHA_ON


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				half4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 positionWS : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				float4 ase_color : COLOR;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			half4 _Tint_Color;
			half4 _MainTex_ST;
			half4 _SecondTex_ST;
			half4 _DissolveTex_ST;
			half2 _Main_XYPan;
			half2 _Second_XYCount;
			half2 _Main_XYCount;
			half2 _Second_XYPan;
			half _BlendMode;
			half _D_UMask_Count;
			half _D_VReverse_Mask;
			half _D_VMask_Count;
			half _A_UReverse_Mask;
			half _Use_A_Gradiant_Mask;
			half _A_Mask_Value;
			half _A_UMask_Count;
			half _A_GradiantMask_Value;
			half _A_VReverse_Mask;
			half _A_UV_Mask_Switch;
			half _D_Mask_Value;
			half _Use_Custom_DissUV1;
			half _D_UV_Mask_Switch;
			half _Dissolve;
			half _A_VMask_Count;
			half _Use_DissolveMask;
			half _Main_Opacity;
			half _Use_AlphaMask;
			half _Use_DepthFade;
			half _Main_Intensity;
			half _Use_Custom_OffsetUV2;
			half _ZTest;
			half _CullMode;
			half _D_UReverse_Mask;
			half _Depth_Value;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _MainTex;
			sampler2D _SecondTex;
			sampler2D _DissolveTex;
			uniform float4 _CameraDepthTexture_TexelSize;


			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 ase_clipPos = TransformObjectToHClip((v.positionOS).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord5 = screenPos;
				
				o.ase_color = v.ase_color;
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				o.ase_texcoord3 = v.ase_texcoord2;
				o.ase_texcoord4 = v.ase_texcoord1;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.zw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.positionWS = positionWS;
				#endif

				o.positionCS = TransformWorldToHClip( positionWS );
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = o.positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				half4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_color = v.ase_color;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord2 = v.ase_texcoord2;
				o.ase_texcoord1 = v.ase_texcoord1;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord2 = patch[0].ase_texcoord2 * bary.x + patch[1].ase_texcoord2 * bary.y + patch[2].ase_texcoord2 * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.positionWS;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				half2 appendResult71 = (half2(_Main_XYPan.x , _Main_XYPan.y));
				half2 uv_MainTex = IN.ase_texcoord2.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				half2 appendResult68 = (half2((( _Use_Custom_OffsetUV2 )?( IN.ase_texcoord3.x ):( _Main_XYCount.x )) , (( _Use_Custom_OffsetUV2 )?( IN.ase_texcoord3.y ):( _Main_XYCount.y ))));
				half2 panner70 = ( 1.0 * _Time.y * appendResult71 + ( uv_MainTex + appendResult68 ));
				half4 tex2DNode10 = tex2D( _MainTex, panner70 );
				half4 temp_cast_0 = (tex2DNode10.a).xxxx;
				#ifdef _USE_MAINALPHA_ON
				half4 staticSwitch125 = temp_cast_0;
				#else
				half4 staticSwitch125 = tex2DNode10;
				#endif
				half4 temp_cast_1 = (0.0).xxxx;
				half4 temp_cast_2 = (1.0).xxxx;
				half2 appendResult78 = (half2(_Second_XYPan.x , _Second_XYPan.y));
				half2 uv_SecondTex = IN.ase_texcoord2.xy * _SecondTex_ST.xy + _SecondTex_ST.zw;
				half2 appendResult81 = (half2((( _Use_Custom_OffsetUV2 )?( IN.ase_texcoord3.z ):( _Second_XYCount.x )) , (( _Use_Custom_OffsetUV2 )?( IN.ase_texcoord3.w ):( _Second_XYCount.y ))));
				half2 panner77 = ( 1.0 * _Time.y * appendResult78 + ( uv_SecondTex + appendResult81 ));
				half4 tex2DNode31 = tex2D( _SecondTex, panner77 );
				half4 temp_cast_3 = (tex2DNode31.a).xxxx;
				#ifdef _USE_SECONDALPHA_ON
				half4 staticSwitch126 = temp_cast_3;
				#else
				half4 staticSwitch126 = tex2DNode31;
				#endif
				half4 temp_cast_4 = (0.0).xxxx;
				half4 temp_cast_5 = (1.0).xxxx;
				half2 uv_DissolveTex = IN.ase_texcoord2.xy * _DissolveTex_ST.xy + _DissolveTex_ST.zw;
				half4 smoothstepResult130 = smoothstep( temp_cast_4 , temp_cast_5 , ( tex2D( _DissolveTex, uv_DissolveTex ) + (( _Use_Custom_DissUV1 )?( IN.ase_texcoord4.x ):( _Dissolve )) ));
				half4 temp_cast_6 = (-1.0).xxxx;
				half4 temp_output_24_0 = ( ( staticSwitch126 + (( _Use_Custom_DissUV1 )?( IN.ase_texcoord4.x ):( _Dissolve )) ) * ( smoothstepResult130 - temp_cast_6 ) );
				half4 temp_cast_7 = (-1.0).xxxx;
				half2 texCoord40 = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				half temp_output_55_0 = texCoord40.x;
				half temp_output_56_0 = texCoord40.y;
				half4 temp_cast_8 = ((( _D_UV_Mask_Switch )?( (( _D_VReverse_Mask )?( ( ( ( 1.0 - temp_output_56_0 ) * _D_Mask_Value ) + _D_VMask_Count ) ):( ( ( temp_output_56_0 * _D_Mask_Value ) + _D_VMask_Count ) )) ):( (( _D_UReverse_Mask )?( ( ( ( 1.0 - temp_output_55_0 ) * _D_Mask_Value ) + _D_UMask_Count ) ):( ( ( temp_output_55_0 * _D_Mask_Value ) + _D_UMask_Count ) )) ))).xxxx;
				half4 smoothstepResult33 = smoothstep( temp_cast_1 , temp_cast_2 , (( _Use_DissolveMask )?( ( temp_output_24_0 - temp_cast_8 ) ):( temp_output_24_0 )));
				half4 temp_output_32_0 = ( ( staticSwitch125 * _Main_Opacity ) * saturate( smoothstepResult33 ) );
				half2 texCoord88 = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				half temp_output_89_0 = ( ( texCoord88.x * _A_Mask_Value ) + _A_UMask_Count );
				half temp_output_114_0 = ( ( ( 1.0 - texCoord88.x ) * _A_Mask_Value ) + _A_UMask_Count );
				half temp_output_91_0 = ( ( texCoord88.y * _A_Mask_Value ) + _A_VMask_Count );
				half temp_output_117_0 = ( ( ( 1.0 - texCoord88.y ) * _A_Mask_Value ) + _A_VMask_Count );
				half4 temp_output_21_0 = ( IN.ase_color.a * (( _Use_AlphaMask )?( ( temp_output_32_0 * saturate( (( _A_UV_Mask_Switch )?( (( _Use_A_Gradiant_Mask )?( ( temp_output_91_0 * temp_output_117_0 * _A_GradiantMask_Value ) ):( (( _A_VReverse_Mask )?( temp_output_117_0 ):( temp_output_91_0 )) )) ):( (( _Use_A_Gradiant_Mask )?( ( temp_output_89_0 * temp_output_114_0 * _A_GradiantMask_Value ) ):( (( _A_UReverse_Mask )?( temp_output_114_0 ):( temp_output_89_0 )) )) )) ) ) ):( temp_output_32_0 )) );
				float4 screenPos = IN.ase_texcoord5;
				half4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float screenDepth133 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				half distanceDepth133 = abs( ( screenDepth133 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _Depth_Value ) );
				

				float Alpha = saturate( (( _Use_DepthFade )?( ( temp_output_21_0 * saturate( distanceDepth133 ) ) ):( temp_output_21_0 )) ).r;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.positionCS );
				#endif
				return 0;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "SceneSelectionPass"
			Tags { "LightMode"="SceneSelectionPass" }

			Cull Off
			AlphaToMask Off

			HLSLPROGRAM

			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_SRP_VERSION 140010
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature_local _USE_MAINALPHA_ON
			#pragma shader_feature_local _USE_SECONDALPHA_ON


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				half4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			half4 _Tint_Color;
			half4 _MainTex_ST;
			half4 _SecondTex_ST;
			half4 _DissolveTex_ST;
			half2 _Main_XYPan;
			half2 _Second_XYCount;
			half2 _Main_XYCount;
			half2 _Second_XYPan;
			half _BlendMode;
			half _D_UMask_Count;
			half _D_VReverse_Mask;
			half _D_VMask_Count;
			half _A_UReverse_Mask;
			half _Use_A_Gradiant_Mask;
			half _A_Mask_Value;
			half _A_UMask_Count;
			half _A_GradiantMask_Value;
			half _A_VReverse_Mask;
			half _A_UV_Mask_Switch;
			half _D_Mask_Value;
			half _Use_Custom_DissUV1;
			half _D_UV_Mask_Switch;
			half _Dissolve;
			half _A_VMask_Count;
			half _Use_DissolveMask;
			half _Main_Opacity;
			half _Use_AlphaMask;
			half _Use_DepthFade;
			half _Main_Intensity;
			half _Use_Custom_OffsetUV2;
			half _ZTest;
			half _CullMode;
			half _D_UReverse_Mask;
			half _Depth_Value;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _MainTex;
			sampler2D _SecondTex;
			sampler2D _DissolveTex;
			uniform float4 _CameraDepthTexture_TexelSize;


			
			int _ObjectId;
			int _PassValue;

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 ase_clipPos = TransformObjectToHClip((v.positionOS).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord3 = screenPos;
				
				o.ase_color = v.ase_color;
				o.ase_texcoord.xy = v.ase_texcoord.xy;
				o.ase_texcoord1 = v.ase_texcoord2;
				o.ase_texcoord2 = v.ase_texcoord1;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord.zw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );

				o.positionCS = TransformWorldToHClip(positionWS);

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				half4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_color = v.ase_color;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord2 = v.ase_texcoord2;
				o.ase_texcoord1 = v.ase_texcoord1;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord2 = patch[0].ase_texcoord2 * bary.x + patch[1].ase_texcoord2 * bary.y + patch[2].ase_texcoord2 * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				half2 appendResult71 = (half2(_Main_XYPan.x , _Main_XYPan.y));
				half2 uv_MainTex = IN.ase_texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				half2 appendResult68 = (half2((( _Use_Custom_OffsetUV2 )?( IN.ase_texcoord1.x ):( _Main_XYCount.x )) , (( _Use_Custom_OffsetUV2 )?( IN.ase_texcoord1.y ):( _Main_XYCount.y ))));
				half2 panner70 = ( 1.0 * _Time.y * appendResult71 + ( uv_MainTex + appendResult68 ));
				half4 tex2DNode10 = tex2D( _MainTex, panner70 );
				half4 temp_cast_0 = (tex2DNode10.a).xxxx;
				#ifdef _USE_MAINALPHA_ON
				half4 staticSwitch125 = temp_cast_0;
				#else
				half4 staticSwitch125 = tex2DNode10;
				#endif
				half4 temp_cast_1 = (0.0).xxxx;
				half4 temp_cast_2 = (1.0).xxxx;
				half2 appendResult78 = (half2(_Second_XYPan.x , _Second_XYPan.y));
				half2 uv_SecondTex = IN.ase_texcoord.xy * _SecondTex_ST.xy + _SecondTex_ST.zw;
				half2 appendResult81 = (half2((( _Use_Custom_OffsetUV2 )?( IN.ase_texcoord1.z ):( _Second_XYCount.x )) , (( _Use_Custom_OffsetUV2 )?( IN.ase_texcoord1.w ):( _Second_XYCount.y ))));
				half2 panner77 = ( 1.0 * _Time.y * appendResult78 + ( uv_SecondTex + appendResult81 ));
				half4 tex2DNode31 = tex2D( _SecondTex, panner77 );
				half4 temp_cast_3 = (tex2DNode31.a).xxxx;
				#ifdef _USE_SECONDALPHA_ON
				half4 staticSwitch126 = temp_cast_3;
				#else
				half4 staticSwitch126 = tex2DNode31;
				#endif
				half4 temp_cast_4 = (0.0).xxxx;
				half4 temp_cast_5 = (1.0).xxxx;
				half2 uv_DissolveTex = IN.ase_texcoord.xy * _DissolveTex_ST.xy + _DissolveTex_ST.zw;
				half4 smoothstepResult130 = smoothstep( temp_cast_4 , temp_cast_5 , ( tex2D( _DissolveTex, uv_DissolveTex ) + (( _Use_Custom_DissUV1 )?( IN.ase_texcoord2.x ):( _Dissolve )) ));
				half4 temp_cast_6 = (-1.0).xxxx;
				half4 temp_output_24_0 = ( ( staticSwitch126 + (( _Use_Custom_DissUV1 )?( IN.ase_texcoord2.x ):( _Dissolve )) ) * ( smoothstepResult130 - temp_cast_6 ) );
				half4 temp_cast_7 = (-1.0).xxxx;
				half2 texCoord40 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				half temp_output_55_0 = texCoord40.x;
				half temp_output_56_0 = texCoord40.y;
				half4 temp_cast_8 = ((( _D_UV_Mask_Switch )?( (( _D_VReverse_Mask )?( ( ( ( 1.0 - temp_output_56_0 ) * _D_Mask_Value ) + _D_VMask_Count ) ):( ( ( temp_output_56_0 * _D_Mask_Value ) + _D_VMask_Count ) )) ):( (( _D_UReverse_Mask )?( ( ( ( 1.0 - temp_output_55_0 ) * _D_Mask_Value ) + _D_UMask_Count ) ):( ( ( temp_output_55_0 * _D_Mask_Value ) + _D_UMask_Count ) )) ))).xxxx;
				half4 smoothstepResult33 = smoothstep( temp_cast_1 , temp_cast_2 , (( _Use_DissolveMask )?( ( temp_output_24_0 - temp_cast_8 ) ):( temp_output_24_0 )));
				half4 temp_output_32_0 = ( ( staticSwitch125 * _Main_Opacity ) * saturate( smoothstepResult33 ) );
				half2 texCoord88 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				half temp_output_89_0 = ( ( texCoord88.x * _A_Mask_Value ) + _A_UMask_Count );
				half temp_output_114_0 = ( ( ( 1.0 - texCoord88.x ) * _A_Mask_Value ) + _A_UMask_Count );
				half temp_output_91_0 = ( ( texCoord88.y * _A_Mask_Value ) + _A_VMask_Count );
				half temp_output_117_0 = ( ( ( 1.0 - texCoord88.y ) * _A_Mask_Value ) + _A_VMask_Count );
				half4 temp_output_21_0 = ( IN.ase_color.a * (( _Use_AlphaMask )?( ( temp_output_32_0 * saturate( (( _A_UV_Mask_Switch )?( (( _Use_A_Gradiant_Mask )?( ( temp_output_91_0 * temp_output_117_0 * _A_GradiantMask_Value ) ):( (( _A_VReverse_Mask )?( temp_output_117_0 ):( temp_output_91_0 )) )) ):( (( _Use_A_Gradiant_Mask )?( ( temp_output_89_0 * temp_output_114_0 * _A_GradiantMask_Value ) ):( (( _A_UReverse_Mask )?( temp_output_114_0 ):( temp_output_89_0 )) )) )) ) ) ):( temp_output_32_0 )) );
				float4 screenPos = IN.ase_texcoord3;
				half4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float screenDepth133 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				half distanceDepth133 = abs( ( screenDepth133 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _Depth_Value ) );
				

				surfaceDescription.Alpha = saturate( (( _Use_DepthFade )?( ( temp_output_21_0 * saturate( distanceDepth133 ) ) ):( temp_output_21_0 )) ).r;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
					clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = half4(_ObjectId, _PassValue, 1.0, 1.0);
				return outColor;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "ScenePickingPass"
			Tags { "LightMode"="Picking" }

			AlphaToMask Off

			HLSLPROGRAM

			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_SRP_VERSION 140010
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT

			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature_local _USE_MAINALPHA_ON
			#pragma shader_feature_local _USE_SECONDALPHA_ON


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				half4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			half4 _Tint_Color;
			half4 _MainTex_ST;
			half4 _SecondTex_ST;
			half4 _DissolveTex_ST;
			half2 _Main_XYPan;
			half2 _Second_XYCount;
			half2 _Main_XYCount;
			half2 _Second_XYPan;
			half _BlendMode;
			half _D_UMask_Count;
			half _D_VReverse_Mask;
			half _D_VMask_Count;
			half _A_UReverse_Mask;
			half _Use_A_Gradiant_Mask;
			half _A_Mask_Value;
			half _A_UMask_Count;
			half _A_GradiantMask_Value;
			half _A_VReverse_Mask;
			half _A_UV_Mask_Switch;
			half _D_Mask_Value;
			half _Use_Custom_DissUV1;
			half _D_UV_Mask_Switch;
			half _Dissolve;
			half _A_VMask_Count;
			half _Use_DissolveMask;
			half _Main_Opacity;
			half _Use_AlphaMask;
			half _Use_DepthFade;
			half _Main_Intensity;
			half _Use_Custom_OffsetUV2;
			half _ZTest;
			half _CullMode;
			half _D_UReverse_Mask;
			half _Depth_Value;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _MainTex;
			sampler2D _SecondTex;
			sampler2D _DissolveTex;
			uniform float4 _CameraDepthTexture_TexelSize;


			
			float4 _SelectionID;

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 ase_clipPos = TransformObjectToHClip((v.positionOS).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord3 = screenPos;
				
				o.ase_color = v.ase_color;
				o.ase_texcoord.xy = v.ase_texcoord.xy;
				o.ase_texcoord1 = v.ase_texcoord2;
				o.ase_texcoord2 = v.ase_texcoord1;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord.zw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );
				o.positionCS = TransformWorldToHClip(positionWS);
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				half4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_color = v.ase_color;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord2 = v.ase_texcoord2;
				o.ase_texcoord1 = v.ase_texcoord1;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord2 = patch[0].ase_texcoord2 * bary.x + patch[1].ase_texcoord2 * bary.y + patch[2].ase_texcoord2 * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				half2 appendResult71 = (half2(_Main_XYPan.x , _Main_XYPan.y));
				half2 uv_MainTex = IN.ase_texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				half2 appendResult68 = (half2((( _Use_Custom_OffsetUV2 )?( IN.ase_texcoord1.x ):( _Main_XYCount.x )) , (( _Use_Custom_OffsetUV2 )?( IN.ase_texcoord1.y ):( _Main_XYCount.y ))));
				half2 panner70 = ( 1.0 * _Time.y * appendResult71 + ( uv_MainTex + appendResult68 ));
				half4 tex2DNode10 = tex2D( _MainTex, panner70 );
				half4 temp_cast_0 = (tex2DNode10.a).xxxx;
				#ifdef _USE_MAINALPHA_ON
				half4 staticSwitch125 = temp_cast_0;
				#else
				half4 staticSwitch125 = tex2DNode10;
				#endif
				half4 temp_cast_1 = (0.0).xxxx;
				half4 temp_cast_2 = (1.0).xxxx;
				half2 appendResult78 = (half2(_Second_XYPan.x , _Second_XYPan.y));
				half2 uv_SecondTex = IN.ase_texcoord.xy * _SecondTex_ST.xy + _SecondTex_ST.zw;
				half2 appendResult81 = (half2((( _Use_Custom_OffsetUV2 )?( IN.ase_texcoord1.z ):( _Second_XYCount.x )) , (( _Use_Custom_OffsetUV2 )?( IN.ase_texcoord1.w ):( _Second_XYCount.y ))));
				half2 panner77 = ( 1.0 * _Time.y * appendResult78 + ( uv_SecondTex + appendResult81 ));
				half4 tex2DNode31 = tex2D( _SecondTex, panner77 );
				half4 temp_cast_3 = (tex2DNode31.a).xxxx;
				#ifdef _USE_SECONDALPHA_ON
				half4 staticSwitch126 = temp_cast_3;
				#else
				half4 staticSwitch126 = tex2DNode31;
				#endif
				half4 temp_cast_4 = (0.0).xxxx;
				half4 temp_cast_5 = (1.0).xxxx;
				half2 uv_DissolveTex = IN.ase_texcoord.xy * _DissolveTex_ST.xy + _DissolveTex_ST.zw;
				half4 smoothstepResult130 = smoothstep( temp_cast_4 , temp_cast_5 , ( tex2D( _DissolveTex, uv_DissolveTex ) + (( _Use_Custom_DissUV1 )?( IN.ase_texcoord2.x ):( _Dissolve )) ));
				half4 temp_cast_6 = (-1.0).xxxx;
				half4 temp_output_24_0 = ( ( staticSwitch126 + (( _Use_Custom_DissUV1 )?( IN.ase_texcoord2.x ):( _Dissolve )) ) * ( smoothstepResult130 - temp_cast_6 ) );
				half4 temp_cast_7 = (-1.0).xxxx;
				half2 texCoord40 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				half temp_output_55_0 = texCoord40.x;
				half temp_output_56_0 = texCoord40.y;
				half4 temp_cast_8 = ((( _D_UV_Mask_Switch )?( (( _D_VReverse_Mask )?( ( ( ( 1.0 - temp_output_56_0 ) * _D_Mask_Value ) + _D_VMask_Count ) ):( ( ( temp_output_56_0 * _D_Mask_Value ) + _D_VMask_Count ) )) ):( (( _D_UReverse_Mask )?( ( ( ( 1.0 - temp_output_55_0 ) * _D_Mask_Value ) + _D_UMask_Count ) ):( ( ( temp_output_55_0 * _D_Mask_Value ) + _D_UMask_Count ) )) ))).xxxx;
				half4 smoothstepResult33 = smoothstep( temp_cast_1 , temp_cast_2 , (( _Use_DissolveMask )?( ( temp_output_24_0 - temp_cast_8 ) ):( temp_output_24_0 )));
				half4 temp_output_32_0 = ( ( staticSwitch125 * _Main_Opacity ) * saturate( smoothstepResult33 ) );
				half2 texCoord88 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				half temp_output_89_0 = ( ( texCoord88.x * _A_Mask_Value ) + _A_UMask_Count );
				half temp_output_114_0 = ( ( ( 1.0 - texCoord88.x ) * _A_Mask_Value ) + _A_UMask_Count );
				half temp_output_91_0 = ( ( texCoord88.y * _A_Mask_Value ) + _A_VMask_Count );
				half temp_output_117_0 = ( ( ( 1.0 - texCoord88.y ) * _A_Mask_Value ) + _A_VMask_Count );
				half4 temp_output_21_0 = ( IN.ase_color.a * (( _Use_AlphaMask )?( ( temp_output_32_0 * saturate( (( _A_UV_Mask_Switch )?( (( _Use_A_Gradiant_Mask )?( ( temp_output_91_0 * temp_output_117_0 * _A_GradiantMask_Value ) ):( (( _A_VReverse_Mask )?( temp_output_117_0 ):( temp_output_91_0 )) )) ):( (( _Use_A_Gradiant_Mask )?( ( temp_output_89_0 * temp_output_114_0 * _A_GradiantMask_Value ) ):( (( _A_UReverse_Mask )?( temp_output_114_0 ):( temp_output_89_0 )) )) )) ) ) ):( temp_output_32_0 )) );
				float4 screenPos = IN.ase_texcoord3;
				half4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float screenDepth133 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				half distanceDepth133 = abs( ( screenDepth133 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _Depth_Value ) );
				

				surfaceDescription.Alpha = saturate( (( _Use_DepthFade )?( ( temp_output_21_0 * saturate( distanceDepth133 ) ) ):( temp_output_21_0 )) ).r;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
					clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = 0;
				outColor = _SelectionID;

				return outColor;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthNormals"
			Tags { "LightMode"="DepthNormalsOnly" }

			ZTest LEqual
			ZWrite On

			HLSLPROGRAM

			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_SRP_VERSION 140010
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_fragment _ _WRITE_RENDERING_LAYERS
        	#pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define VARYINGS_NEED_NORMAL_WS

			#define SHADERPASS SHADERPASS_DEPTHNORMALSONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

            #if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature_local _USE_MAINALPHA_ON
			#pragma shader_feature_local _USE_SECONDALPHA_ON


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				half4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float3 normalWS : TEXCOORD0;
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			half4 _Tint_Color;
			half4 _MainTex_ST;
			half4 _SecondTex_ST;
			half4 _DissolveTex_ST;
			half2 _Main_XYPan;
			half2 _Second_XYCount;
			half2 _Main_XYCount;
			half2 _Second_XYPan;
			half _BlendMode;
			half _D_UMask_Count;
			half _D_VReverse_Mask;
			half _D_VMask_Count;
			half _A_UReverse_Mask;
			half _Use_A_Gradiant_Mask;
			half _A_Mask_Value;
			half _A_UMask_Count;
			half _A_GradiantMask_Value;
			half _A_VReverse_Mask;
			half _A_UV_Mask_Switch;
			half _D_Mask_Value;
			half _Use_Custom_DissUV1;
			half _D_UV_Mask_Switch;
			half _Dissolve;
			half _A_VMask_Count;
			half _Use_DissolveMask;
			half _Main_Opacity;
			half _Use_AlphaMask;
			half _Use_DepthFade;
			half _Main_Intensity;
			half _Use_Custom_OffsetUV2;
			half _ZTest;
			half _CullMode;
			half _D_UReverse_Mask;
			half _Depth_Value;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _MainTex;
			sampler2D _SecondTex;
			sampler2D _DissolveTex;
			uniform float4 _CameraDepthTexture_TexelSize;


			
			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 ase_clipPos = TransformObjectToHClip((v.positionOS).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord4 = screenPos;
				
				o.ase_color = v.ase_color;
				o.ase_texcoord1.xy = v.ase_texcoord.xy;
				o.ase_texcoord2 = v.ase_texcoord2;
				o.ase_texcoord3 = v.ase_texcoord1;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.zw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );
				float3 normalWS = TransformObjectToWorldNormal(v.normalOS);

				o.positionCS = TransformWorldToHClip(positionWS);
				o.normalWS.xyz =  normalWS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				half4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_color = v.ase_color;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord2 = v.ase_texcoord2;
				o.ase_texcoord1 = v.ase_texcoord1;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord2 = patch[0].ase_texcoord2 * bary.x + patch[1].ase_texcoord2 * bary.y + patch[2].ase_texcoord2 * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			void frag( VertexOutput IN
				, out half4 outNormalWS : SV_Target0
			#ifdef _WRITE_RENDERING_LAYERS
				, out float4 outRenderingLayers : SV_Target1
			#endif
				 )
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				half2 appendResult71 = (half2(_Main_XYPan.x , _Main_XYPan.y));
				half2 uv_MainTex = IN.ase_texcoord1.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				half2 appendResult68 = (half2((( _Use_Custom_OffsetUV2 )?( IN.ase_texcoord2.x ):( _Main_XYCount.x )) , (( _Use_Custom_OffsetUV2 )?( IN.ase_texcoord2.y ):( _Main_XYCount.y ))));
				half2 panner70 = ( 1.0 * _Time.y * appendResult71 + ( uv_MainTex + appendResult68 ));
				half4 tex2DNode10 = tex2D( _MainTex, panner70 );
				half4 temp_cast_0 = (tex2DNode10.a).xxxx;
				#ifdef _USE_MAINALPHA_ON
				half4 staticSwitch125 = temp_cast_0;
				#else
				half4 staticSwitch125 = tex2DNode10;
				#endif
				half4 temp_cast_1 = (0.0).xxxx;
				half4 temp_cast_2 = (1.0).xxxx;
				half2 appendResult78 = (half2(_Second_XYPan.x , _Second_XYPan.y));
				half2 uv_SecondTex = IN.ase_texcoord1.xy * _SecondTex_ST.xy + _SecondTex_ST.zw;
				half2 appendResult81 = (half2((( _Use_Custom_OffsetUV2 )?( IN.ase_texcoord2.z ):( _Second_XYCount.x )) , (( _Use_Custom_OffsetUV2 )?( IN.ase_texcoord2.w ):( _Second_XYCount.y ))));
				half2 panner77 = ( 1.0 * _Time.y * appendResult78 + ( uv_SecondTex + appendResult81 ));
				half4 tex2DNode31 = tex2D( _SecondTex, panner77 );
				half4 temp_cast_3 = (tex2DNode31.a).xxxx;
				#ifdef _USE_SECONDALPHA_ON
				half4 staticSwitch126 = temp_cast_3;
				#else
				half4 staticSwitch126 = tex2DNode31;
				#endif
				half4 temp_cast_4 = (0.0).xxxx;
				half4 temp_cast_5 = (1.0).xxxx;
				half2 uv_DissolveTex = IN.ase_texcoord1.xy * _DissolveTex_ST.xy + _DissolveTex_ST.zw;
				half4 smoothstepResult130 = smoothstep( temp_cast_4 , temp_cast_5 , ( tex2D( _DissolveTex, uv_DissolveTex ) + (( _Use_Custom_DissUV1 )?( IN.ase_texcoord3.x ):( _Dissolve )) ));
				half4 temp_cast_6 = (-1.0).xxxx;
				half4 temp_output_24_0 = ( ( staticSwitch126 + (( _Use_Custom_DissUV1 )?( IN.ase_texcoord3.x ):( _Dissolve )) ) * ( smoothstepResult130 - temp_cast_6 ) );
				half4 temp_cast_7 = (-1.0).xxxx;
				half2 texCoord40 = IN.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				half temp_output_55_0 = texCoord40.x;
				half temp_output_56_0 = texCoord40.y;
				half4 temp_cast_8 = ((( _D_UV_Mask_Switch )?( (( _D_VReverse_Mask )?( ( ( ( 1.0 - temp_output_56_0 ) * _D_Mask_Value ) + _D_VMask_Count ) ):( ( ( temp_output_56_0 * _D_Mask_Value ) + _D_VMask_Count ) )) ):( (( _D_UReverse_Mask )?( ( ( ( 1.0 - temp_output_55_0 ) * _D_Mask_Value ) + _D_UMask_Count ) ):( ( ( temp_output_55_0 * _D_Mask_Value ) + _D_UMask_Count ) )) ))).xxxx;
				half4 smoothstepResult33 = smoothstep( temp_cast_1 , temp_cast_2 , (( _Use_DissolveMask )?( ( temp_output_24_0 - temp_cast_8 ) ):( temp_output_24_0 )));
				half4 temp_output_32_0 = ( ( staticSwitch125 * _Main_Opacity ) * saturate( smoothstepResult33 ) );
				half2 texCoord88 = IN.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				half temp_output_89_0 = ( ( texCoord88.x * _A_Mask_Value ) + _A_UMask_Count );
				half temp_output_114_0 = ( ( ( 1.0 - texCoord88.x ) * _A_Mask_Value ) + _A_UMask_Count );
				half temp_output_91_0 = ( ( texCoord88.y * _A_Mask_Value ) + _A_VMask_Count );
				half temp_output_117_0 = ( ( ( 1.0 - texCoord88.y ) * _A_Mask_Value ) + _A_VMask_Count );
				half4 temp_output_21_0 = ( IN.ase_color.a * (( _Use_AlphaMask )?( ( temp_output_32_0 * saturate( (( _A_UV_Mask_Switch )?( (( _Use_A_Gradiant_Mask )?( ( temp_output_91_0 * temp_output_117_0 * _A_GradiantMask_Value ) ):( (( _A_VReverse_Mask )?( temp_output_117_0 ):( temp_output_91_0 )) )) ):( (( _Use_A_Gradiant_Mask )?( ( temp_output_89_0 * temp_output_114_0 * _A_GradiantMask_Value ) ):( (( _A_UReverse_Mask )?( temp_output_114_0 ):( temp_output_89_0 )) )) )) ) ) ):( temp_output_32_0 )) );
				float4 screenPos = IN.ase_texcoord4;
				half4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float screenDepth133 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				half distanceDepth133 = abs( ( screenDepth133 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _Depth_Value ) );
				

				surfaceDescription.Alpha = saturate( (( _Use_DepthFade )?( ( temp_output_21_0 * saturate( distanceDepth133 ) ) ):( temp_output_21_0 )) ).r;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					clip(surfaceDescription.Alpha - surfaceDescription.AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.positionCS );
				#endif

				#if defined(_GBUFFER_NORMALS_OCT)
					float3 normalWS = normalize(IN.normalWS);
					float2 octNormalWS = PackNormalOctQuadEncode(normalWS);           // values between [-1, +1], must use fp32 on some platforms
					float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);   // values between [ 0,  1]
					half3 packedNormalWS = PackFloat2To888(remappedOctNormalWS);      // values between [ 0,  1]
					outNormalWS = half4(packedNormalWS, 0.0);
				#else
					float3 normalWS = IN.normalWS;
					outNormalWS = half4(NormalizeNormalPerPixel(normalWS), 0.0);
				#endif

				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
				#endif
			}

			ENDHLSL
		}

	
	}
	
	CustomEditor "UnityEditor.ShaderGraphUnlitGUI"
	FallBack "Hidden/Shader Graph/FallbackError"
	
	Fallback Off
}
/*ASEBEGIN
Version=19201
Node;AmplifyShaderEditor.CommentaryNode;121;-929.7448,1281.936;Inherit;False;2361.764;1290.6;Alpha_Mask;23;88;95;97;94;93;89;112;113;114;96;115;116;99;91;117;102;103;118;100;101;104;119;120;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;111;-3284.141,1053.458;Inherit;False;2078.089;1258.015;Dissolve_Mask;19;41;44;40;64;54;49;65;106;107;43;108;47;55;56;46;109;66;45;110;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;29;-1017.784,815.0744;Inherit;False;Constant;_Float0;Float 0;3;0;Create;True;0;0;0;False;0;False;-1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;36;-242.7841,-420.5797;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;28;-765.9028,641.4592;Inherit;True;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;24;-545.5463,447.991;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;52;-359.0815,880.5367;Inherit;True;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=ShadowCaster;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;False;False;True;1;LightMode=DepthOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;5;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Universal2D;0;5;Universal2D;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=Universal2D;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;6;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;SceneSelectionPass;0;6;SceneSelectionPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=SceneSelectionPass;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;7;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ScenePickingPass;0;7;ScenePickingPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Picking;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;8;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthNormals;0;8;DepthNormals;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;9;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthNormalsOnly;0;9;DepthNormalsOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;True;9;d3d11;metal;vulkan;xboxone;xboxseries;playstation;ps4;ps5;switch;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.RangedFloatNode;34;-113.6805,86.54824;Inherit;False;Constant;_Float1;Float 1;4;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;35;-128.3161,204.3191;Inherit;False;Constant;_Float2;Float 2;4;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;33;65.28728,347.3635;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;1,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;11;-1934.376,-532.2035;Inherit;False;0;10;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;67;-1586.471,-556.7945;Inherit;True;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;10;-988.4237,-562.7601;Inherit;True;Property;_MainTex;MainTex;6;0;Create;True;0;0;0;False;0;False;-1;cefaa4d61ab66204292af1c18f58e5f6;cefaa4d61ab66204292af1c18f58e5f6;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;70;-1211.702,-547.9971;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;71;-1382.371,-270.0017;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;68;-1838.073,-291.115;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;30;-1779.912,1.576551;Inherit;False;0;31;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;31;-1053.894,-14.72256;Inherit;True;Property;_SecondTex;SecondTex;12;0;Create;True;0;0;0;False;0;False;-1;cefaa4d61ab66204292af1c18f58e5f6;cefaa4d61ab66204292af1c18f58e5f6;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;77;-1255.689,7.99363;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;76;-1436.914,7.993588;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;72;-1581.191,-299.9124;Inherit;False;Property;_Main_XYPan;Main_X/YPan;9;0;Create;True;0;0;0;False;0;False;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.RangedFloatNode;15;-2421.424,497.2584;Inherit;False;Property;_Dissolve;Dissolve;17;0;Create;True;0;0;0;False;0;False;1;-0.5865169;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;39;-2060.161,499.7256;Inherit;False;Property;_Use_Custom_DissUV1;Use_Custom_Diss/UV1;3;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;81;-1752.186,154.8214;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;69;-2398.672,-316.0693;Inherit;False;Property;_Main_XYCount;Main_X/YCount;8;0;Create;True;0;0;0;False;0;False;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.ToggleSwitchNode;74;-2149.088,-283.5341;Inherit;False;Property;_Use_Custom_OffsetUV2;Use_Custom_Offset/UV2;4;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;75;-2149.8,-162.6638;Inherit;False;Property;_Use_Custom_OffsetUV2;Use_Custom_Offset/UV2;15;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;82;-2362.835,60.50008;Inherit;False;Property;_Second_XYCount;Second_X/YCount;14;0;Create;True;0;0;0;False;0;False;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.ToggleSwitchNode;84;-2099.454,166.8811;Inherit;False;Property;_Use_Custom_OffsetUV2;Use_Custom_Offset/UV2;1;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;83;-2102.454,45.10118;Inherit;False;Property;_Use_Custom_OffsetUV2;Use_Custom_Offset/UV2;1;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;78;-1345.736,259.7626;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;80;-1594.67,228.7083;Inherit;False;Property;_Second_XYPan;Second_X/YPan;15;0;Create;True;0;0;0;False;0;False;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TexCoordVertexDataNode;38;-2858.226,-180.2152;Inherit;False;1;4;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexCoordVertexDataNode;73;-2840.863,46.33923;Inherit;False;2;4;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;19;279.0844,-517.3622;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;86;-240.4762,-725.9705;Inherit;False;Property;_Tint_Color;Tint_Color;5;1;[HDR];Create;True;0;0;0;False;0;False;1,1,1,1;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;87;68.44827,-422.7932;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ToggleSwitchNode;53;-207.6642,567.9669;Inherit;False;Property;_Use_DissolveMask;Use_DissolveMask;18;0;Create;True;0;0;0;False;0;False;1;True;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;41;-2207.281,1464.143;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;44;-2207.279,1749.589;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;40;-3234.141,1571.44;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;64;-2554.442,1460.156;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;54;-1792.961,1752.231;Inherit;False;Property;_D_VReverse_Mask;D_VReverse_Mask;22;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;65;-2971.277,1620.409;Inherit;False;Property;_D_Mask_Value;D_Mask_Value;24;0;Create;True;0;0;0;False;0;False;1;1;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;106;-2892.245,1103.458;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;107;-2634.25,1103.458;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;43;-2599.705,1353.275;Inherit;False;Property;_D_UMask_Count;D_UMask_Count;21;0;Create;True;0;0;0;False;0;False;0;1;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;108;-2225.993,1117.633;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;47;-1819.511,1321.291;Inherit;True;Property;_D_UReverse_Mask;D_UReverse_Mask;20;0;Create;True;0;0;0;False;0;False;1;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;55;-2990.648,1494.828;Inherit;False;True;True;True;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;56;-2975.298,1725.904;Inherit;False;True;True;True;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;46;-2838.953,2051.634;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;109;-2598.81,2108.504;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;66;-2551.122,1708.541;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;45;-2616.873,1950.953;Inherit;False;Property;_D_VMask_Count;D_VMask_Count;23;0;Create;True;0;0;0;False;0;False;0;1;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;110;-2196.224,2057.473;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;49;-1478.696,1589.137;Inherit;True;Property;_D_UV_Mask_Switch;D_U/V_Mask_Switch;19;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;88;-879.7448,1829.69;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;95;-629.7762,1862.839;Inherit;False;Property;_A_Mask_Value;A_Mask_Value;32;0;Create;True;0;0;0;False;0;False;1;0;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;94;-334.7764,1967.839;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;93;-313.7764,1727.839;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;89;-24.29232,1740.909;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;112;-618.3,1442.18;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;113;-356.5746,1361.13;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;114;-64.45542,1362.818;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;96;-333.2512,1622.905;Inherit;False;Property;_A_UMask_Count;A_UMask_Count;29;0;Create;True;0;0;0;False;0;False;0;0;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;115;-608.1686,2257.749;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;116;-348.1319,2266.192;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;99;-354.4315,2115.347;Inherit;False;Property;_A_VMask_Count;A_VMask_Count;31;0;Create;True;0;0;0;False;0;False;0;0;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;91;-43.93546,2028.311;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;117;-39.12693,2318.536;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;102;405.8388,1331.936;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;103;113.9524,1951.662;Inherit;False;Property;_A_GradiantMask_Value;A_GradiantMask_Value;33;0;Create;True;0;0;0;False;0;False;2;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;118;372.957,2300.309;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;100;442.9446,1804.379;Inherit;False;Property;_A_UReverse_Mask;A_UReverse_Mask;28;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;101;442.9071,2045.167;Inherit;False;Property;_A_VReverse_Mask;A_VReverse_Mask;30;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;119;806.6558,1792.945;Inherit;True;Property;_Use_A_Gradiant_Mask;Use_A_Gradiant_Mask;27;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;120;812.5264,2039.512;Inherit;True;Property;_Use_A_Gradiant_Mask;Use_A_Gradiant_Mask;29;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;1077.068,-26.66789;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;0;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.ToggleSwitchNode;104;1158.019,1927.958;Inherit;False;Property;_A_UV_Mask_Switch;A_U/V_Mask_Switch;26;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;22;311.9206,346.5307;Inherit;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ComponentMaskNode;97;1201.591,1551.66;Inherit;False;True;True;True;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;14;-394.2113,195.6344;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.StaticSwitch;126;-664.8029,116.276;Inherit;False;Property;_Use_SecondAlpha;Use_SecondAlpha;13;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ToggleSwitchNode;122;940.2446,63.77317;Inherit;False;Property;_Use_AlphaMask;Use_AlphaMask;25;0;Create;True;0;0;0;False;0;False;0;True;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;32;380.0956,3.900694;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;127;721.7753,144.5156;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;37;-418.0248,-187.3268;Inherit;False;Property;_Main_Intensity;Main_Intensity;10;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;125;-233.4108,-183.3046;Inherit;False;Property;_Use_MainAlpha;Use_MainAlpha;7;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;128;143.2901,-59.35343;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;129;-135.9355,-44.26013;Inherit;False;Property;_Main_Opacity;Main_Opacity;11;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;26;-1684.307,691.6544;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;131;-1426.163,748.5788;Inherit;False;Constant;_Float3;Float 3;35;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;132;-1421.33,835.2377;Inherit;False;Constant;_Float4;Float 4;35;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;130;-1233.669,689.0608;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;1,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;13;-2304.86,619.4266;Inherit;False;0;12;2;3;2;SAMPLER2D;;False;0;FLOAT2;30,30;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;12;-2062.717,709.3895;Inherit;True;Property;_DissolveTex;DissolveTex;16;0;Create;True;0;0;0;False;0;False;-1;None;cefaa4d61ab66204292af1c18f58e5f6;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;2232.844,-79.6555;Half;False;True;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;Coloso/Unlit/S_MainUnlit;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;True;True;2;True;_CullMode;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;True;True;2;5;False;;10;True;_BlendMode;1;1;False;;10;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;True;True;2;False;;True;3;True;_ZTest1;True;True;0;False;;0;False;;True;1;LightMode=UniversalForwardOnly;False;False;0;;0;0;Standard;22;Surface;1;638481447225771442;  Blend;0;0;Two Sided;0;638481447313677658;Forward Only;0;0;Cast Shadows;0;638481447243928049;  Use Shadow Threshold;0;0;GPU Instancing;0;638481447248240367;LOD CrossFade;0;638481447251022327;Built-in Fog;0;638481447253207993;DOTS Instancing;0;0;Meta Pass;0;0;Extra Pre Pass;0;0;Tessellation;0;0;  Phong;0;0;  Strength;0.5,False,;0;  Type;0;0;  Tess;16,False,;0;  Min;10,False,;0;  Max;25,False,;0;  Edge Length;16,False,;0;  Max Displacement;25,False,;0;Vertex Position,InvertActionOnDeselection;1;0;0;10;False;True;False;True;False;False;True;True;True;False;False;;False;0
Node;AmplifyShaderEditor.SaturateNode;124;1914.633,8.753946;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;1612.578,-187.7091;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;123;720.9023,851.4641;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DepthFade;133;901.2324,435.2202;Inherit;False;True;False;True;2;1;FLOAT3;0,0,0;False;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;134;685.8973,462.617;Inherit;False;Property;_Depth_Value;Depth_Value;35;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;135;1248.759,373.1905;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;21;1245.303,55.25524;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;136;1501.257,214.0639;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ToggleSwitchNode;137;1724.823,98.33537;Inherit;False;Property;_Use_DepthFade;Use_DepthFade;34;0;Create;True;0;0;0;False;0;False;0;True;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.CommentaryNode;138;1941.647,402.5515;Inherit;False;370.3481;243.2074;Blend;3;141;140;139;Blend;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;140;1970.839,474.7585;Inherit;False;Property;_BlendMode;BlendMode;0;1;[Enum];Create;True;0;3;Additive;1;AlphaBlend;10;Premultiply;6;0;True;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;139;2147.684,475.0406;Inherit;False;Property;_CullMode;CullMode;1;1;[Enum];Create;True;0;0;1;UnityEngine.Rendering.CullMode;True;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;141;1989.829,550.7204;Inherit;False;Property;_ZTest;ZTest;2;1;[Enum];Create;True;0;2;LessEqual;4;Always;8;0;True;0;False;0;0;0;0;0;1;FLOAT;0
WireConnection;36;0;10;0
WireConnection;36;1;37;0
WireConnection;28;0;130;0
WireConnection;28;1;29;0
WireConnection;24;0;14;0
WireConnection;24;1;28;0
WireConnection;52;0;24;0
WireConnection;52;1;49;0
WireConnection;33;0;53;0
WireConnection;33;1;34;0
WireConnection;33;2;35;0
WireConnection;67;0;11;0
WireConnection;67;1;68;0
WireConnection;10;1;70;0
WireConnection;70;0;67;0
WireConnection;70;2;71;0
WireConnection;71;0;72;1
WireConnection;71;1;72;2
WireConnection;68;0;74;0
WireConnection;68;1;75;0
WireConnection;31;1;77;0
WireConnection;77;0;76;0
WireConnection;77;2;78;0
WireConnection;76;0;30;0
WireConnection;76;1;81;0
WireConnection;39;0;15;0
WireConnection;39;1;38;1
WireConnection;81;0;83;0
WireConnection;81;1;84;0
WireConnection;74;0;69;1
WireConnection;74;1;73;1
WireConnection;75;0;69;2
WireConnection;75;1;73;2
WireConnection;84;0;82;2
WireConnection;84;1;73;4
WireConnection;83;0;82;1
WireConnection;83;1;73;3
WireConnection;78;0;80;1
WireConnection;78;1;80;2
WireConnection;87;0;86;0
WireConnection;87;1;36;0
WireConnection;53;0;24;0
WireConnection;53;1;52;0
WireConnection;41;0;64;0
WireConnection;41;1;43;0
WireConnection;44;0;66;0
WireConnection;44;1;45;0
WireConnection;64;0;55;0
WireConnection;64;1;65;0
WireConnection;54;0;44;0
WireConnection;54;1;110;0
WireConnection;106;0;55;0
WireConnection;107;0;106;0
WireConnection;107;1;65;0
WireConnection;108;0;107;0
WireConnection;108;1;43;0
WireConnection;47;0;41;0
WireConnection;47;1;108;0
WireConnection;55;0;40;1
WireConnection;56;0;40;2
WireConnection;46;0;56;0
WireConnection;109;0;46;0
WireConnection;109;1;65;0
WireConnection;66;0;56;0
WireConnection;66;1;65;0
WireConnection;110;0;109;0
WireConnection;110;1;45;0
WireConnection;49;0;47;0
WireConnection;49;1;54;0
WireConnection;94;0;88;2
WireConnection;94;1;95;0
WireConnection;93;0;88;1
WireConnection;93;1;95;0
WireConnection;89;0;93;0
WireConnection;89;1;96;0
WireConnection;112;0;88;1
WireConnection;113;0;112;0
WireConnection;113;1;95;0
WireConnection;114;0;113;0
WireConnection;114;1;96;0
WireConnection;115;0;88;2
WireConnection;116;0;115;0
WireConnection;116;1;95;0
WireConnection;91;0;94;0
WireConnection;91;1;99;0
WireConnection;117;0;116;0
WireConnection;117;1;99;0
WireConnection;102;0;89;0
WireConnection;102;1;114;0
WireConnection;102;2;103;0
WireConnection;118;0;91;0
WireConnection;118;1;117;0
WireConnection;118;2;103;0
WireConnection;100;0;89;0
WireConnection;100;1;114;0
WireConnection;101;0;91;0
WireConnection;101;1;117;0
WireConnection;119;0;100;0
WireConnection;119;1;102;0
WireConnection;120;0;101;0
WireConnection;120;1;118;0
WireConnection;104;0;119;0
WireConnection;104;1;120;0
WireConnection;22;0;33;0
WireConnection;97;0;104;0
WireConnection;14;0;126;0
WireConnection;14;1;39;0
WireConnection;126;1;31;0
WireConnection;126;0;31;4
WireConnection;122;0;32;0
WireConnection;122;1;127;0
WireConnection;32;0;128;0
WireConnection;32;1;22;0
WireConnection;127;0;32;0
WireConnection;127;1;123;0
WireConnection;125;1;10;0
WireConnection;125;0;10;4
WireConnection;128;0;125;0
WireConnection;128;1;129;0
WireConnection;26;0;12;0
WireConnection;26;1;39;0
WireConnection;130;0;26;0
WireConnection;130;1;131;0
WireConnection;130;2;132;0
WireConnection;12;1;13;0
WireConnection;1;2;20;0
WireConnection;1;3;124;0
WireConnection;124;0;137;0
WireConnection;20;0;19;0
WireConnection;20;1;87;0
WireConnection;123;0;97;0
WireConnection;133;0;134;0
WireConnection;135;0;133;0
WireConnection;21;0;19;4
WireConnection;21;1;122;0
WireConnection;136;0;21;0
WireConnection;136;1;135;0
WireConnection;137;0;21;0
WireConnection;137;1;136;0
ASEEND*/
//CHKSM=672AB0E5D85FE74F0E04621D0F22E7E9656A9399