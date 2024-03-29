﻿using System.Collections;
using System.Collections.Generic;
using System.Numerics;
using System.Linq;
using System.Runtime.InteropServices;
using Nethereum.ABI.FunctionEncoding;
using Nethereum.ABI.Model;
using Nethereum.Contracts;
using Nethereum.Hex.HexTypes;
using Nethereum.JsonRpc.Client;
using Nethereum.JsonRpc.UnityClient;
using Nethereum.Util;
using UnityEngine;
using UnityEngine.Networking;
using UnityEngine.UI;
using BestHTTP;

public class ContractService : MonoBehaviour {

    [SerializeField]
    ToyTokenManager toyManager;
    [SerializeField]
    AccountManager account;
    [SerializeField]
    Inventory inventory;
    [SerializeField]
    FungibleTokenManager tokenManager;
    [SerializeField]
    bool LoadToysOnStartup;
    int toysLoaded;
    int totalSupply;

    private ToyContractReader _toyContractReader;
    private PlayContractReader _playContractReader;
    private MetadataHtmlReader _metadataReader;
    private Erc20Reader[] _erc20Readers;

    private string _url = @"https://mainnet.infura.io/v3/697bb76db0504ef29768e3a8df898713";
    private string _server = @"http://52.9.230.48:8100/toy_token";

    // Use this for initialization
    void Start () {
        _toyContractReader = new ToyContractReader();
        _playContractReader = new PlayContractReader();
        _metadataReader = new MetadataHtmlReader();
        _erc20Readers = new Erc20Reader[tokenManager.fungibleTokens.Length];
        for(int i = 1; i < _erc20Readers.Length; ++i)
        {
            _erc20Readers[i] = new Erc20Reader(tokenManager.fungibleTokens[i].address);
        }

        //Coroutines
        if (LoadToysOnStartup)
        {
            StartCoroutine(GetToys());
        }
        StartCoroutine(InitializeColoredTokens());
        StartCoroutine(GetBalance(account.Account));
    }

    //-----------------------------------------------------------------------------------------------------------------
    // GET OWNED TOYS
    //-----------------------------------------------------------------------------------------------------------------
    public IEnumerator GetOwnedToys(string address)
    {
        GameObject.Find("ScanButton").GetComponent<Image>().color = Color.green;
        // get list of owned Toy Token UIDs
        var toyContractRequest = new EthCallUnityRequest(_url);
        var tokensOfOwnerCallInput = _toyContractReader.CreateTokensOfOwnerCallInput(address);
        yield return toyContractRequest.SendRequest(tokensOfOwnerCallInput, Nethereum.RPC.Eth.DTOs.BlockParameter.CreateLatest()); 
        List<long> uids = _toyContractReader.DecodeTokensOfOwner(toyContractRequest.Result);
        inventory.ownedToyUids = uids;
        inventory.InitializeOwnedToys(uids.Count);

        // notify inventory to finish initialization
        inventory.OnFinishedLoading();
    }

    //-----------------------------------------------------------------------------------------------------------------
    // GET TOYS
    //-----------------------------------------------------------------------------------------------------------------
    IEnumerator GetToys()
    {
        // create a unity call request
        var toyContractRequest = new EthCallUnityRequest(_url);

        // create a call input for AAC count
        var toyTotalSupplyCallInput = _toyContractReader.CreateTotalSupplyCallInput();

        // call request send and yield for response
        yield return toyContractRequest.SendRequest(toyTotalSupplyCallInput, Nethereum.RPC.Eth.DTOs.BlockParameter.CreateLatest());

        // decode the result
        totalSupply = (int)_toyContractReader.DecodeTotalSupply(toyContractRequest.Result);

        // initialize the toy data structure
        toyManager.InitializeToyTokensArray(totalSupply);

        for (int i = 1; i <= totalSupply; ++i)
        {
            StartCoroutine(GetOneToy(i));
        }
    }

