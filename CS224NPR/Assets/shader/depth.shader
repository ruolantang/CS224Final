// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/Depth"
{
	SubShader
	{
		Tags{ "RenderType" = "Opaque" }

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 screenuv : TEXCOORD1;
			};

			v2f vert(appdata_base v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.screenuv = ComputeScreenPos(o.pos);
				return o;
			}

			sampler2D _CameraDepthTexture;

			fixed4 frag(v2f i) : SV_Target
			{
				float2 uv = i.screenuv.xy / i.screenuv.w;
				float depth = 1 - Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
				return fixed4(depth, depth, depth, 1);
			}
			ENDCG
		}
	}
	/*

	    SubShader {
        Tags { "RenderType"="Opaque" }
        Pass {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct v2f {
                float4 pos : SV_POSITION;
                float2 depth : TEXCOORD0;
            };

            v2f vert (appdata_base v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                UNITY_TRANSFER_DEPTH(o.depth);
                return o;
            }

            half4 frag(v2f i) : SV_Target {
                UNITY_OUTPUT_DEPTH(i.depth);
            }
            ENDCG
        }
    }
*/
}