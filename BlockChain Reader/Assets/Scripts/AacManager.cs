using System.Collections;
using System.Collections.Generic;
using System.Numerics;
using UnityEngine;

public class AacManager : MonoBehaviour {

    [System.Serializable]
    public class AAC
    {
        public string owner;
        public BigInteger uid;
        public uint timestamp;
        public uint exp;
        public string data;
    }

    public AAC[] AacArray;
    
}
