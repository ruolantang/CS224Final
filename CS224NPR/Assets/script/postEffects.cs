using UnityEngine;  
using System.Collections;  

[ExecuteInEditMode]  
public class postEffects : MonoBehaviour {  

	#region Variables  
	//public Shader curShader;  
	public Material curMaterial;  
	#endregion   

	// Use this for initialization  
	void Start () {  
		
	}  

	void OnRenderImage (RenderTexture sourceTexture, RenderTexture destTexture){  
			Graphics.Blit(sourceTexture, destTexture, curMaterial);   
	}  

	// Update is called once per frame  
	void Update () {  

	}  
		 
}  