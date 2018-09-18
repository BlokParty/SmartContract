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

        if (Input.GetKeyDown(KeyCode.R))
        {
            inventory.DisplayUnregistered("ABCDEF01234567");
        }
    }

    private void DisplayToyData(PTSmartPiece sp)
    {
        // if ID is null, no smart piece was read
        if (sp.id != "null")
        {
            GetComponent<AudioSource>().Play();
            Debug.Log("Scanned SmartPiece Id is " + sp.id);

            // trim ID to its 7 byte UID
            string trimmedId = sp.id.Substring(0, 14);

            // if ID begins with AF, we know its UID is only 4 bytes. Set the last 3 bytes to 0.
            if (trimmedId[0] == 'A')
            {
                trimmedId = trimmedId.Substring(0, 8);
                trimmedId += "000000";
            }

            // convert UID string to long
            long id = long.Parse(trimmedId, System.Globalization.NumberStyles.HexNumber);

            // check if UID is registered in toyManager
            if (toyManager.toyUidToIndex.ContainsKey(id))
            {
                int index = toyManager.toyUidToIndex[id];
                string owner = toyManager.toyTokens[index].Owner;

                // check if scanned toy's owner is current wallet
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
                // if scanned toy's owner is not current wallet, reload inventory
                else
                {
                    accountManager.SetAccount(owner);
                    inventory.uidToDisplay = id;
                    StartCoroutine(contractService.GetOwnedToys(owner));
                    StartCoroutine(contractService.GetBalance(owner));
                }
            }
            // If UID is not registered in toyManager, display unregistered toy
            else
            {
                inventory.DisplayUnregistered(sp.id.Substring(0,14));
            }
        }
        // no smartpiece read, only a touch
        else
        {
            Debug.Log("id was null");
        }
    }
    
}
