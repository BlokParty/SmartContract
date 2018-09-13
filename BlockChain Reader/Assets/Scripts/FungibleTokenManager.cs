using System.Collections;
using System.Collections.Generic;
using System.Numerics;
using UnityEngine;
using UnityEngine.UI;

public class FungibleTokenManager : MonoBehaviour {

    public FungibleToken[] fungibleTokens;
    Dictionary<string, int> addressToTokenIndex;

    public FungibleToken[] coloredTokens;
    public FungibleToken[] depositedExternalTokens;
    [SerializeField]
    GameObject tokenSlot;

    [SerializeField]
    GameObject accountFungibleTokenScrollbar;
    [SerializeField]
    GameObject depositedFungibleTokenScrollbar;
    [SerializeField]
    GameObject coloredTokenScrollbar;

    [SerializeField]
    ContractService contract;
    [SerializeField]
    AccountManager account;

    private void Awake()
    {
        addressToTokenIndex = new Dictionary<string, int>();
        for(int i = 0; i < fungibleTokens.Length; ++i)
        {
            addressToTokenIndex.Add(fungibleTokens[i].address, i);
        }
    }

    //-----------------------------------------------------------------------------------------------------------------
    // COLORED TOKENS
    //-----------------------------------------------------------------------------------------------------------------
    public void InitializeColoredBalances(uint colorTypes)
    {
        coloredTokens = new FungibleToken[colorTypes];
        for (int i = 0; i < colorTypes; ++i)
        {
            GameObject newColor;
            if(i > 4)
            {
                newColor = Instantiate(tokenSlot, transform.position, transform.rotation) as GameObject;
                newColor.transform.SetParent(coloredTokenScrollbar.transform);
                newColor.transform.localScale = Vector3.one;
            }
            else
            {
                newColor = coloredTokenScrollbar.transform.Find(" (" + i + ")").gameObject;
            }
            coloredTokens[i] = newColor.GetComponent<FungibleToken>();
        }
    }

    public void SetColorBalance(uint colorIndex, BigInteger balance)
    {
        coloredTokens[colorIndex].SetAndStringifyBalance(balance);
    }

    public void SetColorName(uint colorIndex, string name)
    {
        coloredTokens[colorIndex].tokenName = name;
    }

    public void SetColoredTokenBalance(int colorIndex, BigInteger tokens)
    {
        coloredTokens[colorIndex].SetAndStringifyBalance(tokens);
    }


    //-----------------------------------------------------------------------------------------------------------------
    // FUNGIBLE TOKENS
    //-----------------------------------------------------------------------------------------------------------------
    public void SetFungibleTokenBalances(long uid)
    {
        GameObject.Find("ScanButton").GetComponent<Image>().color = Color.green;
        for (int i = 0; i < fungibleTokens.Length; ++i)
        {
            StartCoroutine(contract.GetExternalToken(uid, fungibleTokens[i].address));
        }
    }

    public void SetExternalTokenBalance(string address, BigInteger tokens)
    {
        depositedExternalTokens[addressToTokenIndex[address]].SetAndStringifyBalance(tokens);
        GameObject.Find("ScanButton").GetComponent<Image>().color = Color.white;
    }

    public void SetAccountTokenBalance(string address, BigInteger tokens)
    {
        fungibleTokens[addressToTokenIndex[address]].SetAndStringifyBalance(tokens);
    }

    //-----------------------------------------------------------------------------------------------------------------
    // RESET
    //-----------------------------------------------------------------------------------------------------------------
    public void ResetBalances()
    {
        for (int i = 0; i < fungibleTokens.Length; ++i)
        {
            depositedExternalTokens[i].SetAndStringifyBalance(0);
        }
        for (int i = 0; i < coloredTokens.Length; ++i)
        {
            coloredTokens[i].SetAndStringifyBalance(0);
        }
    }
}