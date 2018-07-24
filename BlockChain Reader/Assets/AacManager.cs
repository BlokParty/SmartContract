using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AacManager : MonoBehaviour {

    [System.Serializable]
    public class AAC
    {
        public string owner;
        public uint uid;
        public uint timestamp;
        public uint exp;
        public string data;
    }

    public AAC[] AacArray;
    
}
