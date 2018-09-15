using System.Collections;
using System.Collections.Generic;
using System.Numerics;
using Nethereum.ABI.Encoders;
using Nethereum.ABI.FunctionEncoding.Attributes;
using Nethereum.Contracts;
using Nethereum.Hex.HexConvertors.Extensions;
using Nethereum.Hex.HexTypes;
using Nethereum.JsonRpc.Client;
using Nethereum.JsonRpc.UnityClient;
using Nethereum.RPC.Eth.DTOs;
using Nethereum.RPC.Eth.Transactions;
using Nethereum.Signer;
using UnityEngine;

public class PlayContractReader
{

    public static string ABI = @"[{'constant':false,'inputs':[{'name':'colorIndex','type':'uint256'},{'name':'to','type':'uint256'},{'name':'tokens','type':'uint256'}],'name':'deposit','outputs':[],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':true,'inputs':[],'name':'name','outputs':[{'name':'','type':'string'}],'payable':false,'stateMutability':'pure','type':'function'},{'constant':true,'inputs':[],'name':'requiredLockedForColorRegistration','outputs':[{'name':'','type':'uint256'}],'payable':false,'stateMutability':'view','type':'function'},{'constant':false,'inputs':[{'name':'spender','type':'address'},{'name':'tokens','type':'uint256'}],'name':'approve','outputs':[{'name':'','type':'bool'}],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':true,'inputs':[],'name':'currentYear','outputs':[{'name':'','type':'uint256'}],'payable':false,'stateMutability':'view','type':'function'},{'constant':true,'inputs':[],'name':'maximumLockYears','outputs':[{'name':'','type':'uint256'}],'payable':false,'stateMutability':'view','type':'function'},{'constant':false,'inputs':[{'name':'numberOfYears','type':'uint256'},{'name':'tokens','type':'uint256'}],'name':'lock','outputs':[{'name':'','type':'bool'}],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':true,'inputs':[],'name':'totalSupply','outputs':[{'name':'','type':'uint256'}],'payable':false,'stateMutability':'view','type':'function'},{'constant':false,'inputs':[{'name':'colorIndex','type':'uint256'},{'name':'from','type':'uint256'},{'name':'tokens','type':'uint256'}],'name':'spend','outputs':[{'name':'','type':'bool'}],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':false,'inputs':[{'name':'from','type':'address'},{'name':'to','type':'address'},{'name':'tokens','type':'uint256'}],'name':'transferFrom','outputs':[{'name':'','type':'bool'}],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':true,'inputs':[],'name':'decimals','outputs':[{'name':'','type':'uint8'}],'payable':false,'stateMutability':'pure','type':'function'},{'constant':false,'inputs':[{'name':'tokens','type':'uint256'}],'name':'burn','outputs':[{'name':'','type':'bool'}],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':false,'inputs':[{'name':'from','type':'address'},{'name':'numberOfYears','type':'uint256'},{'name':'tokens','type':'uint256'}],'name':'lockFrom','outputs':[{'name':'','type':'bool'}],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':false,'inputs':[{'name':'colorIndex','type':'uint256'},{'name':'from','type':'uint256'},{'name':'tokens','type':'uint256'}],'name':'spendFrom','outputs':[{'name':'','type':'bool'}],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':false,'inputs':[{'name':'toyAddress','type':'address'}],'name':'setToyTokenContractAddress','outputs':[],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':true,'inputs':[{'name':'tokenOwner','type':'address'}],'name':'balanceOf','outputs':[{'name':'','type':'uint256'}],'payable':false,'stateMutability':'view','type':'function'},{'constant':false,'inputs':[{'name':'from','type':'address'},{'name':'to','type':'address'},{'name':'numberOfYears','type':'uint256'},{'name':'tokens','type':'uint256'}],'name':'transferFromAndLock','outputs':[],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':false,'inputs':[{'name':'from','type':'address'},{'name':'tokens','type':'uint256'}],'name':'burnFrom','outputs':[{'name':'','type':'bool'}],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':false,'inputs':[{'name':'to','type':'address'},{'name':'numberOfYears','type':'uint256'},{'name':'tokens','type':'uint256'}],'name':'transferAndLock','outputs':[],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':false,'inputs':[],'name':'updateYearsSinceRelease','outputs':[],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':true,'inputs':[],'name':'symbol','outputs':[{'name':'','type':'string'}],'payable':false,'stateMutability':'pure','type':'function'},{'constant':true,'inputs':[{'name':'colorIndex','type':'uint256'}],'name':'getColoredToken','outputs':[{'name':'','type':'address'},{'name':'','type':'string'}],'payable':false,'stateMutability':'view','type':'function'},{'constant':false,'inputs':[{'name':'to','type':'address'},{'name':'tokens','type':'uint256'}],'name':'transfer','outputs':[{'name':'','type':'bool'}],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':true,'inputs':[],'name':'coloredTokenCount','outputs':[{'name':'','type':'uint256'}],'payable':false,'stateMutability':'view','type':'function'},{'constant':true,'inputs':[{'name':'uid','type':'uint256'},{'name':'colorIndex','type':'uint256'}],'name':'getColoredTokenBalance','outputs':[{'name':'','type':'uint256'}],'payable':false,'stateMutability':'view','type':'function'},{'constant':false,'inputs':[{'name':'newAmount','type':'uint256'}],'name':'setRequiredLockedForColorRegistration','outputs':[],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':false,'inputs':[{'name':'tokenOwner','type':'address'}],'name':'unlockAll','outputs':[],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':false,'inputs':[{'name':'tokenOwner','type':'address'},{'name':'year','type':'uint256'}],'name':'unlockByYear','outputs':[],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':true,'inputs':[{'name':'tokenOwner','type':'address'},{'name':'year','type':'uint256'}],'name':'getLockedTokensByYear','outputs':[{'name':'','type':'uint256'}],'payable':false,'stateMutability':'view','type':'function'},{'constant':true,'inputs':[{'name':'tokenOwner','type':'address'},{'name':'spender','type':'address'}],'name':'allowance','outputs':[{'name':'','type':'uint256'}],'payable':false,'stateMutability':'view','type':'function'},{'constant':true,'inputs':[{'name':'tokenOwner','type':'address'}],'name':'getTotalLockedTokens','outputs':[{'name':'lockedTokens','type':'uint256'}],'payable':false,'stateMutability':'view','type':'function'},{'constant':false,'inputs':[{'name':'colorName','type':'string'}],'name':'registerNewColor','outputs':[{'name':'','type':'uint256'}],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':false,'inputs':[{'name':'_newOwner','type':'address'}],'name':'transferOwnership','outputs':[],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':false,'inputs':[{'name':'colorIndex','type':'uint256'},{'name':'to','type':'uint256[]'},{'name':'tokens','type':'uint256'}],'name':'depositBulk','outputs':[],'payable':false,'stateMutability':'nonpayable','type':'function'},{'anonymous':false,'inputs':[{'indexed':true,'name':'creator','type':'address'},{'indexed':false,'name':'name','type':'string'}],'name':'NewColor','type':'event'},{'anonymous':false,'inputs':[{'indexed':true,'name':'to','type':'uint256'},{'indexed':true,'name':'colorIndex','type':'uint256'},{'indexed':false,'name':'tokens','type':'uint256'}],'name':'DepositColor','type':'event'},{'anonymous':false,'inputs':[{'indexed':true,'name':'from','type':'uint256'},{'indexed':true,'name':'color','type':'uint256'},{'indexed':false,'name':'amount','type':'uint256'}],'name':'SpendColor','type':'event'},{'anonymous':false,'inputs':[{'indexed':false,'name':'previousOwner','type':'address'},{'indexed':false,'name':'newOwner','type':'address'}],'name':'OwnershipTransfer','type':'event'},{'anonymous':false,'inputs':[{'indexed':true,'name':'tokenOwner','type':'address'},{'indexed':false,'name':'tokens','type':'uint256'}],'name':'Lock','type':'event'},{'anonymous':false,'inputs':[{'indexed':true,'name':'tokenOwner','type':'address'},{'indexed':false,'name':'tokens','type':'uint256'}],'name':'Unlock','type':'event'},{'anonymous':false,'inputs':[{'indexed':true,'name':'from','type':'address'},{'indexed':true,'name':'to','type':'address'},{'indexed':false,'name':'tokens','type':'uint256'}],'name':'Transfer','type':'event'},{'anonymous':false,'inputs':[{'indexed':true,'name':'tokenOwner','type':'address'},{'indexed':true,'name':'spender','type':'address'},{'indexed':false,'name':'tokens','type':'uint256'}],'name':'Approval','type':'event'}]";
    private static string contractAddress = "0x55079fd6049513a5073eC1f873cB839d9ABD2a7c";
    private Contract contract;

