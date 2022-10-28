Shader "Custom/BunnyEarsShader"
{
    Properties 
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Scale ("Scale", Range(0.0, 1.0)) = 0.0
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

            float _Scale;

            v2f vert (appdata v)
            {
                v2f o;

                // Normalize [0, 1] to [-1, 1]
                /* float3 stretch_basis = v.color.rgb * 2.0 - 1.0; */
                float3 stretch_basis = float3(0, 0, -1);
                /* float3 stretch_basis = float3(0, 0, 0); */
                /* v.vertex.xyz += stretch_basis * _Scale; */
                v.vertex.z *= _Scale;

                // Set varyings
                o.color = v.color;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            // Properties
            sampler2D _MainTex;

            fixed4 frag(v2f i) : SV_Target 
            {
                /* return tex2D(_MainTex, i.uv); */
                return i.color;
                /* return fixed4(1, 1, 0, 1); */
            }
            ENDCG
        }
    }
}
