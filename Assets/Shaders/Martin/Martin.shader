Shader "Custom/Martin"
{
    Properties 
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Scale ("Scale", Range(0.0, 1.0)) = 0.0
        _TexBlend("Texture Blend", Range(0.0, 1.0)) = 0.0
        _ColorScale ("Color Scale", Range(0.0, 1.0)) = 0.0
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

            inline float unity_noise_randomValue (float2 uv)
            {
                return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453);
            }

            inline float unity_noise_interpolate (float a, float b, float t)
            {
                return (1.0-t)*a + (t*b);
            }

            inline float unity_valueNoise (float2 uv)
            {
                float2 i = floor(uv);
                float2 f = frac(uv);
                f = f * f * (3.0 - 2.0 * f);

                uv = abs(frac(uv) - 0.5);
                float2 c0 = i + float2(0.0, 0.0);
                float2 c1 = i + float2(1.0, 0.0);
                float2 c2 = i + float2(0.0, 1.0);
                float2 c3 = i + float2(1.0, 1.0);
                float r0 = unity_noise_randomValue(c0);
                float r1 = unity_noise_randomValue(c1);
                float r2 = unity_noise_randomValue(c2);
                float r3 = unity_noise_randomValue(c3);

                float bottomOfGrid = unity_noise_interpolate(r0, r1, f.x);
                float topOfGrid = unity_noise_interpolate(r2, r3, f.x);
                float t = unity_noise_interpolate(bottomOfGrid, topOfGrid, f.y);
                return t;
            }

            void Unity_SimpleNoise_float(float2 UV, float Scale, out float Out)
            {
                float t = 0.0;

                float freq = pow(2.0, float(0));
                float amp = pow(0.5, float(3-0));
                t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                freq = pow(2.0, float(1));
                amp = pow(0.5, float(3-1));
                t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                freq = pow(2.0, float(2));
                amp = pow(0.5, float(3-2));
                t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                Out = t;
            }

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
            };

            // Properties
            sampler2D _MainTex;
            float _Scale;
            float _TexBlend;
            float _TuningParameter;

            v2f vert (appdata v)
            {
                v2f o;

                // Normalize [0, 1] to [-1, 1]
                float3 basis = v.color.rgb;
                float3 pos = v.vertex;
                /* p = p - bp + bps => p = p * (1 + b(-1 + s)) */
                pos = pos * (1 + basis * (_Scale - 1));

                // Set varyings
                o.vertex = UnityObjectToClipPos(pos);
                o.color = v.color;
                o.uv = v.uv;
                o.uv2 = v.uv2;
                return o;
            }

            float3 gaussian5x5( sampler2D tex, float2 uv, float2 pix_size )
            {
                float3 p = 0;
                float coef[25] = { 0.00390625, 0.015625, 0.0234375, 0.015625, 0.00390625, 0.015625, 0.0625, 0.09375, 0.0625, 0.015625, 0.0234375, 0.09375, 0.140625, 0.09375, 0.0234375, 0.015625, 0.0625, 0.09375, 0.0625, 0.015625, 0.00390625, 0.015625, 0.0234375, 0.015625, 0.00390625 };

                for( int y=-2; y<=2; y++ ) {
                    for( int x=-2; x<=2; x ++ ) {
                        float2 _uv = uv + float2( x, y ) * pix_size;
                        p += tex2D( tex, _uv ).rgb * coef[(y+2)*5 + (x+2)];
                    }
                }

                return p;
            }

            float _ColorScale;
            float4 _MainTex_TexelSize;

            fixed4 frag(v2f i) : SV_Target 
            {
                // Take the original texture, blur it, and reduce the color palette
                float4 tex = tex2D(_MainTex, i.uv);
                tex.rgb = gaussian5x5(_MainTex, i.uv, _MainTex_TexelSize.xy);

                // Sample the skin mask
                float4 skinMask = tex2D(_MainTex, i.uv2);
                //float4 col = i.color;
                float t;
                Unity_SimpleNoise_float(i.uv + _Time[0], 100, t);
                /* return t * skinMask; */
                //tex.rgb = (tex.r + tex.g + tex.b) / 3.0;
                float3 _Vals = 2 + floor(14 * _ColorScale);
                float4 reduced = float4(floor((_Vals - 1.0f) * tex + 0.5) / (_Vals - 1.0f), 1);
                float4 orig = tex2D(_MainTex, i.uv);
                return lerp(orig, reduced, _TuningParameter);
            }
            ENDCG
        }
    }
}
