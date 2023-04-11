using System;
using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

public class RipplePip : MonoBehaviour
{
    [SerializeField]
    private float pipDuration;

    private float pipElapsed;

    [SerializeField]
    private GameObject RipplePrefab;

    private float lastY;

    private bool pipPopped;

    private GameObject pipPoppedPrefab;
    private Material pipMat;

    private void Start()
    {
        lastY = transform.position.y;
    }

    private void Update()
    {
        if(transform.position.y > 0 && lastY <= 0)
        {
            PopThePip();
        }

        if(pipPopped)
        {
            UpdatePip();
        }

        lastY = transform.position.y;
    }

    private void UpdatePip()
    {
        pipElapsed -= Time.deltaTime;
        if(pipElapsed < 0)
        {
            pipPopped = false;
            pipMat = null;
            Destroy(pipPoppedPrefab);
        }
        else
        {
            float param = 1 - (pipElapsed / pipDuration);
            pipMat.SetFloat("_RippleParam", param);
        }
    }

    private void PopThePip()
    {
        pipPoppedPrefab = Instantiate(RipplePrefab);
        pipPoppedPrefab.transform.position = transform.position;
        pipElapsed = pipDuration;
        MeshRenderer renderer = pipPoppedPrefab.GetComponent<MeshRenderer>();
        pipMat = renderer.material;
        pipPopped = true;
    }
}
