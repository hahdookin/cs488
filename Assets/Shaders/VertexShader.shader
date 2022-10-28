Shader "Custom/VertexShader"
{
    Properties 
    {
        _EarsScale ("Ears Scale", Range(0.0, 1.0)) = 0.0
        _NoseScale ("Nose Scale", Range(0.0, 1.0)) = 0.0
        _MouthScale ("Mouth Scale", Range(0.0, 1.0)) = 0.0
        _MaxScale ("Max Scale", Range(0.0, 1.0)) = 0.01
    }

    SubShader
    {
        // No culling or depth
        /* Cull Off ZWrite Off ZTest Always */

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 color : COLOR;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                fixed4 color: COLOR;
            };

            // Properties
            float _NoseScale;
            float _MouthScale;
            float _EarsScale;
            float _MaxScale;

            v2f vert (appdata v)
            {
                v2f o;
                float ears = v.color.r;
                float nose = v.color.g;
                float mouth = v.color.b;
                v.vertex.xyz += v.normal * ears * _MaxScale * _EarsScale;
                v.vertex.xyz += v.normal * nose * _MaxScale * _NoseScale;
                v.vertex.xyz += v.normal * mouth * _MaxScale * _MouthScale;
                /* o.color.xyz = v.normal * 0.5 + 0.5; */
                /* o.color.xyz = v.normal; */
                o.color = v.color;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target 
            {
                return i.color;
                /* return fixed4(1, 1, 0, 1); */
            }
            ENDCG
        }
    }
}
