Shader "Unlit/mixAll"
{
	Properties
	{
		_beforeTex("Before Blur Texture", 2D) = "white" {}
		_afterTex ("After Blur Texture", 2D) = "white" {}
		_ctrlTex("Control Texture", 2D) = "white" {}
		_depthTex("Depth Texture", 2D) = "white" {}
		_blurTex("After Blur Texture2", 2D) = "white" {}
		_paperTex ("Paint Texture", 2D) = "white" {}
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
			sampler2D _depthTex;
			float4 _depthTex_ST;
			sampler2D _blurTex;
			float4 _blurTex_ST;
			sampler2D _paperTex;
			float4 _paperTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _beforeTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				//R:distortion, G: Granulation, B: Darkening and bleeding, A: Turbulent and Pigment
				float4 paper = tex2D(_paperTex, i.uv);
				fixed4 control = tex2D(_ctrlTex, i.uv);
				if (control[3] <= 0.51){
					control = fixed4(0.4,0.4,0.4,1);
				}

				//fixed4 bg = tex2Dproj(_BackgroundTexture, i.grabPos);
				fixed4 color = tex2D(_beforeTex, i.uv);
				fixed4 blur = tex2D(_afterTex, i.uv);
				fixed4 depth = tex2D(_depthTex, i.uv);
				fixed4 blur2 = tex2D(_blurTex, i.uv);
				//fixed4 paper = tex2Dproj(_PaperTexture, i.grabPos);

				//float4 c = color + (blur-color) * control[0];

				float4 Icb = color + (blur-color) * min(control[2]*1.5,1);
				//Icb = color + (blur-color) * 0.5;
				float4 diff = max(0,(blur2 - color) * 5);
				float4 Ied = pow(Icb, 1 + control[2] * max(max(diff.x,diff.y),diff.z));
				//Ied = Icb;

				float maxRGB = max(Ied.x, max(Ied.y, Ied.z));
				float minRGB = min(Ied.x, min(Ied.y, Ied.z));
				float saturation = (maxRGB-minRGB)/maxRGB;

				float d = control[1]*5;
				float Piv = 1 - paper;
				float4 Ig = saturation*(Ied-Piv) + (1-saturation) * pow(Ied, 1+(control[1]*d*Piv));
				//float4 Ig = Ied*(Ied-Piv) + (1-Ied) * pow(Ied, 1+(control[1]*d*Piv));

				return Ig;// + Ied;
				//return Ig*0.5 + Ied;
			}
			ENDCG
		}
	}
}
