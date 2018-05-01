// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/waterColor"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_size ("blurSize", int) = 10
		_sigma("sigma", float) = 2.0
		_bluramount("blurAmount", float) = 0.001
		_PaintTex ("Paint Texture", 2D) = "white" {}
		_PaperTex("Paaper Texture", 2D) = "white" {}
		_speed("hand tremor speed", range(0.0, 10.0)) = 1.0
		_frequency("hand tremor frequency", range(1500.0,2500.0)) = 2000.0
		_tremorAmount("tremor amount", range(0, 0.5)) = 0.01
		_pp("pixel size of projection space", range(0.1,2.0)) = 0.1
		_bleedAmount("bleed amount", range(0.001,10)) = 0.1

		//pencil
		//outline shader
		_Outline("Outline Width", Range(0,1)) = 0.1
		_OutlineColor("Outline Color", Color) = (0, 0, 0, 1)

		//pencil stroke textures parameters
		_greyScale("grey scale", float) = 0.5
		_TileFactor("Tile Factor", Float) = 1
		_Hatch0("Hatch 0", 2D) = "white" {}
		_Hatch1("Hatch 1", 2D) = "white" {}
		_Hatch2("Hatch 2", 2D) = "white" {}
		_Hatch3("Hatch 3", 2D) = "white" {}
		_Hatch4("Hatch 4", 2D) = "white" {}
		_Hatch5("Hatch 5", 2D) = "white" {}
	}


	//Common Vertex shader for blur and edge darkening
	CGINCLUDE
	#include "UnityCG.cginc"
	struct appdataA
	{
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
		float3 normal : NORMAL;
	};

	struct v2fA
	{
		float4 vertex : SV_POSITION;
		float2 uv : TEXCOORD0;
		float4 grabPos : TEXCOORD1;
	};

	#include "Lighting.cginc"
	fixed4 _Color;
	sampler2D _MainTex;
	float4 _MainTex_ST;
	float _speed;
	float _frequency;
	float _tremorAmount;
	float _pp;
	float _bleedAmount;


