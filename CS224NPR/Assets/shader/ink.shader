// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "NPR/Ink" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Main Tex", 2D) = "white" {}
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(8.0, 256)) = 20
		_Tooniness("Tooniness" , Range(0.1,20) ) = 4
		_EdgeThread("EdgeThread" , Range(0,0.5) ) = 0.1
		_blackScale("black scale" , float) = 2
		_black("black", 2D ) = "white" {}
		_OutColor( "OutColor" , Color) = (0,0,0,0)
		_White1("white1",2D)= "white" {}
		_White1Adjust("white1 adjust" , Vector) = (0,0,0,0)
		_White1Color( "White1 Color" , Color) = (1,1,1,1)
	}
	SubShader {		
		Pass { 
			Tags { "LightMode"="ForwardBase" "RenderType"="Opaque"}
		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase

			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Specular;
			float _Gloss;
			float _Tooniness;
			float _EdgeThread;
			float _blackScale;
			sampler2D _black;
			float4 _black_ST;
			fixed4 _OutColor;
			sampler2D _White1;
			float4 _White1_ST;
			float4 _White1Adjust;
			fixed4 _White1Color;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2;
				SHADOW_COORDS(3)
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

				TRANSFER_SHADOW(o)
				
				return o;
			}

			fixed4 GetColorFromTexture( sampler2D tex , float2 uv, float4 adjust )
			{
			   	  float xx = cos(adjust.z) * ( uv.x ) + sin( adjust.z ) * uv.y;
			   	  float yy = - sin(adjust.z) * ( uv.x ) + cos( adjust.z ) * uv.y;
			   	  float2 index = float2( xx , yy ) / adjust.w + adjust.xy;
			   	  fixed4 res = tex2D( tex , index );
			   	  res.a = (res.r + res.g + res.b ) / 3;
			   	  return res;
			}

			
			fixed4 frag(v2f i) : SV_Target {
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				
				// Use the texture to sample the diffuse color
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
				
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
				
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				//fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
				fixed shadow = SHADOW_ATTENUATION(i);
				fixed3 col = ambient + diffuse ;//* shadow;

				col = floor( col * _Tooniness ) / _Tooniness;

				//edge
				fixed4 outline = fixed4(1,1,1,1);
				float vdotn = dot( viewDir , worldNormal );
				float f = pow(vdotn,2);
				if(f < _EdgeThread){//edge
					float2 findColor = float2(f*2.5f,i.uv.x/2.0f + i.uv.y/2.0f) / _blackScale;
			     	outline = tex2D(_black, findColor);
			     	outline.a = (outline.r + outline.g + outline.b ) / 3;
			     	outline *= _OutColor;
			     	//return outline;
				}else{//inner
					fixed4 col1 = GetColorFromTexture( _White1 , i.uv , _White1Adjust );
				 	col1.rgb = 0.2*_White1Color.rgb +0.8* col.rgb;
				  	col1.a *= _White1Color.a;
				  	outline = col1;
				  	return col1;
				}

				return outline;
			}
			
			ENDCG
		}
	} 
	FallBack "Specular"
}