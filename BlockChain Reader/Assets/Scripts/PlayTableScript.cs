using System.Collections;
using System.Collections.Generic;
using System.Numerics;
using UnityEngine;
using UnityEngine.UI;
using PlayTable;
using System;

public class PlayTableScript : MonoBehaviour {
    [SerializeField]
    ContractService contractService;
    [SerializeField]
    ToyTokenManager toyManager;
    [SerializeField]
    AccountManager accountManager;
    [SerializeField]
    Inventory inventory;

    private void Awake()
    {
        PTTableTop.Initialize((new GameObject()).AddComponent<PTPlayer>());
        PTTableTop.OnSmartPiece += DisplayToyData;
    }

    private void Update()
    {

        if (Input.GetKeyDown(KeyCode.T))
        {
            long id = long.Parse("0436957A963380", System.Globalization.NumberStyles.HexNumber);

            int index = toyManager.toyUidToIndex[id];
            string owner = toyManager.toyTokens[index].Owner;
            if (owner == accountManager.Account)
            {
                for (int i = 0; i < inventory.ownedToyUids.Count; ++i)
                {
                    if (id == inventory.ownedToyUids[i])
                    {
                        inventory.DisplayToy(i);
                    }
                }
            }
            else
            {
                accountManager.Account = owner;
                inventory.uidToDisplay = id;
                StartCoroutine(contractService.GetOwnedToys(owner));
                StartCoroutine(contractService.GetBalance(owner));
            }
        }

        if (Input.GetKeyDown(KeyCode.C))
        {
            long id = long.Parse("0436957A963380", System.Globalization.NumberStyles.HexNumber);

            int index = toyManager.toyUidToIndex[id];
            string owner = toyManager.toyTokens[index].Owner;
            if (owner == accountManager.Account)
            {
                for (int i = 0; i < inventory.ownedToyUids.Count; ++i)
                {
                    if (id == inventory.ownedToyUids[i])
                    {
                        inventory.DisplayToy(i);
                    }
                }
            }
            else
            {
                accountManager.SetAccount(owner);
                inventory.uidToDisplay = id;
                StartCoroutine(contractService.GetOwnedToys(owner));
                StartCoroutine(contractService.GetBalance(owner));
            }
        }
    }

    private void DisplayToyData(PTSmartPiece sp)
    {
        if (sp.id != "null")
        {
            Debug.Log("Scanned SmartPiece Id is " + sp.id);
            string trimmedId = sp.id.Substring(0, 14);
            long id = long.Parse(trimmedId, System.Globalization.NumberStyles.HexNumber);
            if (toyManager.toyUidToIndex.ContainsKey(id))
            {

                int index = toyManager.toyUidToIndex[id];
                string owner = toyManager.toyTokens[index].Owner;
                if (owner == accountManager.Account)
                {
                    for (int i = 0; i < inventory.ownedToyUids.Count; ++i)
                    {
                        if (id == inventory.ownedToyUids[i])
                        {
                            inventory.DisplayToy(i);
                        }
                    }
                }
                else
                {
                    accountManager.SetAccount(owner);
                    inventory.uidToDisplay = id;
                    StartCoroutine(contractService.GetOwnedToys(owner));
                    StartCoroutine(contractService.GetBalance(owner));
                }
            }
        }
        else
        {
            Debug.Log("id was null");
        }
    }
    
}
