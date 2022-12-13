using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class VertexController : MonoBehaviour
{
    public Material axisBoundGrowthMat;
    public Material meshOutlineMat;
    public Material martinMaterial;

    void Update() {
        /* TuningParameter.Instance.value */
        axisBoundGrowthMat.SetFloat("_Scale", TuningParameter.Instance.value);
        meshOutlineMat.SetFloat("_TuningParameter", TuningParameter.Instance.value);
        martinMaterial.SetFloat("_TuningParameter", TuningParameter.Instance.value);

    }
}