    public PlayContractReader()
    {
        this.contract = new Contract(null, ABI, contractAddress);
    }

    //---------------------------------------------------------------------------------------------
    // GET FUNCTION
    //---------------------------------------------------------------------------------------------
    public Function GetFunctionBalanceOf()
    {
        return contract.GetFunction("balanceOf");
    }

    public Function GetFunctionGetTotalLockedTokens()
    {
        return contract.GetFunction("getTotalLockedTokens");
    }

    public Function GetFunctionColoredTokenCount()
    {
        return contract.GetFunction("coloredTokenCount");
    }

    public Function GetFunctionGetColoredToken()
    {
        return contract.GetFunction("getColoredToken");
    }

    public Function GetFunctionGetColoredTokenBalance()
    {
        return contract.GetFunction("getColoredTokenBalance");
    }

    //---------------------------------------------------------------------------------------------
    // CREATE CALL INPUT
    //---------------------------------------------------------------------------------------------
    public CallInput CreateBalanceOfCallInput(string address)
    {
        var function = GetFunctionBalanceOf();
        return function.CreateCallInput(address);
    }

    public CallInput CreateGetTotalLockedTokensCallInput(string address)
    {
        var function = GetFunctionGetTotalLockedTokens();
        return function.CreateCallInput(address);
    }

