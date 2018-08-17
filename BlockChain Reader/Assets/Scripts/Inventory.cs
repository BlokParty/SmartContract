using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class Inventory : MonoBehaviour {

    public uint numberOfOwnedAacs;
    AacContractReader.GetAacDto[] ownedAacs;
    public AacContractReader.GetAacDto GetOwnedAac(uint index) { return ownedAacs[index]; }
    public void SetOwnedAac(uint index, AacContractReader.GetAacDto value) { ownedAacs[index] = value; }

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
    [SerializeField]
    Slot[] slots;
    string url = "https://www.blok.party/aacs/";

    int viewingIndex;
    [SerializeField]
    Image viewingAac;

    [SerializeField]
    Text aacUid;
    [SerializeField]
    Text aacAge;
    [SerializeField]
    Text aacExp;
    [SerializeField]
    GameObject inventoryButton;

    [SerializeField]
    Sprite defaultSprite;
    [SerializeField]
    Sprite EmptyAacSprite;
    [SerializeField]
    Sprite Charizard;

    public void OnFinishedLoading()
    {
        for(int i = 0; i < ownedAacs.Length; ++i)
        {
            string metadataUrl = url + ownedAacs[i].UID + ".png";
            // get image from JSON
            // texture2d aacImg = callAacApi(metadataUrl);
            // images[i].sprite = makeTextureIntoSprite(aacImg);

            if(ownedAacs[i].UID > 0xFFFFFFFFFFFFFF)
            {
                // empty AAC
                slots[i].MyImage.sprite = EmptyAacSprite;
                slots[i].MyImage.enabled = true;
                slots[i].Age.text = "N/A";
                slots[i].Type.text = "Empty";
                slots[i].Name.text = "N/A";
                slots[i].Exp.text = "0";
                slots[i].Value.text = "0";
                slots[i].Favorite.text = "";
            }
            else if(i == 0)
            {
                slots[i].MyImage.sprite = Charizard;
                slots[i].MyImage.enabled = true;
                slots[i].Age.text = GenerateAgeString(ownedAacs[i].Timestamp);
                slots[i].Type.text = ownedAacs[i].UID.ToString("X14").Substring(0, 2);
                slots[i].Name.text = "";
                slots[i].Exp.text = ownedAacs[i].Experience.ToString();
                slots[i].Favorite.text = "";
            }
            else
            {
                slots[i].MyImage.sprite = defaultSprite;
                slots[i].MyImage.enabled = true;
                slots[i].Age.text = GenerateAgeString(ownedAacs[i].Timestamp);
                slots[i].Type.text = ownedAacs[i].UID.ToString("X14").Substring(0,2);
                slots[i].Name.text = "";
                slots[i].Exp.text = ownedAacs[i].Experience.ToString();
                slots[i].Favorite.text = "";
            }
        }
        if(ownedAacs.Length > 0)
        {
            viewingAac.enabled = true;
            DisplayAac(0);
        }
    }

    public void DisplayAac(int index)
    {
        if(ownedAacs == null || index > ownedAacs.Length)
        {
            return;
        }
        else if(ownedAacs[index].UID < 0xFFFFFFFFFFFFFF)
        {
            aacUid.text = "UID:  " + (ownedAacs[index].UID.ToString("X14"));
            aacAge.text = "Age:  " + GenerateAgeString(ownedAacs[index].Timestamp);
            aacExp.text = "Exp:  " + ownedAacs[index].Experience;
        }
        else
        {
            aacUid.text = "UID:  ???";
            aacAge.text = "Age:  N/A";
            aacExp.text = "Exp:  0";
        }
        viewingIndex = index;
        viewingAac.sprite = slots[index].MyImage.sprite;
        print(index);
    }

    public void InitializeOwnedAacs(uint length)
    {
        numberOfOwnedAacs = length;
        ownedAacs = new AacContractReader.GetAacDto[length];
        slots = new Slot[length];
        for(int i = 0; i < length; ++i)
        {
            slots[i] = new Slot();
            if (i > 17) { MakeNewButton(i); }
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

    public void SortByAge()
    {
        System.Array.Sort(ownedAacs, delegate (AacContractReader.GetAacDto a, AacContractReader.GetAacDto b)
        {
            return a.Timestamp.CompareTo(b.Timestamp);
        });
        OnFinishedLoading();
        print("is this thing on?");
    }

    public void SortByType()
    {
        System.Array.Sort(ownedAacs, delegate (AacContractReader.GetAacDto a, AacContractReader.GetAacDto b)
        {
            return a.UID.CompareTo(b.UID);
        });
        OnFinishedLoading();
        print("yes");
    }

    public void SortByXP()
    {
        System.Array.Sort(ownedAacs, delegate (AacContractReader.GetAacDto a, AacContractReader.GetAacDto b)
        {
            return a.Experience.CompareTo(b.Experience);
        });
        OnFinishedLoading();
    }

    private string GenerateAgeString(uint timestamp)
    {
        System.TimeSpan span = System.DateTime.Now.Subtract(new System.DateTime(1970, 1, 1, 0, 0, 0));
        uint age = (uint)span.TotalSeconds - timestamp;
        age /= 60;
        if(age < 180){ return age + " minutes"; }
        age /= 60;
        if(age < 72){ return age + " hours"; }
        age /= 24;
        return age + " days";
    }

    private void MakeNewButton(int i)
    {
        GameObject newButton = Instantiate(inventoryButton, transform.position, transform.rotation) as GameObject;
        newButton.name = " (" + i + ")";
        newButton.transform.SetParent(transform);
        newButton.transform.localScale = Vector3.one;
        newButton.GetComponent<Button>().onClick.AddListener(delegate { DisplayAac(i); });
    }
}
