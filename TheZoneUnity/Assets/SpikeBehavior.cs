using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SpikeBehavior : MonoBehaviour
{
    [SerializeField]
    float speed;

    [SerializeField]
    float resetHeight;

    private void Update()
    {
        Vector3 offset = transform.up * speed * Time.deltaTime;
        transform.position += offset;

        if(transform.position.y > resetHeight)
        {
            transform.position -= transform.up * resetHeight * 1.5f;
        }
    }
}
