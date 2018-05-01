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

		//outline shader
		_EdgeThread("EdgeThread" , Range(0,0.5) ) = 0.1
		_OutColor( "OutColor" , Color) = (0,0,0,0)
		_blackScale("black scale" , float) = 2
		_black("black", 2D ) = "white" {}

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
	sampler2D _black;
	float4 _black_ST;


	ENDCG


	SubShader
	{
		//Tags {"Queue"="Transparent" "RenderType"="Opaque" }
		Tags {"RenderType"="Opaque"}
		LOD 100

		GrabPass
        {
            "_BackgroundTexture"
        }

		Pass
		{
			Tags { "LightMode"="ForwardBase" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase

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

				SHADOW_COORDS(6)
			};
			/*

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;*/
			sampler2D _PaintTex;
			float4 _PaintTex_ST;
			fixed4 _OutColor;
			float _EdgeThread;
			float _blackScale;

			
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

				float3 worldLightDir = normalize(WorldSpaceLightDir(v.vertex));
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				o.weight = dot(worldLightDir, worldNormal);
				//TRANSFER_SHADOW(o)

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
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
				fixed shadow = SHADOW_ATTENUATION(i);
				//float3 C =  float3(0.76,0.37,0);
				float3 C = ambient+diffuse*shadow;

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
				//float normal_dot_dir = abs(dot(worldNormal, viewDir));
				fixed4 outline = fixed4(1,1,1,1);
				float vdotn = abs(dot( viewDir , worldNormal ));
				float ff = pow(vdotn,2);
				if(ff < _EdgeThread){//edge
					float2 findColor = float2(f*2.5f,i.uv.x/2.0f + i.uv.y/2.0f) / _blackScale;
			     	outline = tex2D(_black, findColor);
			     	outline.a = (outline.r + outline.g + outline.b ) / 3;
			     	outline *= _OutColor;
					return outline;
				}else{//inner
//					fixed4 col1 = GetColorFromTexture( _White1 , i.uv , _White1Adjust );
//				 	col1.rgb = 0.2*_White1Color.rgb +0.8* col.rgb;
//				  	col1.a *= _White1Color.a;
//				  	outline = col1;
//				  	return col1;
				}

				//return outline;


				return fixed4(Cd,1);
			}
			ENDCG
		}//end of pass
		

	}
	Fallback "Diffuse"
	//FallBack "Specular"
}