//	v2fA vertA(appdataA v) {
//		v2fA o;
//		o.vertex = v.vertex;
//		float3 viewDir = WorldSpaceViewDir(v.vertex);
//
//		//hand tremor
//		float s = _speed;//speed
//		float f = _frequency;//frequency
//		float t = _tremorAmount;//tremor amount
//		float Pp = _pp;//pixel size of projection space
//		float a = 0.5f;
//		float4 v0 = sin(_Time * s + o.vertex * f) * t * Pp;
//		float3 norm_normal = normalize(v.normal);
//		float3 norm_viewDir = normalize(viewDir);
//		//o.vertex += v0 * (1 - a * dot(norm_normal, norm_viewDir));
//		//o.vertex -= float4(norm_normal*0.01, 0);
//
//		o.uv = TRANSFORM_TEX(v.uv, _MainTex);
//		o.vertex = UnityObjectToClipPos(o.vertex);
//
//		o.grabPos = ComputeGrabScreenPos(o.vertex);
//		return o;
//	}

	ENDCG


	SubShader
	{
		Tags {"Queue"="Transparent" "RenderType"="Transparent" }
		//Tags {"RenderType"="Opaque"}
		LOD 100

		GrabPass
        {
            "_BackgroundTexture"
        }

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "UnityShaderVariables.cginc"
			#include "Lighting.cginc"


			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				float3 viewDir : TEXCOORD3;
				float turbulence: TEXCOORD4;
				float weight: TEXCOORD5;
				float2 uv_pencil : TEXCOORD6;
				SHADOW_COORDS(7)
			};
			/*

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;*/
			sampler2D _PaintTex;
			float4 _PaintTex_ST;


			//pencil
			float _TileFactor;
			sampler2D _Hatch0;
			sampler2D _Hatch1;
			sampler2D _Hatch2;
			sampler2D _Hatch3;
			sampler2D _Hatch4;
			sampler2D _Hatch5;
			float _greyScale;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = v.vertex;
				//o.vertex = mul(unity_ObjectToWorld, o.vertex);
				float3 viewDir = WorldSpaceViewDir(v.vertex);

				//hand tremor
				float s = _speed;//speed
				float f = _frequency;//frequency
				float t = _tremorAmount;//tremor amount
				float Pp = _pp;//pixel size of projection space
				float a = 0.5f;
				float4 v0 = sin(_Time * s + o.vertex * f) * t * Pp;
				float3 norm_normal = normalize(v.normal);
				float3 norm_viewDir = normalize(viewDir);
				o.vertex += v0 * (1 - a * dot(norm_normal, norm_viewDir));// / unity_ObjectToWorld[0][0];
				//o.vertex += float4(norm_normal*_bleedAmount, 0);
				//o.vertex += v0;

				//o.vertex = v.vertex + float4(normalize(v.normal), 0)*0.3*sin(_Time);

				o.turbulence = 0.5 + pow(sin(_Time * s + o.vertex * 1000)*0.72, 7);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.vertex = UnityObjectToClipPos(o.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = o.vertex.xyz;
				//o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.viewDir = viewDir;

				//pencil
				o.uv_pencil = v.uv.xy * _TileFactor;
				float3 worldLightDir = normalize(WorldSpaceLightDir(v.vertex));
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				o.weight = dot(worldLightDir, worldNormal);
				TRANSFER_SHADOW(o)

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				float3 viewDir = normalize(i.viewDir);

				fixed4 texColor = tex2D(_MainTex, i.uv);
				fixed3 albedo = texColor.rgb * _Color.rgb;
				fixed3 ambient = 2*UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
				//float3 C =  float3(0.76,0.37,0);
				float3 C = ambient;

				//Watercolor Reflectance Model
				float da = 1.0f;//dilute area variable
				float DA = (max(0,dot(worldNormal, worldLightDir)) + (da-1))/da;  //the area of effect
				float c = 0.7f;
				float d = 0.8f;
				float3 Cp = float3(0.95,0.95,0.85);
				float3 Cc = C + float3(DA * c,DA * c,DA * c);//cangiante color
				float3 Cd = d * DA * (Cp - Cc) + Cc;

				//Pigment Turbulence
				float f = 1.f;
				fixed4 noise = tex2D(_PaintTex, i.uv);
				float Ctrl = i.turbulence;
				//float Ctrl = noise[1];
				float3 Ct;
				if(Ctrl < 0.5){
					Ct = pow(Cd, 3-(Ctrl*4));	
				} else{
					Ct = (Ctrl - 0.5) * 2 * (Cp - Cd) + Cd;
				}

				Cd = Cd + (Cp - Cd) * Ct;
				//Cd = max(0,Ct);
				//Edge
				float normal_dot_dir = abs(dot(worldNormal, viewDir));
				if(normal_dot_dir < 0.40){
					//Cd = Cd * max(normal_dot_dir-0.15,0) * 4;
					//Cd = float3(0,0,0);
				}

				//pencil
				fixed4 hatchColor;

				float weight = i.weight * 7.0;
				if (weight > 6.0) {
					hatchColor = fixed4(1, 1, 1, 1);
				}
				else if (weight > 5.0) {
					hatchColor = (weight - 5.0) * fixed4(1, 1, 1, 1) + (5.0 + 1.0 - weight) * tex2D(_Hatch0, i.uv_pencil);
				}
				else if (weight > 4.0) {
					hatchColor = (weight - 4.0) * tex2D(_Hatch0, i.uv_pencil) + (4.0 + 1.0 - weight) * tex2D(_Hatch1, i.uv_pencil);
				}
				else if (weight > 3.0) {
					hatchColor = (weight - 3.0) * tex2D(_Hatch1, i.uv_pencil) + (3.0 + 1.0 - weight) * tex2D(_Hatch2, i.uv_pencil);
				}
				else if (weight > 2.0) {
					hatchColor = (weight - 2.0) * tex2D(_Hatch2, i.uv_pencil) + (2.0 + 1.0 - weight) * tex2D(_Hatch2, i.uv_pencil);
				}
				else if (weight > 1.0) {
					hatchColor = (weight - 1.0) * tex2D(_Hatch3, i.uv_pencil) + (1.0 + 1.0 - weight) * tex2D(_Hatch3, i.uv_pencil);
				}
				else if (weight > 0.0) {
					hatchColor = (weight - 0.0) * tex2D(_Hatch4, i.uv_pencil) + (0.0 + 1.0 - weight) * tex2D(_Hatch3, i.uv_pencil);
				}
				else {
					hatchColor = tex2D(_Hatch3, i.uv_pencil);
				}

				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

				fixed4 pencilTemp = fixed4(hatchColor.rgb * _Color.rgb * atten, 1.0);
				float grey = (pencilTemp.x + pencilTemp.y + pencilTemp.z) / 3.0;

				//return min(_greyScale*grey, 1.0) * fixed4(Cd,0);
				return fixed4(Cd,1);
			}
			ENDCG
		}//end of pass

		
