using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class BunnyEarsScript : MonoBehaviour
{

    public Shader shader;
    private Material mat;
    private Texture2D samplerTex;

    void Start() {
        mat = new Material(shader);
        samplerTex = new Texture2D(4, 1);
        samplerTex.filterMode = FilterMode.Point;
        UpdateTexture();
    }

    void UpdateTexture() {
        for (int i = 0; i < samplerColors.Length; i++) {
            samplerTex.SetPixel(i, 0, samplerColors[i]);
        }
        samplerTex.Apply();
    }

    enum ShaderPass {
        GaussianBlur,
        Dither,
        EdgeDetection,
        Composite
    }

    // Uniforms for the dithering pass
    [Range(0.0f, 1.0f)]
    public float spread = 0.0f;

    [Range(2, 16)]
    public int reds = 2;

    [Range(2, 16)]
    public int greens = 2;

    [Range(2, 16)]
    public int blues = 2;

    public bool greyscale = false;

    [Range(2, 16)]
    public int greys = 2;

    public bool useCustomSampler = false;

    public Color[] samplerColors;
    
    // Uniforms for the edge detection pass
    [Range(0.0f, 1.0f)]
    public float edgeThresh = 0.25f;

    public Color edgeColor = Color.black;

    void OnRenderImage( RenderTexture src, RenderTexture dest ) {
        // Set uniforms in the editor
        // Dither uniforms
        mat.SetFloat("_Spread", spread);
        mat.SetFloat("_Reds", reds);
        mat.SetFloat("_Greens", greens);
        mat.SetFloat("_Blues", blues);
        mat.SetFloat("_Greys", greys);
        mat.SetInt("_Greyscale", greyscale ? 1 : 0);

        mat.SetInt("_UseCustomSampler", useCustomSampler ? 1 : 0);
        UpdateTexture();
        mat.SetTexture("_Sampler", samplerTex);

        // Edge Detection uniforms
        mat.SetFloat("_Thresh", edgeThresh);
        mat.SetColor("_EdgeColor", edgeColor);

        // Blur initial image, this will be reused throughout the pipeline
        RenderTexture blurSrc = RenderTexture.GetTemporary(src.width, src.height, 0, src.format);
        Graphics.Blit(src, blurSrc, mat, (int)ShaderPass.GaussianBlur);

        // Create the dithered (limited color) texture from blurred src
        RenderTexture ditherSrc = RenderTexture.GetTemporary(src.width, src.height, 0, src.format);
        Graphics.Blit(blurSrc, ditherSrc, mat, (int)ShaderPass.Dither);

        // Create the canny edge detection texture from blurred src
        RenderTexture edgeSrc = RenderTexture.GetTemporary(src.width, src.height, 0, src.format);
        Graphics.Blit(blurSrc, edgeSrc, mat, (int)ShaderPass.EdgeDetection);

        // Give our composite pass the textures...
        mat.SetTexture("_EdgeTexture", edgeSrc);
        mat.SetTexture("_DitherTexture", ditherSrc);

        // ...so just composite and render to screen.
        Graphics.Blit(src, dest, mat, (int)ShaderPass.Composite);

        // Release our temporaries
        RenderTexture.ReleaseTemporary(blurSrc);
        RenderTexture.ReleaseTemporary(ditherSrc);
        RenderTexture.ReleaseTemporary(edgeSrc);
    }
}
