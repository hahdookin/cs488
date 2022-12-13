Shader "Custom/MeshOutline"
{
    Properties 
    {
        _MaxScale ("Max Scale", Range(1.0, 1.5)) = 1.0
        _BorderColor ("Border Color", Color) = (0, 0, 0, 1)
    }

    SubShader
    {
        // No culling or depth
        Cull Front

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
            };

            // Properties
            float _MaxScale;
            float4 _BorderColor;
            float _TuningParameter;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex * _MaxScale * _TuningParameter);
                o.normal = v.normal * -1;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target 
            {
                return _BorderColor;
            }
            ENDCG
        }
    }
}
