using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class Inventory : MonoBehaviour {

    uint numberOfOwnedAacs;
    AacContractReader.GetAacDto[] ownedAacs;
    public AacContractReader.GetAacDto GetOwnedAac(uint index) { return ownedAacs[index]; }
    public void SetOwnedAac(uint index, AacContractReader.GetAacDto value) { ownedAacs[index] = value; }
    [SerializeField]
    Image[] images;
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
                images[i].sprite = EmptyAacSprite;
                images[i].enabled = true;
            }
            else if(i == 0)
            {
                images[i].sprite = Charizard;
                images[i].enabled = true;
            }
            else
            {
                images[i].sprite = defaultSprite;
                images[i].enabled = true;
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
        viewingAac.sprite = images[index].sprite;
    }

    public void InitializeOwnedAacs(uint length)
    {
        numberOfOwnedAacs = length;
        ownedAacs = new AacContractReader.GetAacDto[length];
        images = new Image[length];
        for(int i = 0; i < length; ++i)
        {
            if (i > 17)
            {
                GameObject newButton = Instantiate(inventoryButton, transform.position, transform.rotation) as GameObject;
                newButton.name = " (" + i +")";
                newButton.transform.parent = transform;
                newButton.GetComponent<Button>().onClick.AddListener(delegate { DisplayAac(i); });
            }
            images[i] = transform.Find(" (" + i + ")").transform.Find("Image").GetComponent<Image>();
            transform.Find(" (" + i + ")").GetComponent<Button>().enabled = true;
        }
    }

    public string GenerateAgeString(uint timestamp)
    {
        System.TimeSpan span = System.DateTime.Now.Subtract(new System.DateTime(1970, 1, 1, 0, 0, 0));
        uint age = (uint)span.TotalSeconds - timestamp;
        age /= 60;
        if(age < 180)
        {
            return age + " minutes";
        }
        age /= 60;
        if(age < 72)
        {
            return age + " hours";
        }
        age /= 24;

        return age + " days";
    }
}
