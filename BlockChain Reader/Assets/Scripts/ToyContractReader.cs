﻿using System.Collections;
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

public class ToyContractReader
{

    public static string ABI = @"[{'constant':true,'inputs':[{'name':'interfaceID','type':'bytes4'}],'name':'supportsInterface','outputs':[{'name':'','type':'bool'}],'payable':false,'stateMutability':'view','type':'function'},{'constant':true,'inputs':[],'name':'name','outputs':[{'name':'','type':'string'}],'payable':false,'stateMutability':'pure','type':'function'},{'constant':true,'inputs':[{'name':'_tokenId','type':'uint256'}],'name':'getApproved','outputs':[{'name':'','type':'address'}],'payable':false,'stateMutability':'view','type':'function'},{'constant':false,'inputs':[{'name':'_approved','type':'address'},{'name':'_tokenId','type':'uint256'}],'name':'approve','outputs':[],'payable':true,'stateMutability':'payable','type':'function'},{'constant':false,'inputs':[{'name':'_toyUid','type':'uint256'},{'name':'_externalAddress','type':'address'},{'name':'_externalId','type':'uint256'}],'name':'linkExternalNft','outputs':[],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':false,'inputs':[],'name':'mint','outputs':[],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':true,'inputs':[],'name':'totalSupply','outputs':[{'name':'','type':'uint256'}],'payable':false,'stateMutability':'view','type':'function'},{'constant':false,'inputs':[{'name':'_tokenAddress','type':'address'},{'name':'_toUid','type':'uint256'},{'name':'_tokens','type':'uint256'}],'name':'depositERC20','outputs':[],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':false,'inputs':[{'name':'_from','type':'address'},{'name':'_to','type':'address'},{'name':'_tokenId','type':'uint256'}],'name':'transferFrom','outputs':[],'payable':true,'stateMutability':'payable','type':'function'},{'constant':false,'inputs':[{'name':'_fromUid','type':'uint256'},{'name':'_amount','type':'uint256'}],'name':'withdrawEther','outputs':[],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':false,'inputs':[{'name':'_toUid','type':'uint256'}],'name':'depositEther','outputs':[],'payable':true,'stateMutability':'payable','type':'function'},{'constant':true,'inputs':[{'name':'_owner','type':'address'},{'name':'_index','type':'uint256'}],'name':'tokenOfOwnerByIndex','outputs':[{'name':'','type':'uint256'}],'payable':false,'stateMutability':'view','type':'function'},{'constant':false,'inputs':[{'name':'_tokenAddress','type':'address'},{'name':'_fromUid','type':'uint256'},{'name':'_to','type':'address'},{'name':'_tokens','type':'uint256'}],'name':'transferERC20','outputs':[],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':true,'inputs':[{'name':'_uid','type':'uint256'}],'name':'getLinkedNft','outputs':[{'name':'','type':'address'},{'name':'','type':'uint256'}],'payable':false,'stateMutability':'view','type':'function'},{'constant':false,'inputs':[{'name':'_newUid','type':'uint256[]'},{'name':'_toyId','type':'uint256[]'},{'name':'_data','type':'bytes'}],'name':'linkBulk','outputs':[],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':false,'inputs':[{'name':'_from','type':'address'},{'name':'_to','type':'address'},{'name':'_tokenId','type':'uint256'}],'name':'safeTransferFrom','outputs':[],'payable':true,'stateMutability':'payable','type':'function'},{'constant':true,'inputs':[],'name':'priceToMint','outputs':[{'name':'','type':'uint256'}],'payable':false,'stateMutability':'view','type':'function'},{'constant':true,'inputs':[{'name':'_index','type':'uint256'}],'name':'tokenByIndex','outputs':[{'name':'','type':'uint256'}],'payable':false,'stateMutability':'view','type':'function'},{'constant':false,'inputs':[{'name':'_amount','type':'uint256'}],'name':'mintBulk','outputs':[],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':true,'inputs':[{'name':'_tokenId','type':'uint256'}],'name':'ownerOf','outputs':[{'name':'','type':'address'}],'payable':false,'stateMutability':'view','type':'function'},{'constant':false,'inputs':[{'name':'_tokenAddress','type':'address'},{'name':'_fromUid','type':'uint256'},{'name':'_tokens','type':'uint256'}],'name':'withdrawERC20','outputs':[],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':true,'inputs':[{'name':'_owner','type':'address'}],'name':'balanceOf','outputs':[{'name':'','type':'uint256'}],'payable':false,'stateMutability':'view','type':'function'},{'constant':false,'inputs':[{'name':'_newUrl','type':'string'}],'name':'updateMetadataUrl','outputs':[],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':false,'inputs':[{'name':'_newUid','type':'bytes7'},{'name':'_toyId','type':'uint256'},{'name':'_data','type':'bytes'}],'name':'link','outputs':[],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':true,'inputs':[{'name':'_owner','type':'address'}],'name':'tokensOfOwner','outputs':[{'name':'','type':'uint256[]'}],'payable':false,'stateMutability':'view','type':'function'},{'constant':true,'inputs':[{'name':'_externalAddress','type':'address'},{'name':'_externalId','type':'uint256'}],'name':'externalNftIsLinked','outputs':[{'name':'','type':'bool'}],'payable':false,'stateMutability':'view','type':'function'},{'constant':false,'inputs':[{'name':'_fromUid','type':'uint256'},{'name':'_to','type':'address'},{'name':'_amount','type':'uint256'}],'name':'transferEther','outputs':[],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':true,'inputs':[],'name':'symbol','outputs':[{'name':'','type':'string'}],'payable':false,'stateMutability':'pure','type':'function'},{'constant':false,'inputs':[{'name':'_operator','type':'address'},{'name':'_approved','type':'bool'}],'name':'setApprovalForAll','outputs':[],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':false,'inputs':[{'name':'_tokenAddress','type':'address'},{'name':'_from','type':'address'},{'name':'_toUid','type':'uint256'},{'name':'_tokens','type':'uint256'}],'name':'depositERC20From','outputs':[],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':false,'inputs':[{'name':'_from','type':'address'},{'name':'_to','type':'address'},{'name':'_tokenId','type':'uint256'},{'name':'_data','type':'bytes'}],'name':'safeTransferFrom','outputs':[],'payable':true,'stateMutability':'payable','type':'function'},{'constant':true,'inputs':[{'name':'_uid','type':'uint256'}],'name':'getToy','outputs':[{'name':'','type':'address'},{'name':'','type':'uint256'},{'name':'','type':'uint256'},{'name':'','type':'uint256'},{'name':'','type':'bytes'}],'payable':false,'stateMutability':'view','type':'function'},{'constant':false,'inputs':[{'name':'_to','type':'address'}],'name':'mintAndSend','outputs':[],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':true,'inputs':[{'name':'_tokenId','type':'uint256'}],'name':'tokenURI','outputs':[{'name':'','type':'string'}],'payable':false,'stateMutability':'view','type':'function'},{'constant':false,'inputs':[{'name':'_newPrice','type':'uint256'}],'name':'changeToyPrice','outputs':[],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':false,'inputs':[{'name':'_uid','type':'uint256'},{'name':'_data','type':'bytes'}],'name':'changeToyData','outputs':[{'name':'','type':'address'},{'name':'','type':'uint256'},{'name':'','type':'uint256'},{'name':'','type':'uint256'},{'name':'','type':'bytes'}],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':false,'inputs':[{'name':'_newAddress','type':'address'}],'name':'updatePlayTokenContract','outputs':[],'payable':false,'stateMutability':'nonpayable','type':'function'},{'constant':true,'inputs':[{'name':'_owner','type':'address'},{'name':'_operator','type':'address'}],'name':'isApprovedForAll','outputs':[{'name':'','type':'bool'}],'payable':false,'stateMutability':'view','type':'function'},{'constant':true,'inputs':[{'name':'_uid','type':'uint256'},{'name':'_tokenAddress','type':'address'}],'name':'getExternalTokenBalance','outputs':[{'name':'','type':'uint256'}],'payable':false,'stateMutability':'view','type':'function'},{'constant':false,'inputs':[{'name':'_newOwner','type':'address'}],'name':'transferOwnership','outputs':[],'payable':false,'stateMutability':'nonpayable','type':'function'},{'anonymous':false,'inputs':[{'indexed':false,'name':'_oldUid','type':'uint256'},{'indexed':false,'name':'_newUid','type':'uint256'}],'name':'Link','type':'event'},{'anonymous':false,'inputs':[{'indexed':true,'name':'_from','type':'address'},{'indexed':true,'name':'_to','type':'address'},{'indexed':true,'name':'_tokenId','type':'uint256'}],'name':'Transfer','type':'event'},{'anonymous':false,'inputs':[{'indexed':true,'name':'_owner','type':'address'},{'indexed':true,'name':'_approved','type':'address'},{'indexed':true,'name':'_tokenId','type':'uint256'}],'name':'Approval','type':'event'},{'anonymous':false,'inputs':[{'indexed':true,'name':'_owner','type':'address'},{'indexed':true,'name':'_operator','type':'address'},{'indexed':false,'name':'_approved','type':'bool'}],'name':'ApprovalForAll','type':'event'},{'anonymous':false,'inputs':[{'indexed':false,'name':'previousOwner','type':'address'},{'indexed':false,'name':'newOwner','type':'address'}],'name':'OwnershipTransfer','type':'event'}]";
    private static string contractAddress = "0x54cc27B4405FC9fAB144179f40A0422C7d2d3Cde";
    private Contract contract;

