using System.Collections;
using System.Collections.Generic;
using System.Numerics;
using UnityEngine;
using UnityEngine.UI;

public class AccountManager : MonoBehaviour {
    [SerializeField]
    string account = "0x48AeAD82bDeab9b51390d2b6Ce1841B5DDb64201";
    public string Account { get { return account; } set { account = value; } }
    
    uint numberOfOwnedAacs;
    
    public uint NumberOfOwnedAacs { get { return numberOfOwnedAacs; } set { numberOfOwnedAacs = value; } }
    
    [SerializeField]
    Text address;

    private void Start()
    {
        SetAccount(account);
    }

    public void SetAccount(string _account)
    {
        account = _account;
        address.text = "Player ID: " + account;
    }


    // converts BigInteger to string with commas and up to 3 decimal places
    public string ConvertBigIntToString(BigInteger amount, int decimals)
    {
        if(amount == 0) { return "0.000"; }
        string balanceString = "";
        string balanceDividedByDecimals = "" + amount / BigInteger.Pow(10, decimals);
        int balanceLength = balanceDividedByDecimals.Length;
        int balanceLengthMod = balanceLength % 3;
        if (balanceLengthMod == 0) { balanceLengthMod = 3; }
        for (int i = 0; i < balanceLengthMod; ++i)
        {
            balanceString += balanceDividedByDecimals[i];
        }
        if (balanceLength > 3)
        {
            balanceString += ",";
            for (int i = 0; i < 3; ++i)
            {
                balanceString += balanceDividedByDecimals[i + balanceLengthMod];
            }
        }
        if (balanceLength > 6)
        {
            balanceString += ",";
            for (int i = 0; i < 3; ++i)
            {
                balanceString += balanceDividedByDecimals[i + balanceLengthMod + 3];
            }
        }
        if (balanceLength > 9)
        {
            balanceString += ",";
            for (int i = 0; i < 3; ++i)
            {
                balanceString += balanceDividedByDecimals[i + balanceLengthMod + 3];
            }
        }
        if(decimals > 0)
        {
            balanceString += ".";
            if ((amount / BigInteger.Pow(10, decimals - 3)) % 1000 < 100)
            {
                balanceString += "0";
            }
            if ((amount / BigInteger.Pow(10, decimals - 3)) % 1000 < 10)
            {
                balanceString += "0";
            }
            balanceString += ((amount / BigInteger.Pow(10, decimals - 3)) % 1000);
        }
        return balanceString;
    }
}