    //-----------------------------------------------------------------------------------------------------------------
    // GET ONE TOY
    //-----------------------------------------------------------------------------------------------------------------
    IEnumerator GetOneToy(int index)
    {
        // get uid from index
        var toyContractRequest = new EthCallUnityRequest(_url);
        var toyTokenByIndexCallInput = _toyContractReader.CreateTokenByIndexCallInput(index);
        yield return toyContractRequest.SendRequest(toyTokenByIndexCallInput, Nethereum.RPC.Eth.DTOs.BlockParameter.CreateLatest());
        long uid = (long)_toyContractReader.DecodeTokenByIndex(toyContractRequest.Result);

        // set Toy Token data
        toyContractRequest = new EthCallUnityRequest(_url);
        var getToyCallInput = _toyContractReader.CreateGetToyCallInput(uid);
        yield return toyContractRequest.SendRequest(getToyCallInput, Nethereum.RPC.Eth.DTOs.BlockParameter.CreateLatest());
        ToyContractReader.GetToyDto toyData = _toyContractReader.DecodeGetToyDto(toyContractRequest.Result);
        toyManager.toyTokens[index].Owner = toyData.Owner;
        toyManager.toyTokens[index].Uid = (long)toyData.UID;
        toyManager.toyTokens[index].Timestamp = toyData.Timestamp;
        toyManager.toyTokens[index].Exp = (int)toyData.Experience;

        // set value
        StartCoroutine(GetValue(toyData.UID, index));

        // default image is Unregistered
        toyManager.toyTokens[index].Name = "N/A";
        toyManager.toyTokens[index].Description = "";
        toyManager.toyTokens[index].Image = inventory.UnregisteredToySprite;

        toyManager.toyUidToIndex.Add(uid, index);

        toysLoaded++;
        GameObject.Find("LoadingPercentage").GetComponent<Text>().text = "Loading... " + toysLoaded + " / " + totalSupply;
        if(toysLoaded == totalSupply)
        {
            yield return ParseAllMetadata();
            StartCoroutine(GetOwnedToys(account.Account));
            GameObject.Find("Loading").SetActive(false);
        }
    }

    //-----------------------------------------------------------------------------------------------------------------
    // PARSE ALL METADATA
    //-----------------------------------------------------------------------------------------------------------------
    IEnumerator ParseAllMetadata()
    {
        List<MetadataHtmlReader.Metadata> metadataBlob;
        
        HTTPRequest metadataRequest = new HTTPRequest(new System.Uri(_server));
        metadataRequest.SetHeader("Content-Type", "application/json; charset=UTF-8");
        metadataRequest.Send();
        
        yield return StartCoroutine(metadataRequest);

        metadataBlob = _metadataReader.DeserializeMetadataBlob(metadataRequest.Response.DataAsText);
        for (int i = 0; i < metadataBlob.Count; ++i)
        {
            long id = 0xFFFFFFFFFFFFFF;
            long.TryParse(metadataBlob[i].Uid, System.Globalization.NumberStyles.HexNumber, null, out id);
            
            if (!toyManager.toyUidToIndex.ContainsKey(id))
            {
                Debug.LogError(id + " is present in the server, but not present on the blockchain");
            }
            else
            {
                int index = toyManager.toyUidToIndex[id];
                if (id < 0xFFFFFFFFFFFFFF)
                {
                    toyManager.toyTokens[index].Name = metadataBlob[i].Name;
                    toyManager.toyTokens[index].Description = metadataBlob[i].Description;

                    if (toyManager.urlToSprite.ContainsKey(metadataBlob[i].Image))
                    {
                        toyManager.toyTokens[index].Image = toyManager.urlToSprite[metadataBlob[i].Image];
                    }
                    else
                    {
                        metadataRequest = new HTTPRequest(new System.Uri(metadataBlob[i].Image));
                        metadataRequest.Send();
                        yield return StartCoroutine(metadataRequest);

                        if (toyManager.urlToSprite.ContainsKey(metadataBlob[i].Image))
                        {
                            toyManager.toyTokens[index].Image = toyManager.urlToSprite[metadataBlob[i].Image];
                        }
                        else if (metadataRequest.Response != null)
                        {
                            if (metadataRequest.Response.DataAsTexture2D != null)
                            {
                                Sprite metadataSprite = GenerateSpriteFromTexture2D(metadataRequest.Response.DataAsTexture2D);
                                toyManager.toyTokens[index].Image = metadataSprite;
                                toyManager.urlToSprite.Add(metadataBlob[i].Image, metadataSprite);
                            }
                            else
                            {
                                toyManager.toyTokens[index].Image = inventory.UnlinkedToySprite;
                            }
                        }
                    }
                }
                else
                {
                    toyManager.toyTokens[index].Image = inventory.UnlinkedToySprite;
                }
            }
            
        }
        /*
        // set metadata for Toy Tokens that have been linked (unlinked TOYs don't have metadata)
        if (uid < 0xFFFFFFFFFFFFFF)
        {
            HTTPRequest metadataRequest = new HTTPRequest(new System.Uri(_server + uid.ToString("X14")));
            metadataRequest.Send();
            yield return StartCoroutine(metadataRequest);

            // set metadata
            if (metadataRequest.Response.DataAsText != null)
            {
                MetadataHtmlReader.Metadata metadata = _metadataReader.DeserializeMetadata(metadataRequest.Response.DataAsText);
                toyManager.toyTokens[index].Name = metadata.Name;
                toyManager.toyTokens[index].Description = metadata.Description;

                if (toyManager.urlToSprite.ContainsKey(metadata.Image))
                {
                    toyManager.toyTokens[index].Image = toyManager.urlToSprite[metadata.Image];
                }
                else
                {
                    metadataRequest = new HTTPRequest(new System.Uri(metadata.Image));
                    metadataRequest.Send();
                    yield return StartCoroutine(metadataRequest);

                    if (toyManager.urlToSprite.ContainsKey(metadata.Image))
                    {
                        toyManager.toyTokens[index].Image = toyManager.urlToSprite[metadata.Image];
                    } 
                    else if (metadataRequest.Response != null)
                    {
                        if (metadataRequest.Response.DataAsTexture2D != null)
                        {
                            Sprite metadataSprite = GenerateSpriteFromTexture2D(metadataRequest.Response.DataAsTexture2D);
                            toyManager.toyTokens[index].Image = metadataSprite;
                            toyManager.urlToSprite.Add(metadata.Image, metadataSprite);
                        }
                        else
                        {
                            toyManager.toyTokens[index].Image = inventory.UnlinkedToySprite;
                        }
                    }
                }
            }
            else
            {
                toyManager.toyTokens[index].Name = "N/A";
                toyManager.toyTokens[index].Description = "";
                toyManager.toyTokens[index].Image = inventory.UnlinkedToySprite;
            }
        }
        */
    }


