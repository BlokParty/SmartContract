using System.Collections;
using System.Collections.Generic;
using System.Numerics;
using UnityEngine;

public class ToyTokenManager : MonoBehaviour {

    [System.Serializable]
    public class ToyToken
    {
        public long Timestamp;
        public long Uid;
        public string Owner;
        public int Exp;
        public string Name;
        public string Description;
        public Sprite Image;
        public float ethValue;
        public float playValue;
    }

    [SerializeField]
    public ToyToken[] toyTokens;
    [SerializeField]
    public Dictionary<long, int> toyUidToIndex;

    private void Awake()
    {
        toyUidToIndex = new Dictionary<long, int>();
    }

    public void InitializeToyTokensArray(int totalSupply)
    {
        toyTokens = new ToyToken[totalSupply + 1];
        for (int i = 0; i < toyTokens.Length; ++i)
        {
            toyTokens[i] = new ToyToken();
        }
    }

    /*
    public void SortByAge()
    {
        System.Array.Sort(ownedAacs, delegate (AacContractReader.GetAacDto a, AacContractReader.GetAacDto b)
        {
            return a.Timestamp.CompareTo(b.Timestamp);
        });
        OnFinishedLoading();
    }

    public void SortByType()
    {
        System.Array.Sort(ownedAacs, delegate (AacContractReader.GetAacDto a, AacContractReader.GetAacDto b)
        {
            return a.UID.CompareTo(b.UID);
        });
        OnFinishedLoading();
    }

    public void SortByXP()
    {
        System.Array.Sort(ownedAacs, delegate (AacContractReader.GetAacDto a, AacContractReader.GetAacDto b)
        {
            return a.Experience.CompareTo(b.Experience);
        });
        OnFinishedLoading();
    }
    */
}