    public ToyContractReader()
    {
        this.contract = new Contract(null, ABI, contractAddress);
    }

    //---------------------------------------------------------------------------------------------
    // GET FUNCTION
    //---------------------------------------------------------------------------------------------
    public Function GetFunctionGetToy()
    {
        return contract.GetFunction("getToy");
    }

    public Function GetFunctionBalanceOf()
    {
        return contract.GetFunction("balanceOf");
    }

    public Function GetFunctionTokensOfOwner()
    {
        return contract.GetFunction("tokensOfOwner");
    }

    public Function GetFunctionTotalSupply()
    {
        return contract.GetFunction("totalSupply");
    }

    public Function GetFunctionTokenByIndex()
    {
        return contract.GetFunction("tokenByIndex");
    }

    public Function GetFunctionOwnerOf()
    {
        return contract.GetFunction("ownerOf");
    }

    public Function GetFunctionGetExternalTokenBalance()
    {
        return contract.GetFunction("getExternalTokenBalance");
    }

    //---------------------------------------------------------------------------------------------
    // CREATE CALL INPUT
    //---------------------------------------------------------------------------------------------
    public CallInput CreateGetToyCallInput(BigInteger index)
    {
        var function = GetFunctionGetToy();
        return function.CreateCallInput(index);
    }

