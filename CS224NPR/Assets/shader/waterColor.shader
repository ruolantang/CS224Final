// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/waterColor"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

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
				//float3 viewDir : TEXCOORD2;
			};

			#include "Lighting.cginc"
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = v.vertex;
				float3 viewDir = WorldSpaceViewDir(v.vertex);

				//hand tremor
				float s = 1.0f;//speed
				float f = 2000.0f;//frequency
				float t = 0.001f;//tremor amount
				float Pp = 1.0f;//pixel size of projection space
				float a = 0.5f;
				float4 v0 = sin(_Time * s + o.vertex * f) * t * Pp;
				float3 norm_normal = normalize(v.normal);
				float3 norm_viewDir = normalize(viewDir);
				o.vertex += v0 * (1 - a * dot(norm_normal, norm_viewDir));

				//o.vertex = v.vertex + float4(normalize(v.normal), 0)*0.3*sin(_Time);

				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.vertex = UnityObjectToClipPos(o.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

				fixed4 texColor = tex2D(_MainTex, i.uv);
				fixed3 albedo = texColor.rgb * _Color.rgb;
				fixed3 ambient = 2*UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
				//float3 C =  float3(0.76,0.37,0);
				float3 C = ambient;

				//Watercolor Reflectance Model
				float da = 1.0f;//dilute area variable
				float DA = (dot(worldNormal, worldLightDir) + (da-1))/da;  //the area of effect
				float c = 0.7f;
				float d = 0.8f;
				float3 Cp = float3(0.95,0.95,0.85);
				float3 Cc = C + float3(DA * c,DA * c,DA * c);//cangiante color
				float3 Cd = d * DA * (Cp - Cc) + Cc;

				//Pigment Turbulence
//				float f = 1.f;
//				float Ctrl = (sin(i.vertex.x * f)+1) / 4 + (cos(i.vertex.y * f) + 1) / 4;
//				float3 Ct;
//				if(Ctrl < 0.5){
//					Ct = pow(C, 3-(Ctrl*4));	
//				} else{
//					Ct = (Ctrl - 0.5) * 2 * (Cp - C) + C;
//				}

				return fixed4(Cd,0);
			}
			ENDCG
		}//end of pass
	}
}
