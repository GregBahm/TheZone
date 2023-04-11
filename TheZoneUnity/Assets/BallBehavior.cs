using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BallBehavior : MonoBehaviour
{
    [SerializeField]
    private float gain;

    [SerializeField]
    private float resetHeight;

    private float velocity;

    Vector3 startingPos;

    private void Start()
    {
        startingPos = transform.position;
    }

    void Update()
    {
        if(transform.position.y < 0)
        {
            velocity = gain * 10 * Time.deltaTime;
        }
        else
        {
            velocity += gain * Time.deltaTime;
        }
        transform.position = new Vector3(transform.position.x, transform.position.y + velocity, transform.position.z);

        if(transform.position.y > resetHeight)
        {
            velocity = 0;
            transform.position = startingPos;
        }
    }
}
