using System.Collections;
using System.Collections.Generic;
using System.Numerics;
using UnityEngine;
using UnityEngine.UI;

public class FungibleToken : MonoBehaviour {
    [SerializeField]
    public string tokenName;
    [SerializeField]
    public string symbol;
    [SerializeField]
    public int decimals;
    [SerializeField]
    public string address;
    public BigInteger balance;
    string balanceString;

    [SerializeField]
    GameObject buttons;
    bool buttonsVisible;

    public void SetAndStringifyBalance(BigInteger _balance)
    {
        balance = _balance;
        balanceString = GameObject.Find("Account Balances").GetComponent<AccountManager>().ConvertBigIntToString(_balance, decimals);
        string tokenString;
        if (symbol == "")
        {
            tokenString = tokenName + ": " + balanceString;
        }
        else
        {
            tokenString = tokenName + " (" + symbol + "): " + balanceString;
        }
        transform.Find("Text").GetComponent<Text>().text = tokenString;
    }

    public void ToggleButton()
    {
        if (buttonsVisible)
        {
            if (symbol == "")
            {
                transform.Find("Text").GetComponent<Text>().text = tokenName + ": " + balanceString;
            }
            else
            {
                transform.Find("Text").GetComponent<Text>().text = tokenName + " (" + symbol + "): " + balanceString;
            }
        }
        else
        {
            transform.Find("Text").GetComponent<Text>().text = symbol + ": " + balanceString;
        }
        buttons.SetActive(!buttonsVisible);
        buttonsVisible = !buttonsVisible;
        transform.Find("Arrow").transform.Rotate(new Vector3(0, 0, 180));
    }
}
