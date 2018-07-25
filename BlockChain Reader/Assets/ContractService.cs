using System.Collections;
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

public class ContractService : MonoBehaviour {

    [SerializeField]
    AacManager manager;
    [SerializeField]
    AccountManager account;
    [SerializeField]
    bool LoadAacsOnStartup;

    private AacContractReader _aacContractReader;
    private PlayContractReader _playContractReader;

    private string _url = @"https://ropsten.infura.io/697bb76db0504ef29768e3a8df898713";


	// Use this for initialization
	void Start () {
        _aacContractReader = new AacContractReader();
        _playContractReader = new PlayContractReader();
        //Coroutines
        if (LoadAacsOnStartup)
        {
            StartCoroutine(GetAacs());
        }

        StartCoroutine(GetBalance("0x48AeAD82bDeab9b51390d2b6Ce1841B5DDb64201"));
    }
	
	// Update is called once per frame
	void Update () {
		
	}

    IEnumerator GetAacs()
    {
        // create a unity call request
        var aacContractRequest = new EthCallUnityRequest(_url);

        // create a call input for AAC count
        var aacTotalSupplyCallInput = _aacContractReader.CreateTotalSupplyCallInput();

        // call request send and yield for response
        yield return aacContractRequest.SendRequest(aacTotalSupplyCallInput, Nethereum.RPC.Eth.DTOs.BlockParameter.CreateLatest());

        // decode the result
        var count = _aacContractReader.DecodeTotalSupply(aacContractRequest.Result);

        // initialize the aac data structure
        manager.AacArray = new AacManager.AAC[count + 1];

        for (uint i = 1; i <= count; ++i)
        {
            StartCoroutine(GetOneAac(i));
        }
    }

    IEnumerator GetOneAac(uint index)
    {
        // create a unity call request
        var aacContractRequest = new EthCallUnityRequest(_url);

        // create a call input for token by index
        var aacTokenByIndexCallInput = _aacContractReader.CreateTokenByIndexCallInput(index);

        // call request send and yield for response
        yield return aacContractRequest.SendRequest(aacTokenByIndexCallInput, Nethereum.RPC.Eth.DTOs.BlockParameter.CreateLatest());

        // decode the result
        BigInteger uid = _aacContractReader.DecodeTokenByIndex(aacContractRequest.Result);

        // create a new call request
        aacContractRequest = new EthCallUnityRequest(_url);

        // create call input for get AAC
        var aacGetAacCallInput = _aacContractReader.CreateGetAacCallInput(uid);

        // call request send and yield for response
        yield return aacContractRequest.SendRequest(aacGetAacCallInput, Nethereum.RPC.Eth.DTOs.BlockParameter.CreateLatest());

        // decode the result
        var aac = _aacContractReader.DecodeGetAacDto(aacContractRequest.Result);

        // fill the array
        manager.AacArray[index] = new AacManager.AAC
        {
            owner = aac.Owner,
            uid = uid,
            timestamp = aac.Timestamp,
            exp = aac.Experience,
            data = aac.PublicData
        };
    }

    public IEnumerator GetBalance(string address)
    {
        // get ETH balance
        var contractRequest = new EthGetBalanceUnityRequest(_url);
        yield return contractRequest.SendRequest(address, Nethereum.RPC.Eth.DTOs.BlockParameter.CreateLatest());
        account.ETH = contractRequest.Result.Value;

        // get PLAY balance
        var playContractRequest = new EthCallUnityRequest(_url);
        var playBalanceOfCallInput = _playContractReader.CreateBalanceOfCallInput(address);
        yield return playContractRequest.SendRequest(playBalanceOfCallInput, Nethereum.RPC.Eth.DTOs.BlockParameter.CreateLatest());
        account.PLAY = _playContractReader.DecodeBalanceOf(playContractRequest.Result);

        // get Locked balance
        playContractRequest = new EthCallUnityRequest(_url);
        var playGetLockedTokensCallInput = _playContractReader.CreateGetTotalLockedTokensCallInput(address);
        yield return playContractRequest.SendRequest(playGetLockedTokensCallInput, Nethereum.RPC.Eth.DTOs.BlockParameter.CreateLatest());
        account.Locked = _playContractReader.DecodeGetTotalLockedTokens(playContractRequest.Result);

        // Count Colored Token types and initialize colored balances in account
        playContractRequest = new EthCallUnityRequest(_url);
        var playColoredTokensCountCallInput = _playContractReader.CreateColoredTokenCountCallInput();
        yield return playContractRequest.SendRequest(playColoredTokensCountCallInput, Nethereum.RPC.Eth.DTOs.BlockParameter.CreateLatest());
        uint coloredTypes = _playContractReader.DecodeColoredTokenCount(playContractRequest.Result);
        account.InitializeColoredBalances(coloredTypes);

        // get Colored Token balances
        for (uint i = 0; i < coloredTypes; ++i)
        {
            playContractRequest = new EthCallUnityRequest(_url);
            var playGetColoredTokensCallInput = _playContractReader.CreateGetColoredTokenBalanceCallInput(address, i);
            yield return playContractRequest.SendRequest(playGetColoredTokensCallInput, Nethereum.RPC.Eth.DTOs.BlockParameter.CreateLatest());
            account.SetColor(i, _playContractReader.DecodeGetTotalLockedTokens(playContractRequest.Result));
        }

        account.stringifyBalances();
    }

    public IEnumerator GetBalance(BigInteger uid)
    {
        // Count Colored Token types and initialize colored balances in account
        var playContractRequest = new EthCallUnityRequest(_url);
        var playColoredTokensCountCallInput = _playContractReader.CreateColoredTokenCountCallInput();
        yield return playContractRequest.SendRequest(playColoredTokensCountCallInput, Nethereum.RPC.Eth.DTOs.BlockParameter.CreateLatest());
        uint coloredTypes = _playContractReader.DecodeColoredTokenCount(playContractRequest.Result);
        account.InitializeColoredBalances(coloredTypes);

        // get Colored Token balances
        for (uint i = 0; i < coloredTypes; ++i)
        {
            playContractRequest = new EthCallUnityRequest(_url);
            var playGetColoredTokensCallInput = _playContractReader.CreateGetColoredTokenBalanceCallInput(uid, i);
            yield return playContractRequest.SendRequest(playGetColoredTokensCallInput, Nethereum.RPC.Eth.DTOs.BlockParameter.CreateLatest());
            account.SetColor(i, _playContractReader.DecodeGetTotalLockedTokens(playContractRequest.Result));
        }

        account.stringifyBalances();
    }
}