//		// Paper Granulation
//		Pass
//		{
//			CGPROGRAM
//			#pragma vertex vertA
//			#pragma fragment frag
//			#include "UnityCG.cginc"
//			sampler2D _ColorTexture;
//			sampler2D _PaintTex;
//			sampler2D _PaperTex;
//			float4 _PaintTex_ST;
//
//			half4 frag(v2fA i) : SV_Target
//			{
//				half4 bgcolor = tex2Dproj(_ColorTexture, i.grabPos);
//				fixed4 ctrlImg = tex2D(_PaintTex, i.uv);
//				fixed4 paperIv = half4(1, 1, 1, 1) - tex2D(_PaperTex, i.uv);
//				float density = 0.5;
//
//				//float saturation = pow(bgcolor.x * bgcolor.x + bgcolor.y * bgcolor.y + bgcolor.z * bgcolor.z, 0.5);
//				float saturation = pow(dot(bgcolor.xyz, bgcolor.xyz), 0.5);
//				float saturationPaper = pow(paperIv.x * paperIv.x + paperIv.y * paperIv.y + paperIv.z * paperIv.z, 0.5);
//				half4 ig = bgcolor*(saturation - saturationPaper) + (half4(1, 1, 1, 1) - bgcolor)*pow(saturation, 1 + ctrlImg.y * saturationPaper * density);
//				return ig;
//			}
//			ENDCG
//		}
		
//
//		GrabPass
//		{
//			"_PaperTexture"
//		}
		
		
//		Pass
//		{
//			CGPROGRAM
//			#pragma vertex vert
//			#pragma fragment frag
//			
//			#include "UnityCG.cginc"
//
//			struct appdata
//			{
//				float4 vertex : POSITION;
//				float2 uv : TEXCOORD0;
//				float3 normal : NORMAL;
//			};
//
//			struct v2f
//			{
//				float2 uv : TEXCOORD0;
//				float4 vertex : SV_POSITION;
//				float3 worldNormal : TEXCOORD1;
//				float3 worldPos : TEXCOORD2;
//				float3 viewDir : TEXCOORD3;
//				float turbulence: TEXCOORD4;
//				float4 grabPos : TEXCOORD5;
//			};
//			/*
//			#include "Lighting.cginc"
//			fixed4 _Color;
//			sampler2D _MainTex;
//			float4 _MainTex_ST;*/
//			sampler2D _PaintTex;
//			float4 _PaintTex_ST;
//
//			v2f vert (appdata v)
//			{
//				v2f o;
//				o.vertex = v.vertex;
//				//o.vertex = mul(unity_ObjectToWorld, o.vertex);
//				float3 viewDir = WorldSpaceViewDir(v.vertex);
//
//				//hand tremor
//				float s = _speed;//speed
//				float f = _frequency;//frequency
//				float t = _tremorAmount;//tremor amount
//				float Pp = _pp;//pixel size of projection space
//				float a = 0.5f;
//				float4 v0 = sin(_Time * s + o.vertex * f) * t * Pp;
//				float3 norm_normal = normalize(v.normal);
//				float3 norm_viewDir = normalize(viewDir);
//				//o.vertex += v0 * (1 - a * dot(norm_normal, norm_viewDir));// / unity_ObjectToWorld[0][0];
//				//o.vertex += float4(norm_normal*0.1, 0);
//				//o.vertex += v0;
//				//o.vertex = v.vertex + float4(normalize(v.normal), 0)*0.3*sin(_Time);
//
//				o.turbulence = 0.5 + pow(sin(_Time * s + o.vertex * 1000)*0.72, 7);
//				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
//				o.vertex = UnityObjectToClipPos(o.vertex);
//				o.worldNormal = UnityObjectToWorldNormal(v.normal);
//				o.worldPos = o.vertex.xyz;
//				//o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
//				o.viewDir = viewDir;
//				o.grabPos = ComputeGrabScreenPos(o.vertex);
//				return o;
//			}
//
//			sampler2D _BackgroundTexture;
//			sampler2D _ColorTexture;
//			//sampler2D _BlurTexture;
//			//sampler2D _PaperTexture;
//			
//			fixed4 frag (v2f i) : SV_Target
//			{
//				fixed3 worldNormal = normalize(i.worldNormal);
//				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
//				float3 viewDir = normalize(i.viewDir);
//
//				fixed4 control = tex2D(_PaintTex, i.uv);
//				fixed4 bg = tex2Dproj(_BackgroundTexture, i.grabPos);
//				fixed4 color = tex2Dproj(_ColorTexture, i.grabPos);
//				//fixed4 blur = tex2Dproj(_BlurTexture, i.grabPos);
//				//fixed4 paper = tex2Dproj(_PaperTexture, i.grabPos);
//
//				//float4 c = color + (blur-color) * control[0];
//
//				//float4 Icb = color + (blur-color) * control[0];
//				//float4 diff = blur - color;
//				//float4 Ied = pow(Icb, 1 + control[1]*max(max(diff.x,diff.y),diff.z));
//				//return c + (bg+paper) * (1-c[3]);
//				return color;
//			}
//			ENDCG
//		}//end of pass
		

	}
	FallBack "VertexLit"
}
