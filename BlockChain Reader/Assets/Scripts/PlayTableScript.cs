﻿using System.Collections;
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
        PTTableTop.Initialize((new GameObject()).AddComponent<PTPlayer>());
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
        // true if input is an address
        if (uid > 0xFFFFFFFFFFFFFF)
        {
            StartCoroutine(service.GetBalance(input.text));
        }
        else
        {
            StartCoroutine(service.GetBalance(uid));
        }
    }
}