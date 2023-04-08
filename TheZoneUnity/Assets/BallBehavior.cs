using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BallBehavior : MonoBehaviour
{
    [SerializeField]
    private float offset;

    [SerializeField]
    private float scale;

    void Update()
    {
        float pos = Mathf.Sin(Time.time + offset) * scale;
        transform.position = new Vector3(transform.position.x, pos, transform.position.z);
    }
}
