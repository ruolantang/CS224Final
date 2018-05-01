﻿using UnityEngine;
 
[ExecuteInEditMode]
public class DepthTexture : MonoBehaviour
{

    public Material mat;

    void Start()
    {
        GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Graphics.Blit(source, destination, mat);
    }
}