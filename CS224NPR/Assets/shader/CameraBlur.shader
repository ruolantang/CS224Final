Shader "Unlit/CameraBlur"
{
	Properties
	{
		_CamTex("cameraTexture", 2D) = "white" {}
		_size("blurSize", int) = 10
		_sigma("sigma", float) = 2.0
		_bluramount("blurAmount", float) = 0.001

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

			sampler2D _CamTex;
			float4 _CamTex_ST;
			int _size;
			float _sigma;
			float _bluramount;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _CamTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				half4 bgcolor = half4(0, 0, 0, 0);
				int size = _size;
				float sigma = _sigma;
				float bluramount = _bluramount;

				for (int itx = -size; itx < size + 1; itx++) {
					//for (int ity = -0; ity < 0 + 1; ity++) {
					float dis = itx*itx;
					//float pdf = sigma;
					float pdf = 0.39894*exp(-0.5*dis / (sigma*sigma)) / sigma;
					bgcolor += pdf * tex2D(_CamTex, float2(i.uv.x + itx*bluramount, i.uv.y));
					//bgcolor += pdf1*pdf2 * tex2Dproj(_ColorTexture, UNITY_PROJ_COORD(float4(i.grabPos.x + itx*bluramount, i.grabPos.y + ity*bluramount, i.grabPos.z, i.grabPos.w)));
				}
				return bgcolor;
			}
			ENDCG
		}

		GrabPass
        {
            "_BackgroundTexture"
        }


	}
}
