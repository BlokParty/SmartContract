using System.Collections;
using System.Collections.Generic;
using System.Numerics;
using UnityEngine;
using UnityEngine.UI;
using PlayTable;
using System;

public class PlayTableScript : MonoBehaviour {
    [SerializeField]
    ContractService service;
    [SerializeField]
    InputField input;

    private void Awake()
    {
        PTTableTop.Initialize(Application.identifier, (new GameObject()).AddComponent<PTPlayer>(), 1, 1);
        PTTableTop.OnSmartPiece += GetBalancesFromRfid;
    }

    private void GetBalancesFromRfid(PTSmartPiece sp)
    {
        string addressBuffer = "0x00000000000000000000000000";
        string uid = sp.id.Substring(0, 14);
        string spAddress = addressBuffer + uid;
        StartCoroutine(service.GetBalance(spAddress));
    }

    public void GetBalancesFromInput()
    {
        BigInteger uid = BigInteger.Parse(input.text);
        StartCoroutine(service.GetBalance(uid));
    }
}
