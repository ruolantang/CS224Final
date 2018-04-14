// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/pencil"
{
	Properties
	{
		//outline shader
		_Outline("Outline Width", Range(0,1)) = 0.1
		_OutlineColor("Outline Color", Color) = (0, 0, 0, 1)

		//pencil stroke textures parameters
		_Color("Color Tint", Color) = (1, 1, 1, 1)
		_TileFactor("Tile Factor", Float) = 1
		_Hatch0("Hatch 0", 2D) = "white" {}
		_Hatch1("Hatch 1", 2D) = "white" {}
		_Hatch2("Hatch 2", 2D) = "white" {}
		_Hatch3("Hatch 3", 2D) = "white" {}
		_Hatch4("Hatch 4", 2D) = "white" {}
		_Hatch5("Hatch 5", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			NAME "OUTLINE"

			Cull Front

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			//outline width and color
			uniform float _Outline;
			uniform fixed4 _OutlineColor;

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				//float4 pos : SV_POSITION;
				float4 pos : POSITION;
				float4 color : COLOR;
			};
			
			v2f vert (appdata v)
			{	
				//unity official provided shader for outline
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				float3 norm = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
				float2 offset = TransformViewToProjection(norm.xy);

				o.pos.xy += offset * o.pos.z * _Outline;
				o.color = _OutlineColor;
				return o;

				//The following is a common outline width shader
				/*
				v2f o;

				float4 pos = mul(UNITY_MATRIX_MV, v.vertex);
				float3 norm = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);

				pos = pos + float4(normalize(norm), 0) * _Outline;
				o.vertex = mul(UNITY_MATRIX_P, pos);

				return o;*/
			}


			half4 frag(v2f i) :COLOR{
				return i.color;
			}

			//common outline width shader
			//
			//float4 frag(v2f i) : SV_Target{
			//	return float4(_OutlineColor.rgb, 1);
			//}
			ENDCG
		}

		Pass{
				Tags{ "LightMode" = "ForwardBase" }

				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag 

				#pragma multi_compile_fwdbase

				#include "UnityCG.cginc"
				#include "Lighting.cginc"
				#include "AutoLight.cginc"
				#include "UnityShaderVariables.cginc"

				fixed4 _Color;
				float _TileFactor;
				sampler2D _Hatch0;
				sampler2D _Hatch1;
				sampler2D _Hatch2;
				sampler2D _Hatch3;
				sampler2D _Hatch4;
				sampler2D _Hatch5;

				struct appdata {
					float4 vertex : POSITION;
					float4 tangent : TANGENT;
					float3 normal : NORMAL;
					float2 texcoord : TEXCOORD0;
				};

				struct v2f {
					float4 pos : SV_POSITION;
					float2 uv : TEXCOORD0;
					float weight: TEXCOORD1;
					float3 worldPos : TEXCOORD2;
					SHADOW_COORDS(3)
				};

			v2f vert(appdata v) {
				v2f o;

				o.pos = UnityObjectToClipPos(v.vertex);

				o.uv = v.texcoord.xy * _TileFactor;

				float3 worldLightDir = normalize(WorldSpaceLightDir(v.vertex));
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				o.weight = dot(worldLightDir, worldNormal);

				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				TRANSFER_SHADOW(o);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target{
					fixed4 hatchColor;

			float weight = i.weight * 7.0;
			if (weight > 6.0) {
				hatchColor = fixed4(1, 1, 1, 1);
			}
			else if (weight > 5.0) {
				hatchColor = (weight - 5.0) * fixed4(1, 1, 1, 1) + (5.0 + 1.0 - weight) * tex2D(_Hatch0, i.uv);
			}
			else if (weight > 4.0) {
				hatchColor = (weight - 4.0) * tex2D(_Hatch0, i.uv) + (4.0 + 1.0 - weight) * tex2D(_Hatch1, i.uv);
			}
			else if (weight > 3.0) {
				hatchColor = (weight - 3.0) * tex2D(_Hatch1, i.uv) + (3.0 + 1.0 - weight) * tex2D(_Hatch2, i.uv);
			}
			else if (weight > 2.0) {
				hatchColor = (weight - 2.0) * tex2D(_Hatch2, i.uv) + (2.0 + 1.0 - weight) * tex2D(_Hatch3, i.uv);
			}
			else if (weight > 1.0) {
				hatchColor = (weight - 1.0) * tex2D(_Hatch3, i.uv) + (1.0 + 1.0 - weight) * tex2D(_Hatch4, i.uv);
			}
			else if (weight > 0.0) {
				hatchColor = (weight - 0.0) * tex2D(_Hatch4, i.uv) + (0.0 + 1.0 - weight) * tex2D(_Hatch5, i.uv);
			}
			else {
				hatchColor = tex2D(_Hatch5, i.uv);
			}

					UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

					return fixed4(hatchColor.rgb * _Color.rgb * atten, 1.0);
				}

				ENDCG
			}
	}
}
