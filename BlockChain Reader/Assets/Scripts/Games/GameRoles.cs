using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using BestHTTP;
using LitJson;

public class GameRoles : MonoBehaviour {

    [System.Serializable]
    public class SmartPieceGame
    {
        public string gameName;
        public List<string> roles;
    }

    public GameObject inventory;
    public GameObject assign;

    public BattleGridRoles bgRoles;
    public SmartPieceGame[] games;
    public GameObject[] roleButtons;
    public GameObject roleButton;
    public Text selectedUID;
    
    Color selected;
    string uidToAssign;

    string bgServer = "http://52.9.230.48:8100/smart_piece";

    private void Awake()
    {
        ColorUtility.TryParseHtmlString("#F7C4C4FF", out selected);
    }

    public void DisplayGame(int index)
    {
        for(int i = 0; i < roleButtons.Length; ++i)
        {
            GameObject.Destroy(roleButtons[i]);
        }
        roleButtons = new GameObject[games[index].roles.Count];

        for (int i = 0; i < roleButtons.Length; ++i)
        {
            roleButtons[i] = Instantiate(roleButton, transform.position, transform.rotation) as GameObject;
            roleButtons[i].transform.SetParent(GameObject.Find("Roles").transform);
            roleButtons[i].transform.localScale = Vector3.one;
            SetPickButton(roleButtons[i].GetComponent<Button>(), i);
            SetSendButton(roleButtons[i].transform.Find("SendButton").GetComponent<Button>(), i);
            
            roleButtons[i].transform.Find("Text").GetComponent<Text>().text = games[index].roles[i];
        }

        string normalRfid = selectedUID.text.Substring(6, 8);
        string stupidRfid = normalRfid.Substring(0, 2);
        stupidRfid += " ";
        stupidRfid += normalRfid.Substring(2, 2);
        stupidRfid += " ";
        stupidRfid += normalRfid.Substring(4, 2);
        stupidRfid += " ";
        stupidRfid += normalRfid.Substring(6, 2);
        uidToAssign = stupidRfid;

        StartCoroutine(ExposeCurrentRole());
    }

    IEnumerator ExposeCurrentRole()
    {
        HTTPRequest request = new HTTPRequest(new System.Uri(bgServer + "?rfid=" + uidToAssign));
        request.SetHeader("Content-Type", "application/json; charset=UTF-8");
        request.Send();
        yield return StartCoroutine(request);
        if (request.Response.DataAsText != "[]")
        {
            string jsonToParse = (request.Response.DataAsText);
            jsonToParse = jsonToParse.Substring(1);
            jsonToParse = jsonToParse.Substring(0, jsonToParse.Length - 1);

            var characterData = JsonUtility.FromJson<BattleGridRoles.DeletableObject>(jsonToParse);
            for(int i = 0; i < roleButtons.Length; ++i)
            {
                if (characterData.property_cardName == bgRoles.roles[i].property_cardName)
                {
                    roleButtons[i].GetComponent<Image>().color = selected;
                }
            }
        }
    }

    void SetPickButton(Button button, int i)
    {
        button.onClick.AddListener(delegate { PickRole(i); });
    }

    void SetSendButton(Button button, int i)
    {
        button.onClick.AddListener(delegate { SendRoleWrapper(i); });
    }

    public void PickRole(int i)
    {
        bgRoles.roles[i].rfid = uidToAssign;
    }

    public void SendRoleWrapper(int i)
    {
        StartCoroutine(SendRole(i));
    }

    IEnumerator SendRole(int i)
    {
        // query for exists
        HTTPRequest request = new HTTPRequest(new System.Uri(bgServer + "?rfid=" + uidToAssign));
        request.SetHeader("Content-Type", "application/json; charset=UTF-8");
        request.Send();
        yield return StartCoroutine(request);
        
        // if exists, delete
        if (request.Response.DataAsText != "[]")
        {
            string jsonToParse = (request.Response.DataAsText);
            jsonToParse = jsonToParse.Substring(1);
            jsonToParse = jsonToParse.Substring(0, jsonToParse.Length - 1);
            var characterData = JsonUtility.FromJson<BattleGridRoles.DeletableObject>(jsonToParse);
            for(int j = 0; j < roleButtons.Length; ++j)
            {
                if(characterData.property_cardName == bgRoles.roles[j].property_cardName)
                {
                    if(j > 0)
                    {
                        roleButtons[j].GetComponent<Image>().color = roleButtons[j - 1].GetComponent<Image>().color;
                    }
                    else
                    {
                        roleButtons[j].GetComponent<Image>().color = roleButtons[j + 1].GetComponent<Image>().color;
                    }
                }
            }
            request = new HTTPRequest(new System.Uri(bgServer + @"/id/" + characterData.id), HTTPMethods.Delete);
            request.SetHeader("Content-Type", "application/json; charset=UTF-8");
            request.Send();
        }

        // set new role
        JsonWriter writer = new JsonWriter();
        JsonMapper.ToJson(bgRoles.roles[i], writer);
        string payload = writer.ToString();
        request = new HTTPRequest(new System.Uri(bgServer), HTTPMethods.Post, OnRequestFinished);
        request.SetHeader("Content-Type", "application/json; charset=UTF-8");
        var encoder = new System.Text.UTF8Encoding();
        request.RawData = encoder.GetBytes(payload);
        request.Send();
        yield return StartCoroutine(request);
        StartCoroutine(ExposeCurrentRole());
    }

    void OnRequestFinished(HTTPRequest request, HTTPResponse response)
    {
        Debug.Log("Request Finished! Text received: " + response.DataAsText);
    }


    public void ToggleAssign()
    {
        inventory.SetActive(!inventory.activeInHierarchy);
        assign.SetActive(!assign.activeInHierarchy);
    }
}
