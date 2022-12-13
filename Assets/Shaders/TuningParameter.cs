using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// Global tuning parameter
public class TuningParameter : MonoBehaviour
{
    public static TuningParameter Instance { get; private set; }
    private void Awake()
    {
        if (Instance != null && Instance != this) 
        {
            Destroy(this);
        }
        else
        {
            Instance = this;
        }
    }

    [Range(0.0f, 1.0f)]
    public float value = 1.0f;
}
