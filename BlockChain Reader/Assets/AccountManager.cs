using System.Collections;
using System.Collections.Generic;
using System.Numerics;
using UnityEngine;
using UnityEngine.UI;

public class AccountManager : MonoBehaviour {

    string account = "0x48AeAD82bDeab9b51390d2b6Ce1841B5DDb64201";
    public string Account { get { return account; } set { account = value; } }

    BigInteger ethBalance;
    BigInteger playBalance;
    BigInteger lockedBalance;
    BigInteger[] coloredBalances;
    string[] coloredTokenNames;
    uint numberOfOwnedAacs;

    public BigInteger ETH { get { return ethBalance; } set { ethBalance = value; } }
    public BigInteger PLAY { get { return playBalance; } set { playBalance = value; } }
    public BigInteger Locked { get { return lockedBalance; } set { lockedBalance = value; } }
    public BigInteger GetColor(uint colorIndex) { return coloredBalances[colorIndex]; }
    public void SetColor(uint colorIndex, BigInteger value) { coloredBalances[colorIndex] = value; }
    public string GetColorName(uint colorIndex) { return coloredTokenNames[colorIndex]; }
    public void SetColorName(uint colorIndex, string value) { coloredTokenNames[colorIndex] = value; }
    public uint NumberOfOwnedAacs { get { return numberOfOwnedAacs; } set { numberOfOwnedAacs = value; } }

    string ethBalanceString;
    string playBalanceString;
    string lockedBalanceString;
    string[] coloredBalanceStrings;

    [SerializeField]
    Text address;
    [SerializeField]
    Text eth;
    [SerializeField]
    Text pnt;
    [SerializeField]
    Text locked;
    [SerializeField]
    Text[] colored;
    [SerializeField]
    Text aacs;

    AacContractReader.GetAacDto[] ownedAacs;
    public AacContractReader.GetAacDto GetOwnedAac(uint index) { return ownedAacs[index]; }
    public void SetOwnedAac(uint index, AacContractReader.GetAacDto value) { ownedAacs[index] = value; }

    [SerializeField]
    Text aacNumber;
    [SerializeField]
    Text aacUid;
    [SerializeField]
    Text aacTimestamp;
    [SerializeField]
    Text aacExp;

    public void OnFinishedLoadingBalances()
    {
        StringifyBalances();
        address.text = "Signed in as:  " + account;
        eth.text = "Ether:  " + ethBalanceString;
        pnt.text = "PLAYnetwork Token (PNT):  " + playBalanceString;
        locked.text = "Locked PNT:  " + lockedBalanceString;
        for (uint i = 0; i < coloredBalances.Length; ++i)
        {
            colored[i].text = "Colored PNT(" + i + ") - " + coloredTokenNames[i] + ":  " + coloredBalanceStrings[i];
        }
    }

    public void OnFinishedLoadingAACs()
    {
        aacs.text = "Owned AACs:  " + numberOfOwnedAacs;
        aacNumber.text = "1 / " + numberOfOwnedAacs;
        aacUid.text = "UID:  " + (ownedAacs[0].UID.ToString("X14"));
        aacTimestamp.text = "Created:  " + ownedAacs[0].Timestamp;
        aacExp.text = "Exp:  " + ownedAacs[0].Experience;
    }

    // Initializes the coloredBalances array.
    public void InitializeColoredBalances(uint length)
    {
        coloredBalances = new BigInteger[length];
        coloredTokenNames = new string[length];
    }

    public void InitializeOwnedAacs(uint length)
    {
        numberOfOwnedAacs = length;
        ownedAacs = new AacContractReader.GetAacDto[length];
    }

    // converts the BigInteger balances to strings to display
    private void StringifyBalances()
    {
        ethBalanceString = ConvertBigIntToString(ethBalance);
        playBalanceString = ConvertBigIntToString(playBalance);
        lockedBalanceString = ConvertBigIntToString(lockedBalance);
        coloredBalanceStrings = new string[coloredBalances.Length];
        for(uint i = 0; i < coloredBalances.Length; ++i)
        {
            coloredBalanceStrings[i] = ConvertBigIntToString(coloredBalances[i]);
        }
    }

    // converts BigInteger to string with commas and up to 3 decimal places
    private string ConvertBigIntToString(BigInteger amount)
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
