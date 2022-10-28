Shader "Custom/PostEffectShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        /* _Spread ("Spread", Range(0.0, 1.0)) = 0.0 */
        /* _Reds ("Reds", Int) = 2 */
        /* _Greens ("Greens", Int) = 2 */
        /* _Blues ("Blues", Int) = 2 */

        /* _Greyscale ("Use Greyscale", Int) = 0 */
        /* _Greys ("Greys", Int) = 2 */
    }
    
    CGINCLUDE
        #include "UnityCG.cginc"
        // Main tex for blur
        sampler2D _MainTex;
        float4 _MainTex_TexelSize;

        // Composite textures
        sampler2D _DitherTexture;
        sampler2D _EdgeTexture;

        // Edge uniforms
        float4 _EdgeColor;

        // Dither uniforms
        float _Thresh;
        sampler2D _Sampler;
        int _UseCustomSampler;
        int _Greys;
        int _Greyscale;
        int _Blues;
        int _Greens;
        int _Reds;
        float _Spread;
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

        v2f vert (appdata v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = v.uv;
            return o;
        }
    ENDCG


    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        // 0 -> Gaussian blur 5x5 pass
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

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


            fixed4 frag(v2f i) : SV_Target {
                fixed4 tex = tex2D(_MainTex, i.uv);
                tex.rgb = gaussian5x5(_MainTex, i.uv, _MainTex_TexelSize.xy);
                return tex;
            }
            ENDCG
        }

        // 1 -> Dithering pass
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float GetBayer4(int x, int y) {
                int bayer4[16] = {
                    0, 8, 2, 10,
                    12, 4, 14, 6,
                    3, 11, 1, 9,
                    15, 7, 13, 5
                };
                return float(bayer4[(x % 4) + (y % 4) * 4]) * (1.0f / 16.0f) - 0.5f;
            }

            

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 tex = tex2D(_MainTex, i.uv);

                int x = i.uv.x * _MainTex_TexelSize.z;
                int y = i.uv.y * _MainTex_TexelSize.w;

                float3 output = tex.rgb + _Spread * GetBayer4(x, y);
                if (_Greyscale) {
                    output = (output.r + output.g + output.b) / 3.0;
                    float val = floor((float(_Greys) - 1.0f) * output.r + 0.5) / (float(_Greys) - 1.0f);
                    if (_UseCustomSampler)
                        output = tex2D(_Sampler, val).rgb;
                    else
                        output = val;
                } else {
                    output.r = floor((float(_Reds) - 1.0f) * output.r + 0.5) / (float(_Reds) - 1.0f);
                    output.g = floor((float(_Greens) - 1.0f) * output.g + 0.5) / (float(_Greens) - 1.0f);
                    output.b = floor((float(_Blues) - 1.0f) * output.b + 0.5) / (float(_Blues) - 1.0f);
                }

                return fixed4(output, 1.0);
            }
            ENDCG
        }
        
        // 2 -> Canny Edge Detection pass
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            fixed4 frag(v2f i) : SV_Target {

                int Kx[9] = {
                    1, 0, -1,
                    2, 0, -2,
                    1, 0, -1
                };
                int Ky[9] = {
                    1, 2, 1,
                    0, 0, 0,
                    -1, -2, -1
                };
                
                float Gx = 0.0f;
                float Gy = 0.0f;
                
                for (int y = 0; y < 3; y++) {
                    for (int x = 0; x < 3; x++) {
                        // Grab the pixel in the 3x3 area surrounding this one.
                        float2 uv = i.uv + (float2(x, y) - 1.0) * _MainTex_TexelSize.xy;
                        float pixel = tex2D(_MainTex, uv).r;
                        
                        // ... and convolve it with the kernel.
                        Gx += pixel * float(Kx[9 - (y * 3 + x) - 1]);
                        Gy += pixel * float(Ky[9 - (y * 3 + x) - 1]);
                    }
                }
                
                float mag = sqrt( Gx * Gx + Gy * Gy );
                float theta = abs(atan2(Gy, Gx)) / 3.14159; // normalize theta to [0, 1]
                return step(_Thresh, fixed4(mag, mag, mag, 1));
            }
            ENDCG
        }

        // 3 -> Composite pass (edge and dither)
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            fixed4 frag(v2f i) : SV_Target {
                float4 edge = tex2D(_EdgeTexture, i.uv);
                edge.rgb = 1.0 - edge.rbg;
                float4 dither = tex2D(_DitherTexture, i.uv);
                float4 final = dither * edge;
                /* if (final == 0) final = _EdgeColor; */
                return final;
            }
            ENDCG
        }
    }
}
