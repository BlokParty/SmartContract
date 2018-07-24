using System.Collections;
using System.Collections.Generic;
using System.Numerics;
using UnityEngine;

public class AccountManager : MonoBehaviour {

    BigInteger ethBalance;
    BigInteger playBalance;
    BigInteger lockedBalance;
    BigInteger[] coloredBalance;

    public BigInteger ETH { get { return ethBalance; } set { ethBalance = value; } }
    public BigInteger PLAY { get { return ethBalance; } set { ethBalance = value; } }
    public BigInteger Locked { get { return ethBalance; } set { ethBalance = value; } }
    public BigInteger GetColor(uint colorIndex){ return coloredBalance[colorIndex]; }
    public void SetColor(BigInteger value){ ethBalance = value; }


    // Use this for initialization
    void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		
	}
}
