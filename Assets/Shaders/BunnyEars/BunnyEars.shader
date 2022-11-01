Shader "Custom/BunnyEarsShader"
{
    Properties 
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Scale ("Scale", Range(0.0, 1.0)) = 0.0
        _TexBlend("Texture Blend", Range(0.0, 1.0)) = 0.0
    }

    SubShader
    {
        // No culling or depth
        /* Cull Off ZWrite Off ZTest Always */

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            // Properties
            sampler2D _MainTex;
            float _Scale;
            float _TexBlend;

            v2f vert (appdata v)
            {
                v2f o;

                // Normalize [0, 1] to [-1, 1]
                /* float3 stretch_basis = v.color.rgb * 2.0 - 1.0; */
                /* float3 basis = float3(0.25, 1, 0); */
                float3 basis = v.color.rgb;
                float3 pos = v.vertex;
                /* p = p - bp + bps => p = p * (1 + b(-1 + s)) */
                pos = pos * (1 + basis * (_Scale - 1));

                // Set varyings
                o.vertex = UnityObjectToClipPos(pos);
                o.color = v.color;
                o.uv = v.uv;
                return o;
            }


            fixed4 frag(v2f i) : SV_Target 
            {
                float4 tex = tex2D(_MainTex, i.uv);
                float4 col = i.color;
                return lerp(col, tex, _TexBlend);
            }
            ENDCG
        }
    }
}
