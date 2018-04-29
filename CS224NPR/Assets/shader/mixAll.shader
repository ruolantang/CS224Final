Shader "Unlit/mixAll"
{
	Properties
	{
		_beforeTex("Before Blur Texture", 2D) = "white" {}
		_afterTex ("After Blur Texture", 2D) = "white" {}
		_ctrlTex("Control Texture", 2D) = "white" {}
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
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _beforeTex;
			float4 _beforeTex_ST;
			sampler2D _afterTex;
			float4 _afterTex_ST;
			sampler2D _ctrlTex;
			float4 _ctrlTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _beforeTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 control = tex2D(_ctrlTex, i.uv);
				//fixed4 bg = tex2Dproj(_BackgroundTexture, i.grabPos);
				fixed4 color = tex2D(_beforeTex, i.uv);
				fixed4 blur = tex2D(_afterTex, i.uv);
				//fixed4 paper = tex2Dproj(_PaperTexture, i.grabPos);

				//float4 c = color + (blur-color) * control[0];

				float4 Icb = color + (blur-color) * control[0];
				float4 diff = blur - color;
				float4 Ied = pow(Icb, 1 + control[1]*max(max(diff.x,diff.y),diff.z));
				//return c + (bg+paper) * (1-c[3]);
				return color;
			}
			ENDCG
		}
	}
}
