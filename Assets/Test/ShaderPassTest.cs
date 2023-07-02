using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class ShaderPassTest : MonoBehaviour
{
    public Material mat;
    public bool useOutline = false;


    public void Update()
    {
        if (useOutline)
        {
            mat.SetShaderPassEnabled("OutlineNormal", true);
        }
        else
        {
            mat.SetShaderPassEnabled("OutlineNormal", false);
        }
    }

}
