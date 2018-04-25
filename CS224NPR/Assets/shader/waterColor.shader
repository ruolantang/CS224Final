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
		_tremorAmount("tremor amount", range(0, 0.02)) = 0.01
		_pp("pixel size of projection space", range(0.1,2.0)) = 1.0
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


	v2fA vertA(appdataA v) {
		v2fA o;
		o.vertex = v.vertex;
		float3 viewDir = WorldSpaceViewDir(v.vertex);

		//hand tremor
		float s = 1.0f;//speed
		float f = 2000.0f;//frequency
		float t = 0.01f;//tremor amount
		float Pp = 1.0f;//pixel size of projection space
		float a = 0.5f;
		float4 v0 = sin(_Time * s + o.vertex * f) * t * Pp;
		float3 norm_normal = normalize(v.normal);
		float3 norm_viewDir = normalize(viewDir);
		o.vertex += v0 * (1 - a * dot(norm_normal, norm_viewDir));
		o.vertex += float4(norm_normal*0.2, 0);

		o.uv = TRANSFORM_TEX(v.uv, _MainTex);
		o.vertex = UnityObjectToClipPos(o.vertex);

		o.grabPos = ComputeGrabScreenPos(o.vertex);
		return o;
	}

	ENDCG


	SubShader
	{
		Tags {"Queue"="Transparent" "RenderType"="Transparent" }
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
			};
			/*
			#include "Lighting.cginc"
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;*/
			sampler2D _PaintTex;
			float4 _PaintTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = v.vertex;
				//o.vertex = mul(unity_ObjectToWorld, o.vertex);
				float3 viewDir = WorldSpaceViewDir(v.vertex);

				//hand tremor
				float s = 1.0f;//speed
				float f = 2000.0f;//frequency
				float t = 0.01f;//tremor amount
				float Pp = 1.0f;//pixel size of projection space
				float a = 0.5f;
				float4 v0 = sin(_Time * s + o.vertex * f) * t * Pp;
				float3 norm_normal = normalize(v.normal);
				float3 norm_viewDir = normalize(viewDir);
				o.vertex += v0 * (1 - a * dot(norm_normal, norm_viewDir));// / unity_ObjectToWorld[0][0];
				//o.vertex -= float4(norm_normal*0.2, 0);
				//o.vertex += v0;

				//o.vertex = v.vertex + float4(normalize(v.normal), 0)*0.3*sin(_Time);

				o.turbulence = 0.5 + pow(sin(_Time * s + o.vertex * 1000)*0.72, 7);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.vertex = UnityObjectToClipPos(o.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = o.vertex.xyz;
				//o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.viewDir = viewDir;
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
		
				return fixed4(Cd,1);
			}
			ENDCG
		}//end of pass

		GrabPass
        {
            "_ColorTexture"
        }

		//Blur Pass
        Pass
        {
            CGPROGRAM
            #pragma vertex vertA
            #pragma fragment frag
            #include "UnityCG.cginc"

			sampler2D _ColorTexture;
			int _size;
			float _sigma;
			float _bluramount;

            half4 frag(v2fA i) : SV_Target
            {
				half4 bgcolor = half4(0,0,0,0);
				int size = _size;
				float sigma = _sigma;
				float bluramount = _bluramount;

				for (int itx = -size; itx < size + 1; itx++) {
					for (int ity = -size; ity < size + 1; ity++) {
					//for (int ity = -0; ity < 0 + 1; ity++) {
						float dis1 = itx*itx;
						float dis2 = ity*ity;
						//float pdf = sigma;
						float pdf1 = 0.39894*exp(-0.5*dis1 / (sigma*sigma)) / sigma;
						float pdf2 = 0.39894*exp(-0.5*dis2 / (sigma*sigma)) / sigma;
						bgcolor += pdf1*pdf2 * tex2Dproj(_ColorTexture, UNITY_PROJ_COORD(float4(i.grabPos.x + itx*bluramount, i.grabPos.y + ity*bluramount, i.grabPos.z, i.grabPos.w)));
					}

				}
				//fixed4 noise = tex2D(_PaintTex, i.uv);
               // bgcolor = tex2Dproj(_ColorTexture, i.uv);
               return bgcolor;

            }
            ENDCG
        }

		GrabPass
		{
			"_BlurTexture"
		}
		
		// Paper Granulation
		Pass
		{
			CGPROGRAM
			#pragma vertex vertA
			#pragma fragment frag
			#include "UnityCG.cginc"
			sampler2D _ColorTexture;
			sampler2D _PaintTex;
			sampler2D _PaperTex;
			float4 _PaintTex_ST;

			half4 frag(v2fA i) : SV_Target
			{
				half4 bgcolor = tex2Dproj(_ColorTexture, i.grabPos);
				fixed4 ctrlImg = tex2D(_PaintTex, i.uv);
				fixed4 paperIv = half4(1, 1, 1, 1) - tex2D(_PaperTex, i.uv);
				float density = 0.5;

				//float saturation = pow(bgcolor.x * bgcolor.x + bgcolor.y * bgcolor.y + bgcolor.z * bgcolor.z, 0.5);
				float saturation = pow(dot(bgcolor.xyz, bgcolor.xyz), 0.5);
				float saturationPaper = pow(paperIv.x * paperIv.x + paperIv.y * paperIv.y + paperIv.z * paperIv.z, 0.5);
				half4 ig = bgcolor*(saturation - saturationPaper) + (half4(1, 1, 1, 1) - bgcolor)*pow(saturation, 1 + ctrlImg.y * saturationPaper * density);
				return ig;
			}
			ENDCG
		}
		

		GrabPass
		{
			"_PaperTexture"
		}

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

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
				float4 grabPos : TEXCOORD5;
			};
			/*
			#include "Lighting.cginc"
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;*/
			sampler2D _PaintTex;
			float4 _PaintTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = v.vertex;
				//o.vertex = mul(unity_ObjectToWorld, o.vertex);
				float3 viewDir = WorldSpaceViewDir(v.vertex);

				//hand tremor
				float s = 1.0f;//speed
				float f = 2000.0f;//frequency
				float t = 0.01f;//tremor amount
				float Pp = 1.0f;//pixel size of projection space
				float a = 0.5f;
				float4 v0 = sin(_Time * s + o.vertex * f) * t * Pp;
				float3 norm_normal = normalize(v.normal);
				float3 norm_viewDir = normalize(viewDir);
				o.vertex += v0 * (1 - a * dot(norm_normal, norm_viewDir));// / unity_ObjectToWorld[0][0];
				o.vertex += float4(norm_normal*0.2, 0);
				//o.vertex += v0;
				//o.vertex = v.vertex + float4(normalize(v.normal), 0)*0.3*sin(_Time);

				o.turbulence = 0.5 + pow(sin(_Time * s + o.vertex * 1000)*0.72, 7);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.vertex = UnityObjectToClipPos(o.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = o.vertex.xyz;
				//o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.viewDir = viewDir;
				o.grabPos = ComputeGrabScreenPos(o.vertex);
				return o;
			}

			sampler2D _BackgroundTexture;
			sampler2D _ColorTexture;
			sampler2D _BlurTexture;
			sampler2D _PaperTexture;
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				float3 viewDir = normalize(i.viewDir);

				fixed4 control = tex2D(_PaintTex, i.uv);
				fixed4 bg = tex2Dproj(_BackgroundTexture, i.grabPos);
				fixed4 color = tex2Dproj(_ColorTexture, i.grabPos);
				fixed4 blur = tex2Dproj(_BlurTexture, i.grabPos);
				fixed4 paper = tex2Dproj(_PaperTexture, i.grabPos);

				float4 c = color + (blur-color) * control[0];

				float4 Icb = color + (blur-color) * control[0];
				float4 diff = blur - color;
				float4 Ied = pow(Icb, 1 + control[1]*max(max(diff.x,diff.y),diff.z));
				//return c + (bg+paper) * (1-c[3]);
				return Ied;
			}
			ENDCG
		}//end of pass
	}
}