    //-----------------------------------------------------------------------------------------------------------------
    // GET BALANCE
    //-----------------------------------------------------------------------------------------------------------------
    public IEnumerator GetBalance(string address)
    {
        // get ETH balance
        var contractRequest = new EthGetBalanceUnityRequest(_url);
        yield return contractRequest.SendRequest(address, Nethereum.RPC.Eth.DTOs.BlockParameter.CreateLatest());
        tokenManager.SetAccountTokenBalance(tokenManager.fungibleTokens[0].address, contractRequest.Result.Value);

        // get ERC20 balances (start from 1 because 0 is ETH)
        for(int i = 1; i < _erc20Readers.Length; ++i)
        {
            StartCoroutine(GetErc20Balance(i, address));
        }
    }

    //-----------------------------------------------------------------------------------------------------------------
    // GET VALUE
    //-----------------------------------------------------------------------------------------------------------------
    public IEnumerator GetValue(BigInteger uid, int index)
    {
        // get ETH balance
        var toyContractRequest = new EthCallUnityRequest(_url);
        var getExternalTokenCallInput = _toyContractReader.CreateGetExternalTokenBalanceCallInput(uid, "0x54cc27B4405FC9fAB144179f40A0422C7d2d3Cde");
        yield return toyContractRequest.SendRequest(getExternalTokenCallInput, Nethereum.RPC.Eth.DTOs.BlockParameter.CreateLatest());
        var weiBalance = _toyContractReader.DecodeGetExternalTokenBalance(toyContractRequest.Result);

        toyManager.toyTokens[index].ethValue = ((float)weiBalance / 5000000000)/1000000;

        // get PLAY balance
        toyContractRequest = new EthCallUnityRequest(_url);
        getExternalTokenCallInput = _toyContractReader.CreateGetExternalTokenBalanceCallInput(uid, "0x55079fd6049513a5073eC1f873cB839d9ABD2a7c");
        yield return toyContractRequest.SendRequest(getExternalTokenCallInput, Nethereum.RPC.Eth.DTOs.BlockParameter.CreateLatest());
        var pweiBalance = _toyContractReader.DecodeGetExternalTokenBalance(toyContractRequest.Result);
        toyManager.toyTokens[index].playValue = ((float)pweiBalance / 6666666666666)/1000000;
    }