    public CallInput CreateBalanceOfCallInput(string address)
    {
        var function = GetFunctionBalanceOf();
        return function.CreateCallInput(address);
    }

    public CallInput CreateTokensOfOwnerCallInput(string address)
    {
        var function = GetFunctionTokensOfOwner();
        return function.CreateCallInput(address);
    }

    public CallInput CreateTotalSupplyCallInput()
    {
        var function = GetFunctionTotalSupply();
        return function.CreateCallInput();
    }

    public CallInput CreateTokenByIndexCallInput(BigInteger index)
    {
        var function = GetFunctionTokenByIndex();
        return function.CreateCallInput(index);
    }

    public CallInput CreateOwnerOfCallInput(BigInteger index)
    {
        var function = GetFunctionOwnerOf();
        return function.CreateCallInput(index);
    }

    public CallInput CreateGetExternalTokenBalanceCallInput(BigInteger uid, string address)
    {
        var function = GetFunctionGetExternalTokenBalance();
        return function.CreateCallInput(uid, address);
    }

    //---------------------------------------------------------------------------------------------
    // DECODE RESULT
    //---------------------------------------------------------------------------------------------
    public GetToyDto DecodeGetToyDto(string result)
    {
        var function = GetFunctionGetToy();
        return function.DecodeDTOTypeOutput<GetToyDto>(result);
    }

    public uint DecodeBalanceOf(string result)
    {
        var function = GetFunctionBalanceOf();
        return function.DecodeSimpleTypeOutput<uint>(result);
    }

    public List<long> DecodeTokensOfOwner(string result)
    {
        var function = GetFunctionTokensOfOwner();
        return function.DecodeSimpleTypeOutput<List<long>>(result);
    }

    public uint DecodeTotalSupply(string result)
    {
        var function = GetFunctionTotalSupply();
        return function.DecodeSimpleTypeOutput<uint>(result);
    }

    public BigInteger DecodeTokenByIndex(string result)
    {
        var function = GetFunctionTokenByIndex();
        return function.DecodeSimpleTypeOutput<BigInteger>(result);
    }

    public string DecodeOwnerOf(string result)
    {
        var function = GetFunctionOwnerOf();
        return function.DecodeSimpleTypeOutput<string>(result);
    }

    public BigInteger DecodeGetExternalTokenBalance(string result)
    {
        var function = GetFunctionGetExternalTokenBalance();
        return function.DecodeSimpleTypeOutput<BigInteger>(result);
    }

    //---------------------------------------------------------------------------------------------
    // DATA TYPE OBJECT
    //---------------------------------------------------------------------------------------------
    [FunctionOutput]
    public class GetToyDto
    {
        [Parameter("address", "owner", 1)]
        public string Owner { get; set; }
        [Parameter("uint", "uid", 2)]
        public BigInteger UID { get; set; }
        [Parameter("uint", "timeStamp", 3)]
        public uint Timestamp { get; set; }
        [Parameter("uint", "exp", 4)]
        public uint Experience { get; set; }
        [Parameter("bytes", "publicData", 5)]
        public string PublicData { get; set; }
    }

}