    public CallInput CreateGetColoredTokenBalanceCallInput(BigInteger uid, uint colorIndex)
    {
        var function = GetFunctionGetColoredTokenBalance();
        return function.CreateCallInput(uid, colorIndex);
    }

    public CallInput CreateColoredTokenCountCallInput()
    {
        var function = GetFunctionColoredTokenCount();
        return function.CreateCallInput();
    }

    public CallInput CreateGetColoredTokenCallInput(uint colorIndex)
    {
        var function = GetFunctionGetColoredToken();
        return function.CreateCallInput(colorIndex);
    }
    
    //---------------------------------------------------------------------------------------------
    // DECODE RESULT
    //---------------------------------------------------------------------------------------------
    public BigInteger DecodeBalanceOf(string result)
    {
        var function = GetFunctionBalanceOf();
        return function.DecodeSimpleTypeOutput<BigInteger>(result);
    }

    public BigInteger DecodeGetTotalLockedTokens(string result)
    {
        var function = GetFunctionGetTotalLockedTokens();
        return function.DecodeSimpleTypeOutput<BigInteger>(result);
    }

    public BigInteger DecodeGetColoredTokenBalance(string result)
    {
        var function = GetFunctionGetColoredTokenBalance();
        return function.DecodeSimpleTypeOutput<BigInteger>(result);
    }

    public uint DecodeColoredTokenCount(string result)
    {
        var function = GetFunctionColoredTokenCount();
        return function.DecodeSimpleTypeOutput<uint>(result);
    }

    public GetColoredTokenDto DecodeGetColoredToken(string result)
    {
        var function = GetFunctionGetColoredToken();
        return function.DecodeDTOTypeOutput<GetColoredTokenDto>(result);
    }

    //---------------------------------------------------------------------------------------------
    // DATA TYPE OBJECT
    //---------------------------------------------------------------------------------------------
    [FunctionOutput]
    public class GetColoredTokenDto
    {
        [Parameter("address", "creator", 1)]
        public string Creator { get; set; }
        [Parameter("string", "name", 2)]
        public string Name { get; set; }
    }
}
