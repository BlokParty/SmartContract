using System.Collections;
using System.Collections.Generic;
using System.Numerics;
using UnityEngine;

public class AccountManager : MonoBehaviour {
    
    BigInteger ethBalance;
    BigInteger playBalance;
    BigInteger lockedBalance;
    BigInteger[] coloredBalances;
    [SerializeField]
    string ethBalanceString;
    [SerializeField]
    string playBalanceString;
    [SerializeField]
    string lockedBalanceString;
    [SerializeField]
    string[] coloredBalanceStrings;

    public BigInteger ETH { get { return ethBalance; } set { ethBalance = value; } }
    public BigInteger PLAY { get { return playBalance; } set { playBalance = value; } }
    public BigInteger Locked { get { return lockedBalance; } set { lockedBalance = value; } }
    public BigInteger GetColor(uint colorIndex){ return coloredBalances[colorIndex]; }
    public void SetColor(uint colorIndex, BigInteger value){ coloredBalances[colorIndex] = value; }

    public void InitializeColoredBalances(uint length)
    {
        coloredBalances = new BigInteger[length];
    }

    public void stringifyBalances()
    {
        ethBalanceString = convertWeiToEthString(ethBalance);
        playBalanceString = convertWeiToEthString(playBalance);
        lockedBalanceString = convertWeiToEthString(lockedBalance);
        coloredBalanceStrings = new string[coloredBalances.Length];
        for(uint i = 0; i < coloredBalances.Length; ++i)
        {
            coloredBalanceStrings[i] = convertWeiToEthString(coloredBalances[i]);
        }
    }

    public string convertWeiToEthString(BigInteger amount)
    {
        string balance = "";
        string balanceInEth = "" + amount / 1000000000000000000;
        int balanceLength = balanceInEth.Length;
        int balanceLengthMod = balanceLength % 3;
        if (balanceLengthMod == 0) { balanceLengthMod = 3; }
        for (int i = 0; i < balanceLengthMod; ++i)
        {
            balance += balanceInEth[i];
        }
        if (balanceLength > 3)
        {
            balance += ",";
            for (int i = 0; i < 3; ++i)
            {
                balance += balanceInEth[i + balanceLengthMod];
            }
        }
        if (balanceLength > 6)
        {
            balance += ",";
            for (int i = 0; i < 3; ++i)
            {
                balance += balanceInEth[i + balanceLengthMod + 3];
            }
        }
        if (balanceLength > 9)
        {
            balance += ",";
            for (int i = 0; i < 3; ++i)
            {
                balance += balanceInEth[i + balanceLengthMod + 3];
            }
        }
        balance += ".";
        if ((amount / 1000000000000000) % 1000 < 100)
        {
            balance += "0";
        }
        if ((amount / 1000000000000000) % 1000 < 10)
        {
            balance += "0";
        }
        balance += ((amount / 1000000000000000) % 1000);
        return balance;
    }
}
