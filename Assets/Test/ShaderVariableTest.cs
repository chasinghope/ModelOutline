using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class ShaderVariableTest : MonoBehaviour
{
    public Material mat;
    private LocalKeyword exampleFeatureKeyword;
    public bool useOutline = false;

    public void Start()
    {
        exampleFeatureKeyword = new LocalKeyword(mat.shader, "_OUTLINE");
    }

    public void Update()
    {
        if (useOutline)
        {
            mat.EnableKeyword(exampleFeatureKeyword);
        }
        else
        {
            mat.DisableKeyword(exampleFeatureKeyword);
        }
    }

}
