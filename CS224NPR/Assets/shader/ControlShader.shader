// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/waterColor"
{
	Properties
	{
		_MainTex("Main Texture", 2D) = "white" {}
		_Color("Color Tint", Color) = (1, 1, 1, 1)
		_size("blurSize", int) = 10
		_sigma("sigma", float) = 2.0
		_bluramount("blurAmount", float) = 0.001
		_PaintTex("Paint Texture", 2D) = "white" {}
		_PaperTex("Paaper Texture", 2D) = "white" {}
		_speed("hand tremor speed", range(0.0, 10.0)) = 1.0
		_frequency("hand tremor frequency", range(1500.0,2500.0)) = 2000.0
		_tremorAmount("tremor amount", range(0, 0.5)) = 0.01
		_pp("pixel size of projection space", range(0.1,2.0)) = 0.1
		_bleedAmount("bleed amount", range(0.001,10)) = 0.1
	}


	SubShader
	{
		Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" }
		//Tags {"RenderType"="Opaque"}
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
		};

		#include "Lighting.cginc"
		sampler2D _PaintTex;
		float4 _PaintTex_ST;
		fixed4 _Color;
		sampler2D _MainTex;
		float4 _MainTex_ST;
		float _speed;
		float _frequency;
		float _tremorAmount;
		float _pp;
		float _bleedAmount;

		v2f vert(appdata v)
		{
			v2f o;
			o.vertex = v.vertex;
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
			o.vertex += float4(norm_normal*_bleedAmount*2.5, 0);

			o.uv = TRANSFORM_TEX(v.uv, _PaintTex);
			o.vertex = UnityObjectToClipPos(o.vertex);
			return o;
		}

		fixed4 frag(v2f i) : SV_Target
		{
			fixed4 texColor = tex2D(_PaintTex, i.uv);
			return texColor;
		}
		ENDCG
	}//end of pass
	 
}
}
