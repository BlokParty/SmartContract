using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class ExpandingButton : MonoBehaviour {

    [SerializeField]
    float collapsedSize;
    [SerializeField]
    float expandedSize;
    [SerializeField]
    bool collapsed = true;

    private void Start()
    {
        Vector3 position = transform.position;
        if (collapsed)
        {
            collapsedSize = GetComponent<RectTransform>().rect.height;
        }
        else
        {
            expandedSize = GetComponent<RectTransform>().rect.height;
        }
    }

    public void ToggleButtonSize()
    {
        Vector3 position = GetComponent<RectTransform>().position;
        if(collapsed)
        {
            GetComponent<RectTransform>().SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, expandedSize);
            collapsed = false;
        }
        else
        {
            GetComponent<RectTransform>().SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, collapsedSize);
            collapsed = true;
        }
            
    }
}
