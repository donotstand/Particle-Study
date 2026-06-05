// Made with Amplify Shader Editor v1.9.2.1
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "VFX/S_MasterShader_01"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[Enum(LessEqual,4,Always,8)]_ZTest1("ZTest", Float) = 0
		[Enum(UnityEngine.Rendering.CullMode)]_CullMode("CullMode", Float) = 0
		[Enum(Additive,1,AlphaBlend,10,Premultiply,6)]_BlendMode("BlendMode", Float) = 0
		[Toggle]_Use_Custom("Use_Custom", Float) = 0
		[Toggle]_Use_SecondMask("Use_SecondMask", Float) = 0
		[Toggle]_Use_ThridColor("Use_ThridColor", Float) = 0
		[HDR]_Main_Color("Main_Color", Color) = (1,1,1,1)
		_MainTex("MainTex", 2D) = "white" {}
		[Toggle]_Use_Alpha("Use_Alpha", Float) = 0
		_Main_Pow("Main_Pow", Float) = 1
		_MainSecond_Panning("Main/Second_Panning", Vector) = (0,0,0,0)
		_SecondNoiseTex("SecondNoiseTex", 2D) = "white" {}
		_Noise_Amount("Noise_Amount", Range( -0.15 , 0.15)) = 0
		_Third_Panning("Third_Panning", Vector) = (0,0,0,0)
		_ThridColorTex("ThridColorTex", 2D) = "white" {}
		[Toggle]_Use_ThridDissolveColor("Use_ThridDissolveColor", Float) = 0
		[HDR]_EdgeColor("EdgeColor", Color) = (1,1,1,1)
		_Outline_Pow("Outline_Pow", Float) = 1
		_Cutout_Amount("Cutout_Amount", Float) = 0
		_Cutout_Hardness("Cutout_Hardness", Range( 0 , 1)) = 0.1
		_Cutout_Outline_Border("Cutout_Outline_Border ", Range( 0 , 1)) = 0.1
		_Cutout_Blend("Cutout_Blend", Range( 0 , 1)) = 0
		_Alpha_Clip_value("Alpha_Clip_value", Range( 0 , 1)) = 0


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
		#pragma target 3.5
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
			#define shader_feature_local _RECEIVE_SHADOWS_OFF
			#define _ALPHATEST_ON 1
			#define ASE_SRP_VERSION 140010


			#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3

			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile_fragment _ DEBUG_DISPLAY

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_UNLIT

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceData.hlsl"

			#define ASE_NEEDS_FRAG_COLOR


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				#ifdef ASE_FOG
					float fogFactor : TEXCOORD2;
				#endif
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _ThridColorTex_ST;
			float4 _MainTex_ST;
			float4 _MainSecond_Panning;
			float4 _SecondNoiseTex_ST;
			float4 _EdgeColor;
			float4 _Main_Color;
			float4 _Third_Panning;
			float _Use_SecondMask;
			float _Use_Alpha;
			float _Cutout_Blend;
			float _Cutout_Outline_Border;
			float _Cutout_Hardness;
			float _Cutout_Amount;
			float _CullMode;
			float _Use_ThridColor;
			float _Outline_Pow;
			float _Noise_Amount;
			float _Use_Custom;
			float _Use_ThridDissolveColor;
			float _BlendMode;
			float _ZTest1;
			float _Main_Pow;
			float _Alpha_Clip_value;
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
			sampler2D _SecondNoiseTex;
			sampler2D _ThridColorTex;


			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				o.ase_texcoord4 = v.ase_texcoord2;
				o.ase_texcoord5 = v.ase_texcoord1;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
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

				o.clipPos = positionCS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_color : COLOR;

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
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord2 = v.ase_texcoord2;
				o.ase_texcoord1 = v.ase_texcoord1;
				o.ase_color = v.ase_color;
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
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord2 = patch[0].ase_texcoord2 * bary.x + patch[1].ase_texcoord2 * bary.y + patch[2].ase_texcoord2 * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
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

			half4 frag ( VertexOutput IN  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.worldPos;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float2 uv_MainTex = IN.ase_texcoord3.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				float2 appendResult49 = (float2(_MainSecond_Panning.x , _MainSecond_Panning.y));
				float4 _Main_TileOffset = float4(1,1,0,0);
				float2 appendResult51 = (float2(_Main_TileOffset.z , _Main_TileOffset.w));
				float2 appendResult32 = (float2(IN.ase_texcoord4.x , IN.ase_texcoord4.y));
				float2 MainUV36 = appendResult32;
				float2 uv_SecondNoiseTex = IN.ase_texcoord3.xy * _SecondNoiseTex_ST.xy + _SecondNoiseTex_ST.zw;
				float2 appendResult53 = (float2(_MainSecond_Panning.z , _MainSecond_Panning.w));
				float2 Second_Panning54 = appendResult53;
				float4 _Second_TileOffset = float4(1,1,0,0);
				float2 appendResult94 = (float2(_Second_TileOffset.z , _Second_TileOffset.w));
				float4 tex2DNode97 = tex2D( _SecondNoiseTex, ( ( ( uv_SecondNoiseTex * float2( 1,1 ) ) + frac( ( Second_Panning54 * _TimeParameters.x ) ) ) + appendResult94 ) );
				float SecondTexR96 = tex2DNode97.r;
				float2 temp_cast_0 = ((-1.0 + (SecondTexR96 - 0.0) * (1.0 - -1.0) / (1.0 - 0.0))).xx;
				float Noise_Amount69 = IN.ase_texcoord5.w;
				float2 lerpResult61 = lerp( ( ( ( uv_MainTex * float2( 1,1 ) ) + frac( ( appendResult49 * _TimeParameters.x ) ) ) + (( _Use_Custom )?( ( appendResult51 + MainUV36 ) ):( appendResult51 )) ) , temp_cast_0 , (( _Use_Custom )?( ( _Noise_Amount + Noise_Amount69 ) ):( _Noise_Amount )));
				float4 tex2DNode66 = tex2D( _MainTex, lerpResult61 );
				float2 uv_ThridColorTex = IN.ase_texcoord3.xy * _ThridColorTex_ST.xy + _ThridColorTex_ST.zw;
				float4 _Third_TileOffset = float4(1,1,0,0);
				float2 appendResult80 = (float2(_Third_TileOffset.x , _Third_TileOffset.y));
				float2 appendResult89 = (float2(_Third_Panning.z , _Third_Panning.w));
				float2 appendResult78 = (float2(_Third_TileOffset.z , _Third_TileOffset.w));
				float2 appendResult31 = (float2(IN.ase_texcoord4.z , IN.ase_texcoord4.w));
				float2 ThirdUV37 = appendResult31;
				float4 tex2DNode90 = tex2D( _ThridColorTex, ( ( ( uv_ThridColorTex * appendResult80 ) + frac( ( appendResult89 * _TimeParameters.x ) ) ) + (( _Use_Custom )?( ( appendResult78 + ThirdUV37 ) ):( appendResult78 )) ) );
				float4 ThirdTex74 = tex2DNode90;
				float4 Cutout_Color23 = (( _Use_ThridDissolveColor )?( ( ( _Outline_Pow * ThirdTex74 ) * 20.0 ) ):( ( _Outline_Pow * _EdgeColor ) ));
				float Main_Pow146 = IN.ase_texcoord5.z;
				float Cutout_Amount33 = IN.ase_texcoord5.x;
				float temp_output_141_0 = ( (-7.0 + (( _Cutout_Amount + Cutout_Amount33 ) - -1.0) * (10.0 - -7.0) / (1.0 - -1.0)) + _Cutout_Hardness );
				float ThirdTexR73 = tex2DNode90.r;
				float Cutout_Blend119 = IN.ase_texcoord5.y;
				float lerpResult40 = lerp( SecondTexR96 , ThirdTexR73 , (( _Use_Custom )?( ( _Cutout_Blend + Cutout_Blend119 ) ):( _Cutout_Blend )));
				float CutoutTex_Blend43 = lerpResult40;
				float smoothstepResult123 = smoothstep( ( temp_output_141_0 * _Cutout_Hardness ) , ( ( temp_output_141_0 * _Cutout_Hardness ) + _Cutout_Outline_Border ) , CutoutTex_Blend43);
				float CutoutAlpha129 = smoothstepResult123;
				float4 lerpResult125 = lerp( Cutout_Color23 , ( ( _Main_Pow + Main_Pow146 ) * _Main_Color ) , CutoutAlpha129);
				float4 Color126 = lerpResult125;
				float4 temp_output_34_0 = abs( ( tex2DNode66 * Color126 ) );
				float MainTexR151 = (( _Use_Alpha )?( tex2DNode66.a ):( ( tex2DNode66.r * tex2DNode66.a ) ));
				float temp_output_105_0 = ( CutoutAlpha129 * MainTexR151 * (( _Use_SecondMask )?( SecondTexR96 ):( 1.0 )) * IN.ase_color.a );
				float4 temp_cast_1 = (1.0).xxxx;
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = ( (( _Use_ThridDissolveColor )?( ( temp_output_34_0 * saturate( temp_output_105_0 ) ) ):( temp_output_34_0 )) * IN.ase_color * (( _Use_ThridColor )?( ThirdTex74 ):( temp_cast_1 )) ).rgb;
				float Alpha = temp_output_105_0;
				float AlphaClipThreshold = _Alpha_Clip_value;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					clip( Alpha - AlphaClipThreshold );
				#endif

				#if defined(_DBUFFER)
					ApplyDecalToBaseColor(IN.clipPos, Color);
				#endif

				#if defined(_ALPHAPREMULTIPLY_ON)
				Color *= Alpha;
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#ifdef ASE_FOG
					Color = MixFog( Color, IN.fogFactor );
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
			#define shader_feature_local _RECEIVE_SHADOWS_OFF
			#define _ALPHATEST_ON 1
			#define ASE_SRP_VERSION 140010


			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _ThridColorTex_ST;
			float4 _MainTex_ST;
			float4 _MainSecond_Panning;
			float4 _SecondNoiseTex_ST;
			float4 _EdgeColor;
			float4 _Main_Color;
			float4 _Third_Panning;
			float _Use_SecondMask;
			float _Use_Alpha;
			float _Cutout_Blend;
			float _Cutout_Outline_Border;
			float _Cutout_Hardness;
			float _Cutout_Amount;
			float _CullMode;
			float _Use_ThridColor;
			float _Outline_Pow;
			float _Noise_Amount;
			float _Use_Custom;
			float _Use_ThridDissolveColor;
			float _BlendMode;
			float _ZTest1;
			float _Main_Pow;
			float _Alpha_Clip_value;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _SecondNoiseTex;
			sampler2D _ThridColorTex;
			sampler2D _MainTex;


			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.ase_texcoord2 = v.ase_texcoord1;
				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				o.ase_texcoord4 = v.ase_texcoord2;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				o.clipPos = TransformWorldToHClip( positionWS );
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = o.clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;

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
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord1 = v.ase_texcoord1;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord2 = v.ase_texcoord2;
				o.ase_color = v.ase_color;
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
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord2 = patch[0].ase_texcoord2 * bary.x + patch[1].ase_texcoord2 * bary.y + patch[2].ase_texcoord2 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
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
				float3 WorldPosition = IN.worldPos;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float Cutout_Amount33 = IN.ase_texcoord2.x;
				float temp_output_141_0 = ( (-7.0 + (( _Cutout_Amount + Cutout_Amount33 ) - -1.0) * (10.0 - -7.0) / (1.0 - -1.0)) + _Cutout_Hardness );
				float2 uv_SecondNoiseTex = IN.ase_texcoord3.xy * _SecondNoiseTex_ST.xy + _SecondNoiseTex_ST.zw;
				float2 appendResult53 = (float2(_MainSecond_Panning.z , _MainSecond_Panning.w));
				float2 Second_Panning54 = appendResult53;
				float4 _Second_TileOffset = float4(1,1,0,0);
				float2 appendResult94 = (float2(_Second_TileOffset.z , _Second_TileOffset.w));
				float4 tex2DNode97 = tex2D( _SecondNoiseTex, ( ( ( uv_SecondNoiseTex * float2( 1,1 ) ) + frac( ( Second_Panning54 * _TimeParameters.x ) ) ) + appendResult94 ) );
				float SecondTexR96 = tex2DNode97.r;
				float2 uv_ThridColorTex = IN.ase_texcoord3.xy * _ThridColorTex_ST.xy + _ThridColorTex_ST.zw;
				float4 _Third_TileOffset = float4(1,1,0,0);
				float2 appendResult80 = (float2(_Third_TileOffset.x , _Third_TileOffset.y));
				float2 appendResult89 = (float2(_Third_Panning.z , _Third_Panning.w));
				float2 appendResult78 = (float2(_Third_TileOffset.z , _Third_TileOffset.w));
				float2 appendResult31 = (float2(IN.ase_texcoord4.z , IN.ase_texcoord4.w));
				float2 ThirdUV37 = appendResult31;
				float4 tex2DNode90 = tex2D( _ThridColorTex, ( ( ( uv_ThridColorTex * appendResult80 ) + frac( ( appendResult89 * _TimeParameters.x ) ) ) + (( _Use_Custom )?( ( appendResult78 + ThirdUV37 ) ):( appendResult78 )) ) );
				float ThirdTexR73 = tex2DNode90.r;
				float Cutout_Blend119 = IN.ase_texcoord2.y;
				float lerpResult40 = lerp( SecondTexR96 , ThirdTexR73 , (( _Use_Custom )?( ( _Cutout_Blend + Cutout_Blend119 ) ):( _Cutout_Blend )));
				float CutoutTex_Blend43 = lerpResult40;
				float smoothstepResult123 = smoothstep( ( temp_output_141_0 * _Cutout_Hardness ) , ( ( temp_output_141_0 * _Cutout_Hardness ) + _Cutout_Outline_Border ) , CutoutTex_Blend43);
				float CutoutAlpha129 = smoothstepResult123;
				float2 uv_MainTex = IN.ase_texcoord3.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				float2 appendResult49 = (float2(_MainSecond_Panning.x , _MainSecond_Panning.y));
				float4 _Main_TileOffset = float4(1,1,0,0);
				float2 appendResult51 = (float2(_Main_TileOffset.z , _Main_TileOffset.w));
				float2 appendResult32 = (float2(IN.ase_texcoord4.x , IN.ase_texcoord4.y));
				float2 MainUV36 = appendResult32;
				float2 temp_cast_0 = ((-1.0 + (SecondTexR96 - 0.0) * (1.0 - -1.0) / (1.0 - 0.0))).xx;
				float Noise_Amount69 = IN.ase_texcoord2.w;
				float2 lerpResult61 = lerp( ( ( ( uv_MainTex * float2( 1,1 ) ) + frac( ( appendResult49 * _TimeParameters.x ) ) ) + (( _Use_Custom )?( ( appendResult51 + MainUV36 ) ):( appendResult51 )) ) , temp_cast_0 , (( _Use_Custom )?( ( _Noise_Amount + Noise_Amount69 ) ):( _Noise_Amount )));
				float4 tex2DNode66 = tex2D( _MainTex, lerpResult61 );
				float MainTexR151 = (( _Use_Alpha )?( tex2DNode66.a ):( ( tex2DNode66.r * tex2DNode66.a ) ));
				float temp_output_105_0 = ( CutoutAlpha129 * MainTexR151 * (( _Use_SecondMask )?( SecondTexR96 ):( 1.0 )) * IN.ase_color.a );
				

				float Alpha = temp_output_105_0;
				float AlphaClipThreshold = _Alpha_Clip_value;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
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
			#define shader_feature_local _RECEIVE_SHADOWS_OFF
			#define _ALPHATEST_ON 1
			#define ASE_SRP_VERSION 140010


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

			

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _ThridColorTex_ST;
			float4 _MainTex_ST;
			float4 _MainSecond_Panning;
			float4 _SecondNoiseTex_ST;
			float4 _EdgeColor;
			float4 _Main_Color;
			float4 _Third_Panning;
			float _Use_SecondMask;
			float _Use_Alpha;
			float _Cutout_Blend;
			float _Cutout_Outline_Border;
			float _Cutout_Hardness;
			float _Cutout_Amount;
			float _CullMode;
			float _Use_ThridColor;
			float _Outline_Pow;
			float _Noise_Amount;
			float _Use_Custom;
			float _Use_ThridDissolveColor;
			float _BlendMode;
			float _ZTest1;
			float _Main_Pow;
			float _Alpha_Clip_value;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _SecondNoiseTex;
			sampler2D _ThridColorTex;
			sampler2D _MainTex;


			
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

				o.ase_texcoord = v.ase_texcoord1;
				o.ase_texcoord1.xy = v.ase_texcoord.xy;
				o.ase_texcoord2 = v.ase_texcoord2;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.zw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );

				o.clipPos = TransformWorldToHClip(positionWS);

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;

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
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord1 = v.ase_texcoord1;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord2 = v.ase_texcoord2;
				o.ase_color = v.ase_color;
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
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord2 = patch[0].ase_texcoord2 * bary.x + patch[1].ase_texcoord2 * bary.y + patch[2].ase_texcoord2 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
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

				float Cutout_Amount33 = IN.ase_texcoord.x;
				float temp_output_141_0 = ( (-7.0 + (( _Cutout_Amount + Cutout_Amount33 ) - -1.0) * (10.0 - -7.0) / (1.0 - -1.0)) + _Cutout_Hardness );
				float2 uv_SecondNoiseTex = IN.ase_texcoord1.xy * _SecondNoiseTex_ST.xy + _SecondNoiseTex_ST.zw;
				float2 appendResult53 = (float2(_MainSecond_Panning.z , _MainSecond_Panning.w));
				float2 Second_Panning54 = appendResult53;
				float4 _Second_TileOffset = float4(1,1,0,0);
				float2 appendResult94 = (float2(_Second_TileOffset.z , _Second_TileOffset.w));
				float4 tex2DNode97 = tex2D( _SecondNoiseTex, ( ( ( uv_SecondNoiseTex * float2( 1,1 ) ) + frac( ( Second_Panning54 * _TimeParameters.x ) ) ) + appendResult94 ) );
				float SecondTexR96 = tex2DNode97.r;
				float2 uv_ThridColorTex = IN.ase_texcoord1.xy * _ThridColorTex_ST.xy + _ThridColorTex_ST.zw;
				float4 _Third_TileOffset = float4(1,1,0,0);
				float2 appendResult80 = (float2(_Third_TileOffset.x , _Third_TileOffset.y));
				float2 appendResult89 = (float2(_Third_Panning.z , _Third_Panning.w));
				float2 appendResult78 = (float2(_Third_TileOffset.z , _Third_TileOffset.w));
				float2 appendResult31 = (float2(IN.ase_texcoord2.z , IN.ase_texcoord2.w));
				float2 ThirdUV37 = appendResult31;
				float4 tex2DNode90 = tex2D( _ThridColorTex, ( ( ( uv_ThridColorTex * appendResult80 ) + frac( ( appendResult89 * _TimeParameters.x ) ) ) + (( _Use_Custom )?( ( appendResult78 + ThirdUV37 ) ):( appendResult78 )) ) );
				float ThirdTexR73 = tex2DNode90.r;
				float Cutout_Blend119 = IN.ase_texcoord.y;
				float lerpResult40 = lerp( SecondTexR96 , ThirdTexR73 , (( _Use_Custom )?( ( _Cutout_Blend + Cutout_Blend119 ) ):( _Cutout_Blend )));
				float CutoutTex_Blend43 = lerpResult40;
				float smoothstepResult123 = smoothstep( ( temp_output_141_0 * _Cutout_Hardness ) , ( ( temp_output_141_0 * _Cutout_Hardness ) + _Cutout_Outline_Border ) , CutoutTex_Blend43);
				float CutoutAlpha129 = smoothstepResult123;
				float2 uv_MainTex = IN.ase_texcoord1.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				float2 appendResult49 = (float2(_MainSecond_Panning.x , _MainSecond_Panning.y));
				float4 _Main_TileOffset = float4(1,1,0,0);
				float2 appendResult51 = (float2(_Main_TileOffset.z , _Main_TileOffset.w));
				float2 appendResult32 = (float2(IN.ase_texcoord2.x , IN.ase_texcoord2.y));
				float2 MainUV36 = appendResult32;
				float2 temp_cast_0 = ((-1.0 + (SecondTexR96 - 0.0) * (1.0 - -1.0) / (1.0 - 0.0))).xx;
				float Noise_Amount69 = IN.ase_texcoord.w;
				float2 lerpResult61 = lerp( ( ( ( uv_MainTex * float2( 1,1 ) ) + frac( ( appendResult49 * _TimeParameters.x ) ) ) + (( _Use_Custom )?( ( appendResult51 + MainUV36 ) ):( appendResult51 )) ) , temp_cast_0 , (( _Use_Custom )?( ( _Noise_Amount + Noise_Amount69 ) ):( _Noise_Amount )));
				float4 tex2DNode66 = tex2D( _MainTex, lerpResult61 );
				float MainTexR151 = (( _Use_Alpha )?( tex2DNode66.a ):( ( tex2DNode66.r * tex2DNode66.a ) ));
				float temp_output_105_0 = ( CutoutAlpha129 * MainTexR151 * (( _Use_SecondMask )?( SecondTexR96 ):( 1.0 )) * IN.ase_color.a );
				

				surfaceDescription.Alpha = temp_output_105_0;
				surfaceDescription.AlphaClipThreshold = _Alpha_Clip_value;

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
			#define shader_feature_local _RECEIVE_SHADOWS_OFF
			#define _ALPHATEST_ON 1
			#define ASE_SRP_VERSION 140010


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

			

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _ThridColorTex_ST;
			float4 _MainTex_ST;
			float4 _MainSecond_Panning;
			float4 _SecondNoiseTex_ST;
			float4 _EdgeColor;
			float4 _Main_Color;
			float4 _Third_Panning;
			float _Use_SecondMask;
			float _Use_Alpha;
			float _Cutout_Blend;
			float _Cutout_Outline_Border;
			float _Cutout_Hardness;
			float _Cutout_Amount;
			float _CullMode;
			float _Use_ThridColor;
			float _Outline_Pow;
			float _Noise_Amount;
			float _Use_Custom;
			float _Use_ThridDissolveColor;
			float _BlendMode;
			float _ZTest1;
			float _Main_Pow;
			float _Alpha_Clip_value;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _SecondNoiseTex;
			sampler2D _ThridColorTex;
			sampler2D _MainTex;


			
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

				o.ase_texcoord = v.ase_texcoord1;
				o.ase_texcoord1.xy = v.ase_texcoord.xy;
				o.ase_texcoord2 = v.ase_texcoord2;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.zw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				o.clipPos = TransformWorldToHClip(positionWS);
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;

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
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord1 = v.ase_texcoord1;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord2 = v.ase_texcoord2;
				o.ase_color = v.ase_color;
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
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord2 = patch[0].ase_texcoord2 * bary.x + patch[1].ase_texcoord2 * bary.y + patch[2].ase_texcoord2 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
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

				float Cutout_Amount33 = IN.ase_texcoord.x;
				float temp_output_141_0 = ( (-7.0 + (( _Cutout_Amount + Cutout_Amount33 ) - -1.0) * (10.0 - -7.0) / (1.0 - -1.0)) + _Cutout_Hardness );
				float2 uv_SecondNoiseTex = IN.ase_texcoord1.xy * _SecondNoiseTex_ST.xy + _SecondNoiseTex_ST.zw;
				float2 appendResult53 = (float2(_MainSecond_Panning.z , _MainSecond_Panning.w));
				float2 Second_Panning54 = appendResult53;
				float4 _Second_TileOffset = float4(1,1,0,0);
				float2 appendResult94 = (float2(_Second_TileOffset.z , _Second_TileOffset.w));
				float4 tex2DNode97 = tex2D( _SecondNoiseTex, ( ( ( uv_SecondNoiseTex * float2( 1,1 ) ) + frac( ( Second_Panning54 * _TimeParameters.x ) ) ) + appendResult94 ) );
				float SecondTexR96 = tex2DNode97.r;
				float2 uv_ThridColorTex = IN.ase_texcoord1.xy * _ThridColorTex_ST.xy + _ThridColorTex_ST.zw;
				float4 _Third_TileOffset = float4(1,1,0,0);
				float2 appendResult80 = (float2(_Third_TileOffset.x , _Third_TileOffset.y));
				float2 appendResult89 = (float2(_Third_Panning.z , _Third_Panning.w));
				float2 appendResult78 = (float2(_Third_TileOffset.z , _Third_TileOffset.w));
				float2 appendResult31 = (float2(IN.ase_texcoord2.z , IN.ase_texcoord2.w));
				float2 ThirdUV37 = appendResult31;
				float4 tex2DNode90 = tex2D( _ThridColorTex, ( ( ( uv_ThridColorTex * appendResult80 ) + frac( ( appendResult89 * _TimeParameters.x ) ) ) + (( _Use_Custom )?( ( appendResult78 + ThirdUV37 ) ):( appendResult78 )) ) );
				float ThirdTexR73 = tex2DNode90.r;
				float Cutout_Blend119 = IN.ase_texcoord.y;
				float lerpResult40 = lerp( SecondTexR96 , ThirdTexR73 , (( _Use_Custom )?( ( _Cutout_Blend + Cutout_Blend119 ) ):( _Cutout_Blend )));
				float CutoutTex_Blend43 = lerpResult40;
				float smoothstepResult123 = smoothstep( ( temp_output_141_0 * _Cutout_Hardness ) , ( ( temp_output_141_0 * _Cutout_Hardness ) + _Cutout_Outline_Border ) , CutoutTex_Blend43);
				float CutoutAlpha129 = smoothstepResult123;
				float2 uv_MainTex = IN.ase_texcoord1.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				float2 appendResult49 = (float2(_MainSecond_Panning.x , _MainSecond_Panning.y));
				float4 _Main_TileOffset = float4(1,1,0,0);
				float2 appendResult51 = (float2(_Main_TileOffset.z , _Main_TileOffset.w));
				float2 appendResult32 = (float2(IN.ase_texcoord2.x , IN.ase_texcoord2.y));
				float2 MainUV36 = appendResult32;
				float2 temp_cast_0 = ((-1.0 + (SecondTexR96 - 0.0) * (1.0 - -1.0) / (1.0 - 0.0))).xx;
				float Noise_Amount69 = IN.ase_texcoord.w;
				float2 lerpResult61 = lerp( ( ( ( uv_MainTex * float2( 1,1 ) ) + frac( ( appendResult49 * _TimeParameters.x ) ) ) + (( _Use_Custom )?( ( appendResult51 + MainUV36 ) ):( appendResult51 )) ) , temp_cast_0 , (( _Use_Custom )?( ( _Noise_Amount + Noise_Amount69 ) ):( _Noise_Amount )));
				float4 tex2DNode66 = tex2D( _MainTex, lerpResult61 );
				float MainTexR151 = (( _Use_Alpha )?( tex2DNode66.a ):( ( tex2DNode66.r * tex2DNode66.a ) ));
				float temp_output_105_0 = ( CutoutAlpha129 * MainTexR151 * (( _Use_SecondMask )?( SecondTexR96 ):( 1.0 )) * IN.ase_color.a );
				

				surfaceDescription.Alpha = temp_output_105_0;
				surfaceDescription.AlphaClipThreshold = _Alpha_Clip_value;

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
			#define shader_feature_local _RECEIVE_SHADOWS_OFF
			#define _ALPHATEST_ON 1
			#define ASE_SRP_VERSION 140010


			#pragma vertex vert
			#pragma fragment frag

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

			

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float3 normalWS : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _ThridColorTex_ST;
			float4 _MainTex_ST;
			float4 _MainSecond_Panning;
			float4 _SecondNoiseTex_ST;
			float4 _EdgeColor;
			float4 _Main_Color;
			float4 _Third_Panning;
			float _Use_SecondMask;
			float _Use_Alpha;
			float _Cutout_Blend;
			float _Cutout_Outline_Border;
			float _Cutout_Hardness;
			float _Cutout_Amount;
			float _CullMode;
			float _Use_ThridColor;
			float _Outline_Pow;
			float _Noise_Amount;
			float _Use_Custom;
			float _Use_ThridDissolveColor;
			float _BlendMode;
			float _ZTest1;
			float _Main_Pow;
			float _Alpha_Clip_value;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _SecondNoiseTex;
			sampler2D _ThridColorTex;
			sampler2D _MainTex;


			
			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.ase_texcoord1 = v.ase_texcoord1;
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				o.ase_texcoord3 = v.ase_texcoord2;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.zw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float3 normalWS = TransformObjectToWorldNormal(v.ase_normal);

				o.clipPos = TransformWorldToHClip(positionWS);
				o.normalWS.xyz =  normalWS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;

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
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord1 = v.ase_texcoord1;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord2 = v.ase_texcoord2;
				o.ase_color = v.ase_color;
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
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord2 = patch[0].ase_texcoord2 * bary.x + patch[1].ase_texcoord2 * bary.y + patch[2].ase_texcoord2 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
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

				float Cutout_Amount33 = IN.ase_texcoord1.x;
				float temp_output_141_0 = ( (-7.0 + (( _Cutout_Amount + Cutout_Amount33 ) - -1.0) * (10.0 - -7.0) / (1.0 - -1.0)) + _Cutout_Hardness );
				float2 uv_SecondNoiseTex = IN.ase_texcoord2.xy * _SecondNoiseTex_ST.xy + _SecondNoiseTex_ST.zw;
				float2 appendResult53 = (float2(_MainSecond_Panning.z , _MainSecond_Panning.w));
				float2 Second_Panning54 = appendResult53;
				float4 _Second_TileOffset = float4(1,1,0,0);
				float2 appendResult94 = (float2(_Second_TileOffset.z , _Second_TileOffset.w));
				float4 tex2DNode97 = tex2D( _SecondNoiseTex, ( ( ( uv_SecondNoiseTex * float2( 1,1 ) ) + frac( ( Second_Panning54 * _TimeParameters.x ) ) ) + appendResult94 ) );
				float SecondTexR96 = tex2DNode97.r;
				float2 uv_ThridColorTex = IN.ase_texcoord2.xy * _ThridColorTex_ST.xy + _ThridColorTex_ST.zw;
				float4 _Third_TileOffset = float4(1,1,0,0);
				float2 appendResult80 = (float2(_Third_TileOffset.x , _Third_TileOffset.y));
				float2 appendResult89 = (float2(_Third_Panning.z , _Third_Panning.w));
				float2 appendResult78 = (float2(_Third_TileOffset.z , _Third_TileOffset.w));
				float2 appendResult31 = (float2(IN.ase_texcoord3.z , IN.ase_texcoord3.w));
				float2 ThirdUV37 = appendResult31;
				float4 tex2DNode90 = tex2D( _ThridColorTex, ( ( ( uv_ThridColorTex * appendResult80 ) + frac( ( appendResult89 * _TimeParameters.x ) ) ) + (( _Use_Custom )?( ( appendResult78 + ThirdUV37 ) ):( appendResult78 )) ) );
				float ThirdTexR73 = tex2DNode90.r;
				float Cutout_Blend119 = IN.ase_texcoord1.y;
				float lerpResult40 = lerp( SecondTexR96 , ThirdTexR73 , (( _Use_Custom )?( ( _Cutout_Blend + Cutout_Blend119 ) ):( _Cutout_Blend )));
				float CutoutTex_Blend43 = lerpResult40;
				float smoothstepResult123 = smoothstep( ( temp_output_141_0 * _Cutout_Hardness ) , ( ( temp_output_141_0 * _Cutout_Hardness ) + _Cutout_Outline_Border ) , CutoutTex_Blend43);
				float CutoutAlpha129 = smoothstepResult123;
				float2 uv_MainTex = IN.ase_texcoord2.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				float2 appendResult49 = (float2(_MainSecond_Panning.x , _MainSecond_Panning.y));
				float4 _Main_TileOffset = float4(1,1,0,0);
				float2 appendResult51 = (float2(_Main_TileOffset.z , _Main_TileOffset.w));
				float2 appendResult32 = (float2(IN.ase_texcoord3.x , IN.ase_texcoord3.y));
				float2 MainUV36 = appendResult32;
				float2 temp_cast_0 = ((-1.0 + (SecondTexR96 - 0.0) * (1.0 - -1.0) / (1.0 - 0.0))).xx;
				float Noise_Amount69 = IN.ase_texcoord1.w;
				float2 lerpResult61 = lerp( ( ( ( uv_MainTex * float2( 1,1 ) ) + frac( ( appendResult49 * _TimeParameters.x ) ) ) + (( _Use_Custom )?( ( appendResult51 + MainUV36 ) ):( appendResult51 )) ) , temp_cast_0 , (( _Use_Custom )?( ( _Noise_Amount + Noise_Amount69 ) ):( _Noise_Amount )));
				float4 tex2DNode66 = tex2D( _MainTex, lerpResult61 );
				float MainTexR151 = (( _Use_Alpha )?( tex2DNode66.a ):( ( tex2DNode66.r * tex2DNode66.a ) ));
				float temp_output_105_0 = ( CutoutAlpha129 * MainTexR151 * (( _Use_SecondMask )?( SecondTexR96 ):( 1.0 )) * IN.ase_color.a );
				

				surfaceDescription.Alpha = temp_output_105_0;
				surfaceDescription.AlphaClipThreshold = _Alpha_Clip_value;

				#if _ALPHATEST_ON
					clip(surfaceDescription.Alpha - surfaceDescription.AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				float3 normalWS = IN.normalWS;

				return half4(NormalizeNormalPerPixel(normalWS), 0.0);
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthNormalsOnly"
			Tags { "LightMode"="DepthNormalsOnly" }

			ZTest LEqual
			ZWrite On

			HLSLPROGRAM

			#define _SURFACE_TYPE_TRANSPARENT 1
			#define shader_feature_local _RECEIVE_SHADOWS_OFF
			#define _ALPHATEST_ON 1
			#define ASE_SRP_VERSION 140010


			#pragma exclude_renderers glcore gles gles3 
			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define ATTRIBUTES_NEED_TEXCOORD1
			#define VARYINGS_NEED_NORMAL_WS
			#define VARYINGS_NEED_TANGENT_WS

			#define SHADERPASS SHADERPASS_DEPTHNORMALSONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float3 normalWS : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _ThridColorTex_ST;
			float4 _MainTex_ST;
			float4 _MainSecond_Panning;
			float4 _SecondNoiseTex_ST;
			float4 _EdgeColor;
			float4 _Main_Color;
			float4 _Third_Panning;
			float _Use_SecondMask;
			float _Use_Alpha;
			float _Cutout_Blend;
			float _Cutout_Outline_Border;
			float _Cutout_Hardness;
			float _Cutout_Amount;
			float _CullMode;
			float _Use_ThridColor;
			float _Outline_Pow;
			float _Noise_Amount;
			float _Use_Custom;
			float _Use_ThridDissolveColor;
			float _BlendMode;
			float _ZTest1;
			float _Main_Pow;
			float _Alpha_Clip_value;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			sampler2D _SecondNoiseTex;
			sampler2D _ThridColorTex;
			sampler2D _MainTex;


			
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

				o.ase_texcoord1 = v.ase_texcoord1;
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				o.ase_texcoord3 = v.ase_texcoord2;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float3 normalWS = TransformObjectToWorldNormal(v.ase_normal);

				o.clipPos = TransformWorldToHClip(positionWS);
				o.normalWS.xyz =  normalWS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;

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
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord1 = v.ase_texcoord1;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord2 = v.ase_texcoord2;
				o.ase_color = v.ase_color;
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
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord2 = patch[0].ase_texcoord2 * bary.x + patch[1].ase_texcoord2 * bary.y + patch[2].ase_texcoord2 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
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

				float Cutout_Amount33 = IN.ase_texcoord1.x;
				float temp_output_141_0 = ( (-7.0 + (( _Cutout_Amount + Cutout_Amount33 ) - -1.0) * (10.0 - -7.0) / (1.0 - -1.0)) + _Cutout_Hardness );
				float2 uv_SecondNoiseTex = IN.ase_texcoord2.xy * _SecondNoiseTex_ST.xy + _SecondNoiseTex_ST.zw;
				float2 appendResult53 = (float2(_MainSecond_Panning.z , _MainSecond_Panning.w));
				float2 Second_Panning54 = appendResult53;
				float4 _Second_TileOffset = float4(1,1,0,0);
				float2 appendResult94 = (float2(_Second_TileOffset.z , _Second_TileOffset.w));
				float4 tex2DNode97 = tex2D( _SecondNoiseTex, ( ( ( uv_SecondNoiseTex * float2( 1,1 ) ) + frac( ( Second_Panning54 * _TimeParameters.x ) ) ) + appendResult94 ) );
				float SecondTexR96 = tex2DNode97.r;
				float2 uv_ThridColorTex = IN.ase_texcoord2.xy * _ThridColorTex_ST.xy + _ThridColorTex_ST.zw;
				float4 _Third_TileOffset = float4(1,1,0,0);
				float2 appendResult80 = (float2(_Third_TileOffset.x , _Third_TileOffset.y));
				float2 appendResult89 = (float2(_Third_Panning.z , _Third_Panning.w));
				float2 appendResult78 = (float2(_Third_TileOffset.z , _Third_TileOffset.w));
				float2 appendResult31 = (float2(IN.ase_texcoord3.z , IN.ase_texcoord3.w));
				float2 ThirdUV37 = appendResult31;
				float4 tex2DNode90 = tex2D( _ThridColorTex, ( ( ( uv_ThridColorTex * appendResult80 ) + frac( ( appendResult89 * _TimeParameters.x ) ) ) + (( _Use_Custom )?( ( appendResult78 + ThirdUV37 ) ):( appendResult78 )) ) );
				float ThirdTexR73 = tex2DNode90.r;
				float Cutout_Blend119 = IN.ase_texcoord1.y;
				float lerpResult40 = lerp( SecondTexR96 , ThirdTexR73 , (( _Use_Custom )?( ( _Cutout_Blend + Cutout_Blend119 ) ):( _Cutout_Blend )));
				float CutoutTex_Blend43 = lerpResult40;
				float smoothstepResult123 = smoothstep( ( temp_output_141_0 * _Cutout_Hardness ) , ( ( temp_output_141_0 * _Cutout_Hardness ) + _Cutout_Outline_Border ) , CutoutTex_Blend43);
				float CutoutAlpha129 = smoothstepResult123;
				float2 uv_MainTex = IN.ase_texcoord2.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				float2 appendResult49 = (float2(_MainSecond_Panning.x , _MainSecond_Panning.y));
				float4 _Main_TileOffset = float4(1,1,0,0);
				float2 appendResult51 = (float2(_Main_TileOffset.z , _Main_TileOffset.w));
				float2 appendResult32 = (float2(IN.ase_texcoord3.x , IN.ase_texcoord3.y));
				float2 MainUV36 = appendResult32;
				float2 temp_cast_0 = ((-1.0 + (SecondTexR96 - 0.0) * (1.0 - -1.0) / (1.0 - 0.0))).xx;
				float Noise_Amount69 = IN.ase_texcoord1.w;
				float2 lerpResult61 = lerp( ( ( ( uv_MainTex * float2( 1,1 ) ) + frac( ( appendResult49 * _TimeParameters.x ) ) ) + (( _Use_Custom )?( ( appendResult51 + MainUV36 ) ):( appendResult51 )) ) , temp_cast_0 , (( _Use_Custom )?( ( _Noise_Amount + Noise_Amount69 ) ):( _Noise_Amount )));
				float4 tex2DNode66 = tex2D( _MainTex, lerpResult61 );
				float MainTexR151 = (( _Use_Alpha )?( tex2DNode66.a ):( ( tex2DNode66.r * tex2DNode66.a ) ));
				float temp_output_105_0 = ( CutoutAlpha129 * MainTexR151 * (( _Use_SecondMask )?( SecondTexR96 ):( 1.0 )) * IN.ase_color.a );
				

				surfaceDescription.Alpha = temp_output_105_0;
				surfaceDescription.AlphaClipThreshold = _Alpha_Clip_value;

				#if _ALPHATEST_ON
					clip(surfaceDescription.Alpha - surfaceDescription.AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				float3 normalWS = IN.normalWS;

				return half4(NormalizeNormalPerPixel(normalWS), 0.0);
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
Node;AmplifyShaderEditor.CommentaryNode;155;-4444.654,781.3525;Inherit;False;1402.997;506.876;Outline_Color;9;19;20;21;22;23;35;71;72;115;Outline_Color;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;154;-4507.643,-158.4853;Inherit;False;1881.034;708.5717;ThirdUV;17;73;74;75;76;77;84;85;90;80;116;78;79;89;117;86;92;81;ThirdUV;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;153;-2460.479,99.75766;Inherit;False;1201.446;403.1948;Blend;8;40;41;42;43;38;44;70;39;Blend;1,1,1,1;0;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;0;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=ShadowCaster;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;False;False;True;1;LightMode=DepthOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;5;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Universal2D;0;5;Universal2D;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=Universal2D;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;6;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;SceneSelectionPass;0;6;SceneSelectionPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=SceneSelectionPass;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;7;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ScenePickingPass;0;7;ScenePickingPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Picking;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;8;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthNormals;0;8;DepthNormals;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;9;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthNormalsOnly;0;9;DepthNormalsOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;True;9;d3d11;metal;vulkan;xboxone;xboxseries;playstation;ps4;ps5;switch;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.CommentaryNode;10;-2906.104,788.6575;Inherit;False;2268.778;738.85;Cutout;28;148;147;145;144;143;142;141;140;139;138;137;136;135;134;133;132;131;130;129;128;127;126;125;124;123;122;121;120;Cutout;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;11;-152.8074,-495.4367;Inherit;False;1221.167;464.6053;Alpha;9;113;107;106;105;104;103;102;101;100;Alpha;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;12;-4191.109,-953.242;Inherit;False;1752.016;430.5674;SecondUV;8;118;99;98;97;96;95;94;93;SecondUV;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;14;-2269.031,-1085.038;Inherit;False;1929.266;980.3576;MainUV;27;152;151;150;68;67;66;65;64;63;62;61;60;59;58;57;56;55;54;53;52;51;50;49;48;47;46;45;MainUV;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;16;-1157.98,21.32648;Inherit;False;769.7681;709.0884;Custom;10;146;119;69;37;36;33;32;31;30;29;Custom;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;18;1192.786,-382.1865;Inherit;False;370.3481;243.2074;Blend;3;28;27;26;Blend;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;24;-262.8083,-747.6216;Inherit;False;126;Color;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;25;-38.80518,-840.8866;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;26;1398.823,-309.6974;Inherit;False;Property;_CullMode;CullMode;1;1;[Enum];Create;True;0;0;1;UnityEngine.Rendering.CullMode;True;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;27;1239.653,-234.0175;Inherit;False;Property;_ZTest1;ZTest;0;1;[Enum];Create;True;0;2;LessEqual;4;Always;8;0;True;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;28;1221.978,-309.9795;Inherit;False;Property;_BlendMode;BlendMode;2;1;[Enum];Create;True;0;3;Additive;1;AlphaBlend;10;Premultiply;6;0;True;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;29;-1100.935,207.2443;Inherit;False;1;4;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexCoordVertexDataNode;30;-1107.98,492.8295;Inherit;False;2;4;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;31;-826.4973,594.0815;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;32;-825.1904,499.7755;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;33;-757.6963,119.8643;Inherit;False;Cutout_Amount;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.AbsOpNode;34;200.2666,-857.7886;Inherit;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;36;-642.4065,508.9455;Inherit;False;MainUV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;37;-650.4065,605.9455;Inherit;False;ThirdUV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WireNode;45;-1395.45,-1002.521;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WireNode;46;-1380.083,-1001.035;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WireNode;47;-1378.626,-986.6669;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;48;-1833.367,-569.0217;Inherit;False;Property;_MainSecond_Panning;Main/Second_Panning;10;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;49;-1521.185,-555.393;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;50;-1981.099,-665.6395;Inherit;False;36;MainUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;51;-1977.392,-780.9384;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;52;-1786.849,-719.3873;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;53;-1524.678,-453.2537;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;54;-1370.605,-451.4827;Inherit;False;Second_Panning;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FunctionNode;56;-1315.051,-856.8854;Inherit;False;S_UV_01;-1;;28;e25fc9644ee19a54fa2cb37170096ce6;0;4;6;FLOAT2;0,0;False;8;FLOAT2;1,1;False;13;FLOAT2;0,0;False;18;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WireNode;57;-1371.573,-831.7604;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WireNode;58;-1370.685,-827.6445;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;59;-2219.031,-849.9454;Inherit;False;Constant;_Main_TileOffset;Main_Tile/Offset;10;0;Create;True;0;0;0;False;0;False;1,1,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;61;-1076.501,-579.2667;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;62;-1573.213,-645.0814;Inherit;False;96;SecondTexR;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;63;-1308.599,-644.2461;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;-1;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;65;-1365.402,-241.2801;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;66;-1007.349,-834.0731;Inherit;True;Property;_MainTex;MainTex;7;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;67;-1671.272,-342.6843;Inherit;False;Property;_Noise_Amount;Noise_Amount;12;0;Create;True;0;0;0;False;0;False;0;0;-0.15;0.15;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;68;-1621.785,-219.4734;Inherit;False;69;Noise_Amount;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;69;-756.7454,376.5065;Inherit;False;Noise_Amount;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;93;-2701.293,-760.389;Inherit;False;SecondTex;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.DynamicAppendNode;94;-3618.329,-670.0763;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;95;-4031.771,-730.6746;Inherit;False;Constant;_Second_TileOffset;Second_Tile/Offset;13;0;Create;True;0;0;0;False;0;False;1,1,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;96;-2681.093,-684.3891;Inherit;False;SecondTexR;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;97;-2990.093,-760.389;Inherit;True;Property;_SecondNoiseTex;SecondNoiseTex;11;0;Create;True;0;0;0;False;0;False;-1;6bbfa4e77d840ad418b592c285d67bfa;6bbfa4e77d840ad418b592c285d67bfa;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;99;-3696.094,-743.3528;Inherit;False;54;Second_Panning;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.VertexColorNode;100;449.1138,-280.8521;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WireNode;101;928.9727,-311.3662;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;103;366.8984,-362.6522;Inherit;False;151;MainTexR;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;104;345.5098,-445.4366;Inherit;False;129;CutoutAlpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;105;645.4658,-420.7042;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;106;890.3599,-435.5212;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;107;-102.8074,-143.6313;Inherit;False;96;SecondTexR;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;108;440.0986,-988.756;Inherit;False;74;ThirdTex;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;109;481.7695,-1119.997;Inherit;False;Constant;_Float6;Float 6;30;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;110;986.9556,-881.3411;Inherit;True;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;111;919.9858,-1056.284;Inherit;False;Property;_Alpha_Clip_value;Alpha_Clip_value;22;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;112;394.3657,-855.1618;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ToggleSwitchNode;113;148.6714,-206.1021;Inherit;False;Property;_Use_SecondMask;Use_SecondMask;4;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;118;-3355.317,-752.2954;Inherit;False;S_UV_01;-1;;30;e25fc9644ee19a54fa2cb37170096ce6;0;4;6;FLOAT2;0,0;False;8;FLOAT2;1,1;False;13;FLOAT2;0,0;False;18;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;119;-739.0254,190.4404;Inherit;False;Cutout_Blend;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;120;-2035.317,1251.467;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;121;-1878.687,1161.467;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;122;-1874.956,1250.517;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;123;-1662.562,1136.715;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;124;-1923.165,1088.375;Inherit;False;43;CutoutTex_Blend;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;125;-1125.594,1085.153;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;126;-879.3264,1084.959;Inherit;False;Color;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;127;-1316.412,858.0495;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;128;-1378.443,1058.165;Inherit;False;23;Cutout_Color;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;129;-1380.276,1144.517;Inherit;False;CutoutAlpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;130;-1185.443,888.1645;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;131;-1187.443,905.1645;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;132;-1188.443,1129.165;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;133;-1185.443,1131.165;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;134;-2324.025,1216.652;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;135;-2322.225,1215.251;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;136;-2323.125,1293.853;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;137;-2856.104,986.9715;Inherit;False;33;Cutout_Amount;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;138;-2826.298,885.1535;Inherit;False;Property;_Cutout_Amount;Cutout_Amount;18;0;Create;True;0;0;0;False;0;False;0;-1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;139;-2631.794,891.6445;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;140;-2413.184,892.9825;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;-1;False;2;FLOAT;1;False;3;FLOAT;-7;False;4;FLOAT;10;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;141;-2174.302,893.0464;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;143;-2163.646,1414.708;Inherit;False;Property;_Cutout_Outline_Border;Cutout_Outline_Border ;20;0;Create;True;0;0;0;False;0;False;0.1;0.1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;144;-1613.938,954.2065;Inherit;False;Property;_Main_Color;Main_Color;6;1;[HDR];Create;True;0;0;0;False;0;False;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;145;-1903.383,889.2145;Inherit;False;146;Main_Pow;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;146;-730.7295,271.846;Inherit;False;Main_Pow;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;147;-1886.91,818.6575;Inherit;False;Property;_Main_Pow;Main_Pow;9;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;148;-1563.756,840.1085;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;149;677.8794,-1068.431;Inherit;False;Property;_Use_ThridColor;Use_ThridColor;5;0;Create;True;0;0;0;False;0;False;0;True;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;150;-669.8723,-777.2843;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;151;-512.9653,-776.9143;Inherit;False;MainTexR;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;102;-74.32837,-252.1021;Inherit;False;Constant;_Float2;Float 2;26;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;1323.458,-885.3006;Float;False;True;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;VFX/S_MasterShader_01;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;True;True;0;True;_CullMode;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;True;True;1;5;False;;10;True;_BlendMode;1;1;False;;10;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;True;True;2;False;;True;3;True;_ZTest1;True;True;0;False;;0;False;;True;1;LightMode=UniversalForwardOnly;False;False;0;;0;0;Standard;23;Surface;1;638476375663980686;  Blend;0;0;Two Sided;1;0;Forward Only;0;0;Cast Shadows;0;638476375681868958;  Use Shadow Threshold;0;0;Receive Shadows;0;638476375705996290;GPU Instancing;0;638476375685899147;LOD CrossFade;0;638476375697244438;Built-in Fog;0;638476375700913435;DOTS Instancing;0;0;Meta Pass;0;0;Extra Pre Pass;0;0;Tessellation;0;0;  Phong;0;0;  Strength;0.5,False,;0;  Type;0;0;  Tess;16,False,;0;  Min;10,False,;0;  Max;25,False,;0;  Edge Length;16,False,;0;  Max Displacement;25,False,;0;Vertex Position,InvertActionOnDeselection;1;0;0;10;False;True;False;True;False;False;True;True;True;True;False;;False;0
Node;AmplifyShaderEditor.ToggleSwitchNode;55;-1608.612,-782.8058;Inherit;False;Property;_Use_Custom;Use_Custom;3;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ToggleSwitchNode;64;-1222.724,-359.7287;Inherit;False;Property;_Use_Custom;Use_Custom;3;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;152;-569.3035,-683.2283;Inherit;False;Property;_Use_Alpha;Use_Alpha;8;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;114;660.1396,-877.4973;Inherit;False;Property;_Use_ThridDissolveColor;Use_ThridDissolveColor;15;0;Create;True;0;0;0;False;0;False;0;True;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;60;-1628.124,-1035.038;Inherit;False;0;66;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;98;-3880.343,-903.242;Inherit;False;0;97;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;40;-1744.315,194.6515;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;41;-1964.038,149.7577;Inherit;False;96;SecondTexR;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;42;-1956.529,219.5416;Inherit;False;73;ThirdTexR;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;43;-1501.034,193.2368;Inherit;False;CutoutTex_Blend;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;38;-2135.434,344.1525;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;44;-2368.434,390.1525;Inherit;False;119;Cutout_Blend;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;70;-2410.479,243.3525;Inherit;False;Property;_Cutout_Blend;Cutout_Blend;21;0;Create;True;0;0;0;False;0;False;0;-0.7;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;39;-2021.587,311.1144;Inherit;False;Property;_Use_Custom;Use_Custom;3;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;73;-2877.02,144.1178;Inherit;False;ThirdTexR;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;74;-2868.611,64.76802;Inherit;False;ThirdTex;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;75;-3556.233,116.3142;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WireNode;76;-3540.233,116.3142;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FunctionNode;77;-3460.233,84.31422;Inherit;False;S_UV_01;-1;;31;e25fc9644ee19a54fa2cb37170096ce6;0;4;6;FLOAT2;0,0;False;8;FLOAT2;1,1;False;13;FLOAT2;0,0;False;18;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WireNode;84;-3566.053,-71.63408;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WireNode;85;-3564.481,-64.11668;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;90;-3165.881,74.62367;Inherit;True;Property;_ThridColorTex;ThridColorTex;14;0;Create;True;0;0;0;False;0;False;-1;6bbfa4e77d840ad418b592c285d67bfa;6bbfa4e77d840ad418b592c285d67bfa;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;80;-3873.031,81.91423;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;116;-4457.643,65.13191;Inherit;False;Constant;_Third_TileOffset;Third_Tile/Offset;17;0;Create;True;0;0;0;False;0;False;1,1,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;78;-4110.631,163.5139;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;79;-3892.235,236.3144;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;89;-3625.507,271.4473;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;117;-3865.098,342.0864;Inherit;False;Property;_Third_Panning;Third_Panning;13;0;Create;True;0;0;0;False;0;False;0,0,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;86;-3826.044,-108.4853;Inherit;False;0;90;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;92;-4110.632,269.1144;Inherit;False;37;ThirdUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ToggleSwitchNode;81;-3736.231,161.9139;Inherit;False;Property;_Use_Custom;Use_Custom;3;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;19;-4140.813,1034.428;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;20;-3918.404,1099.324;Inherit;False;Constant;_Float0;Float 0;27;0;Create;True;0;0;0;False;0;False;20;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;21;-3761.345,1033.137;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;22;-3768.92,831.3525;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;23;-3283.656,837.4305;Inherit;False;Cutout_Color;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;35;-4382.454,1102.326;Inherit;False;74;ThirdTex;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;71;-4394.654,922.7255;Inherit;False;Property;_Outline_Pow;Outline_Pow;17;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;72;-4133.919,865.6575;Inherit;False;Property;_EdgeColor;EdgeColor;16;1;[HDR];Create;True;0;0;0;False;0;False;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ToggleSwitchNode;115;-3558.657,835.2585;Inherit;False;Property;_Use_ThridDissolveColor;Use_ThridDissolveColor;7;0;Create;True;0;0;0;False;0;False;0;True;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;142;-2572.724,1274.906;Inherit;False;Property;_Cutout_Hardness;Cutout_Hardness;19;0;Create;True;0;0;0;False;0;False;0.1;0.1;0;1;0;1;FLOAT;0
WireConnection;25;0;66;0
WireConnection;25;1;24;0
WireConnection;31;0;30;3
WireConnection;31;1;30;4
WireConnection;32;0;30;1
WireConnection;32;1;30;2
WireConnection;33;0;29;1
WireConnection;34;0;25;0
WireConnection;36;0;32;0
WireConnection;37;0;31;0
WireConnection;45;0;60;0
WireConnection;46;0;45;0
WireConnection;47;0;46;0
WireConnection;49;0;48;1
WireConnection;49;1;48;2
WireConnection;51;0;59;3
WireConnection;51;1;59;4
WireConnection;52;0;51;0
WireConnection;52;1;50;0
WireConnection;53;0;48;3
WireConnection;53;1;48;4
WireConnection;54;0;53;0
WireConnection;56;6;57;0
WireConnection;56;13;49;0
WireConnection;56;18;55;0
WireConnection;57;0;58;0
WireConnection;58;0;47;0
WireConnection;61;0;56;0
WireConnection;61;1;63;0
WireConnection;61;2;64;0
WireConnection;63;0;62;0
WireConnection;65;0;67;0
WireConnection;65;1;68;0
WireConnection;66;1;61;0
WireConnection;69;0;29;4
WireConnection;93;0;97;0
WireConnection;94;0;95;3
WireConnection;94;1;95;4
WireConnection;96;0;97;1
WireConnection;97;1;118;0
WireConnection;101;0;100;0
WireConnection;105;0;104;0
WireConnection;105;1;103;0
WireConnection;105;2;113;0
WireConnection;105;3;100;4
WireConnection;106;0;105;0
WireConnection;110;0;114;0
WireConnection;110;1;101;0
WireConnection;110;2;149;0
WireConnection;112;0;34;0
WireConnection;112;1;106;0
WireConnection;113;0;102;0
WireConnection;113;1;107;0
WireConnection;118;6;98;0
WireConnection;118;13;99;0
WireConnection;118;18;94;0
WireConnection;119;0;29;2
WireConnection;120;0;141;0
WireConnection;120;1;142;0
WireConnection;121;0;141;0
WireConnection;121;1;134;0
WireConnection;122;0;120;0
WireConnection;122;1;143;0
WireConnection;123;0;124;0
WireConnection;123;1;121;0
WireConnection;123;2;122;0
WireConnection;125;0;128;0
WireConnection;125;1;133;0
WireConnection;125;2;129;0
WireConnection;126;0;125;0
WireConnection;127;0;148;0
WireConnection;127;1;144;0
WireConnection;129;0;123;0
WireConnection;130;0;127;0
WireConnection;131;0;130;0
WireConnection;132;0;131;0
WireConnection;133;0;132;0
WireConnection;134;0;135;0
WireConnection;135;0;136;0
WireConnection;136;0;142;0
WireConnection;139;0;138;0
WireConnection;139;1;137;0
WireConnection;140;0;139;0
WireConnection;141;0;140;0
WireConnection;141;1;142;0
WireConnection;146;0;29;3
WireConnection;148;0;147;0
WireConnection;148;1;145;0
WireConnection;149;0;109;0
WireConnection;149;1;108;0
WireConnection;150;0;66;1
WireConnection;150;1;66;4
WireConnection;151;0;152;0
WireConnection;1;2;110;0
WireConnection;1;3;105;0
WireConnection;1;4;111;0
WireConnection;55;0;51;0
WireConnection;55;1;52;0
WireConnection;64;0;67;0
WireConnection;64;1;65;0
WireConnection;152;0;150;0
WireConnection;152;1;66;4
WireConnection;114;0;34;0
WireConnection;114;1;112;0
WireConnection;40;0;41;0
WireConnection;40;1;42;0
WireConnection;40;2;39;0
WireConnection;43;0;40;0
WireConnection;38;0;70;0
WireConnection;38;1;44;0
WireConnection;39;0;70;0
WireConnection;39;1;38;0
WireConnection;73;0;90;1
WireConnection;74;0;90;0
WireConnection;75;0;85;0
WireConnection;76;0;75;0
WireConnection;77;6;76;0
WireConnection;77;8;80;0
WireConnection;77;13;89;0
WireConnection;77;18;81;0
WireConnection;84;0;86;0
WireConnection;85;0;84;0
WireConnection;90;1;77;0
WireConnection;80;0;116;1
WireConnection;80;1;116;2
WireConnection;78;0;116;3
WireConnection;78;1;116;4
WireConnection;79;0;78;0
WireConnection;79;1;92;0
WireConnection;89;0;117;3
WireConnection;89;1;117;4
WireConnection;81;0;78;0
WireConnection;81;1;79;0
WireConnection;19;0;71;0
WireConnection;19;1;35;0
WireConnection;21;0;19;0
WireConnection;21;1;20;0
WireConnection;22;0;71;0
WireConnection;22;1;72;0
WireConnection;23;0;115;0
WireConnection;115;0;22;0
WireConnection;115;1;21;0
ASEEND*/
//CHKSM=83BAB0C194FF6CEF108770711B797A81FEDCD805