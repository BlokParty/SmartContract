using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using BestHTTP;

public class Inventory : MonoBehaviour {

    public List<long> ownedToyUids;

    [System.Serializable]
    public class Slot
    {
        Image image;
        public Image MyImage { get { return image; } set { image = value; } }
        string age;
        public Text Age { get; set; }
        string type;
        public Text Type { get; set; }
        string name;
        public Text Name { get; set; }
        string exp;
        public Text Exp { get; set; }
        string value;
        public Text Value { get; set; }
        string favorite;
        public Text Favorite { get; set; }
    }

    public long uidToDisplay = 0;

    [SerializeField]
    Slot[] slots;

    [SerializeField]
    ToyTokenManager toyManager;
    [SerializeField]
    FungibleTokenManager tokenManager;
    [SerializeField]
    ContractService contract;
    [SerializeField]
    GameRoles gameRoles;

    [SerializeField]
    Image viewingToy;

    [SerializeField]
    Text toyUid;
    [SerializeField]
    Text toyAge;
    [SerializeField]
    Text toyExp;
    [SerializeField]
    Text toyDescription;
    [SerializeField]
    GameObject inventoryButton;

    [SerializeField]
    public Sprite UnregisteredToySprite;
    [SerializeField]
    public Sprite UnlinkedToySprite;

    public void OnFinishedLoading()
    {
        for(int i = 0; i < ownedToyUids.Count; ++i)
        {
            int globalIndex = toyManager.toyUidToIndex[ownedToyUids[i]];
            if (ownedToyUids[i] > 0xFFFFFFFFFFFFFF)
            {
                // Unlinked TOY Token
                slots[i].MyImage.sprite = UnlinkedToySprite;
                slots[i].MyImage.enabled = true;
                slots[i].Age.text = "N/A";
                slots[i].Type.text = "Empty";
                slots[i].Name.text = "N/A";
                slots[i].Exp.text = "0";
                slots[i].Value.text = "0";
                slots[i].Favorite.text = "";
            }
            else
            {
                if (toyManager.toyTokens[globalIndex].Image != null) { slots[i].MyImage.sprite = toyManager.toyTokens[globalIndex].Image; }
                slots[i].MyImage.enabled = true;
                slots[i].Age.text = GenerateAgeString(toyManager.toyTokens[globalIndex].Timestamp);
                slots[i].Type.text = ownedToyUids[i].ToString("X14").Substring(0,2);
                slots[i].Name.text = toyManager.toyTokens[globalIndex].Name;
                slots[i].Exp.text = toyManager.toyTokens[globalIndex].Exp.ToString();
                slots[i].Value.text = "$" + (toyManager.toyTokens[globalIndex].ethValue + toyManager.toyTokens[globalIndex].playValue);
                slots[i].Favorite.text = "";
            }
        }
        if(ownedToyUids.Count > 0)
        {
            viewingToy.enabled = true;
            if(uidToDisplay != 0)
            {
                for (int i = 0; i < ownedToyUids.Count; ++i)
                {
                    if (uidToDisplay == ownedToyUids[i])
                    {
                        DisplayToy(i);
                        uidToDisplay = 0;
                    }
                }
            }
            else
            {
                DisplayToy(0);
            }
        }
    }

    public void DisplayUnregistered(string uid)
    {
        toyUid.text = "UID:  " + uid;
        toyAge.text = "Age:  N/A";
        toyExp.text = "Exp:  0";
        toyDescription.text = "Unregistered toy. Link this to a TOY Token to track it digitally";
        viewingToy.sprite = UnregisteredToySprite;
        tokenManager.ResetBalances();
    }

    public void DisplayToy(int index)
    {
        int globalIndex = toyManager.toyUidToIndex[ownedToyUids[index]];
        if(ownedToyUids == null || index > ownedToyUids.Count)
        {
            return;
        }
        else if(ownedToyUids[index] < 0xFFFFFFFFFFFFFF)
        {
            toyUid.text = "UID:  " + ownedToyUids[index].ToString("X14");
            toyAge.text = "Age:  " + slots[index].Age.text;
            toyExp.text = "Exp:  " + slots[index].Exp.text;
            toyDescription.text = toyManager.toyTokens[globalIndex].Description;
        }
        else
        {
            toyUid.text = "UID:  ???";
            toyAge.text = "Age:  N/A";
            toyExp.text = "Exp:  0";
            toyDescription.text = "Unlinked TOY Token. Link this with a scannable toy to track the toy digitally";
        }
        viewingToy.sprite = slots[index].MyImage.sprite;
        tokenManager.SetFungibleTokenBalances(ownedToyUids[index]);
        contract.GetToyColoredBalance(ownedToyUids[index]);
        if(gameRoles.gameObject.activeInHierarchy == true)
        {
            StartCoroutine(gameRoles.ExposeCurrentRole());
        }
    }

    public void InitializeOwnedToys(int length)
    {
        if (slots != null)
        {
            if(slots.Length > length)
            {
                for (int i = length; i < slots.Length; ++i)
                {
                    if (i > 8)
                    {
                        GameObject.Destroy(transform.Find(" (" + i + ")").gameObject);
                    }
                    else
                    {
                        ClearSlot(i);
                    }
                }
            }
        }
        slots = new Slot[length];
        for(int i = 0; i < length; ++i)
        {
            slots[i] = new Slot();
            if (i > 8) { MakeNewButton(i); }
            slots[i].MyImage = transform.Find(" (" + i + ")").transform.Find("Image").GetComponent<Image>();
            slots[i].Age = transform.Find(" (" + i + ")").transform.Find("Age").transform.Find("Text").GetComponent<Text>();
            slots[i].Type = transform.Find(" (" + i + ")").transform.Find("Type").transform.Find("Text").GetComponent<Text>();
            slots[i].Name = transform.Find(" (" + i + ")").transform.Find("Name").transform.Find("Text").GetComponent<Text>();
            slots[i].Exp = transform.Find(" (" + i + ")").transform.Find("Exp").transform.Find("Text").GetComponent<Text>();
            slots[i].Value = transform.Find(" (" + i + ")").transform.Find("Value").transform.Find("Text").GetComponent<Text>();
            slots[i].Favorite = transform.Find(" (" + i + ")").transform.Find("Favorite").transform.Find("Text").GetComponent<Text>();
            transform.Find(" (" + i + ")").GetComponent<Button>().enabled = true;
        }
    }

    private string GenerateAgeString(long timestamp)
    {
        System.TimeSpan span = System.DateTime.UtcNow.Subtract(new System.DateTime(1970, 1, 1, 0, 0, 0));
        long age = (long)span.TotalSeconds - timestamp;
        age /= 60;
        if(age < 180){ return age + " Minutes"; }
        age /= 60;
        if(age < 72){ return age + " Hours"; }
        age /= 24;
        return age + " Days";
    }

    private void MakeNewButton(int i)
    {
        GameObject newButton = Instantiate(inventoryButton, transform.position, transform.rotation) as GameObject;
        newButton.name = " (" + i + ")";
        newButton.transform.SetParent(transform);
        newButton.transform.localScale = Vector3.one;
        newButton.GetComponent<Button>().onClick.AddListener(delegate { DisplayToy(i); });
    }

    private void ClearSlot(int i)
    {
        slots[i].MyImage.enabled = false;
        slots[i].Age.text = "";
        slots[i].Type.text = "";
        slots[i].Name.text = "";
        slots[i].Exp.text = "";
        slots[i].Value.text = "";
        slots[i].Favorite.text = "";
        transform.Find(" (" + i + ")").GetComponent<Button>().enabled = false;
    }
}
