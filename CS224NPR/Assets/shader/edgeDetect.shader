// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/test" {  
    Properties {  
        _MainTex ("MainTex", 2D) = "white" {}  
        _Size("Size", range(1,2048)) = 256//size  
        _Color("Main Color",color)=(1,1,1,1)  
    }  
    SubShader {  

        pass{  
        Tags{"LightMode"="ForwardBase" }  
        Cull off  
        CGPROGRAM  
        #pragma vertex vert  
        #pragma fragment frag  
        #include "UnityCG.cginc"  
  
        float4 _Color;  
        float _Size;  
        sampler2D _MainTex;  
        float4 _MainTex_ST;  
        struct v2f {  
            float4 pos:SV_POSITION;  
            float2 uv_MainTex:TEXCOORD0;  
              
        };  
  
        v2f vert (appdata_full v) {  
            v2f o;  
            o.pos=UnityObjectToClipPos(v.vertex);  
            o.uv_MainTex = TRANSFORM_TEX(v.texcoord,_MainTex);  
            return o;  
        }  
        float4 frag(v2f i):COLOR  
        {//浮雕就是对图像上的一个像素和它右下的那个像素的色差的一种处理  
            float3 mc00mc = tex2D (_MainTex, i.uv_MainTex).rgb;//当前点的颜色  
            float3 mc11 = tex2D (_MainTex, i.uv_MainTex+fixed2(1,1)/_Size).rgb;//当前点右下角（偏移了（1,1）个单位）的点的颜色，  
            //由于CG函数tex2DSize函数（获取图片长宽的像素数）在unity中不能用，我也不知道用什么函数来替代它，就弄了个外部变量_Size方便调节  
  
            float3 diffs = abs( mc00mc - mc11);//diffs为亮点颜色差  
            float max0 = diffs.r>diffs.g?diffs.r:diffs.g;  
             max0 = max0>diffs.b?max0:diffs.b;//求出色差中rgb的最大值设为色差数  
             float gray = clamp(max0+0.4 , 0, 1);//灰度值其实就是这个色差数  
            float4 c = 0;  
            c = float4(gray.xxx,1)*_Color;//最终颜色  
            return c;  
        }  
        ENDCG  
        }//  
  
    }   
}  