    //-----------------------------------------------------------------------------------------------------------------
    // GET ERC-20 BALANCE
    //-----------------------------------------------------------------------------------------------------------------
    IEnumerator GetErc20Balance(int index, string tokenOwner)
    {
        var erc20ContractRequest = new EthCallUnityRequest(_url);
        var balanceOfCallInput = _erc20Readers[index].CreateBalanceOfCallInput(tokenOwner);
        yield return erc20ContractRequest.SendRequest(balanceOfCallInput, Nethereum.RPC.Eth.DTOs.BlockParameter.CreateLatest());
        var balance = _erc20Readers[index].DecodeBalanceOf(erc20ContractRequest.Result);
        tokenManager.SetAccountTokenBalance(tokenManager.fungibleTokens[index].address, balance);
    }

    //-----------------------------------------------------------------------------------------------------------------
    // GET EXTERNAL TOKEN BALANCE
    //-----------------------------------------------------------------------------------------------------------------
    public IEnumerator GetExternalToken(BigInteger uid, string address)
    {
        var toyContractRequest = new EthCallUnityRequest(_url);
        var getExternalTokenCallInput = _toyContractReader.CreateGetExternalTokenBalanceCallInput(uid, address);
        yield return toyContractRequest.SendRequest(getExternalTokenCallInput, Nethereum.RPC.Eth.DTOs.BlockParameter.CreateLatest());
        var balance = _toyContractReader.DecodeGetExternalTokenBalance(toyContractRequest.Result);
        tokenManager.SetExternalTokenBalance(address, balance);
    }

    //-----------------------------------------------------------------------------------------------------------------
    // INITIALIZE COLORED TOKENS
    //-----------------------------------------------------------------------------------------------------------------
    public IEnumerator InitializeColoredTokens()
    {
        // count colored token types and initialize colored balances in account
        var playContractRequest = new EthCallUnityRequest(_url);
        var playColoredTokensCountCallInput = _playContractReader.CreateColoredTokenCountCallInput();
        yield return playContractRequest.SendRequest(playColoredTokensCountCallInput, Nethereum.RPC.Eth.DTOs.BlockParameter.CreateLatest());
        uint coloredTypes = _playContractReader.DecodeColoredTokenCount(playContractRequest.Result);
        tokenManager.InitializeColoredBalances(coloredTypes);

        // get colored token names
        for (uint i = 0; i < tokenManager.coloredTokens.Length; ++i)
        {
            StartCoroutine(GetColoredTokenName(i));
        }
    }

    //-----------------------------------------------------------------------------------------------------------------
    // GET COLORED TOKEN BALANCE
    //-----------------------------------------------------------------------------------------------------------------
    IEnumerator GetColoredTokenName(uint i)
    {
        var playContractRequest = new EthCallUnityRequest(_url);
        var getColoredTokenNamesCallInput = _playContractReader.CreateGetColoredTokenCallInput(i);
        yield return playContractRequest.SendRequest(getColoredTokenNamesCallInput, Nethereum.RPC.Eth.DTOs.BlockParameter.CreateLatest());
        var coloredToken = _playContractReader.DecodeGetColoredToken(playContractRequest.Result);
        tokenManager.SetColorName(i, coloredToken.Name);
    }

    //-----------------------------------------------------------------------------------------------------------------
    // GET TOY COLORED BALANCES
    //-----------------------------------------------------------------------------------------------------------------
    public void GetToyColoredBalance(BigInteger uid)
    {
        // get colored token balances
        for (uint i = 0; i < tokenManager.coloredTokens.Length; ++i)
        {
            StartCoroutine(GetOneColoredBalance(i, uid));
        }
    }

    private Sprite GenerateSpriteFromTexture2D(Texture2D value)
    {
        return Sprite.Create(value, new Rect(0, 0, value.width, value.height), new Vector2(0.5f, 0.5f));
    }

    //-----------------------------------------------------------------------------------------------------------------
    // GET ONE COLORED BALANCE
    //-----------------------------------------------------------------------------------------------------------------
    IEnumerator GetOneColoredBalance(uint i, BigInteger uid)
    {
        var playContractRequest = new EthCallUnityRequest(_url);
        var playGetColoredTokensCallInput = _playContractReader.CreateGetColoredTokenBalanceCallInput(uid, i);
        yield return playContractRequest.SendRequest(playGetColoredTokensCallInput, Nethereum.RPC.Eth.DTOs.BlockParameter.CreateLatest());
        tokenManager.SetColorBalance(i, _playContractReader.DecodeGetColoredTokenBalance(playContractRequest.Result));
    }
}
