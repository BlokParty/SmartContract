using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using PlayTable;
using System.Threading.Tasks;

public class SmartPiece
{
    public int x;
    public int y;
    public string id;
    public SmartPiece(int x0, int y0, string id0)
    {
        x = x0;
        y = y0;
        id = id0;
    }
}

public class SmartPieceManager : MonoBehaviour
{
    // TouchMap
    int xOffsetL = 64;
    int xOffsetR = 64;

    int xOverlap = 24;
    int yOverlap = 27;

    int yOffsetT = 106;
    int yOffsetB = 86;

    int xAntSize = 171;
    int yAntSize = 181;

    int numAntBanks = 6;
    int totalNumAntX = 2 * 6; // numAntBanks (C# !)

    int numAntY = 6;
    int numAntXPerBank = 2;

    int canvasHeight = 1080;
    int canvasWidth = 1920;
    AndroidJavaObject pluginObject;
    float pauseBetweenScansMs = .125f;
    int maxNumTouchGos = 20; // machine has limit of 10  (was 4)
    int currentTouchN;
    int cntScans;
    int cntFrames;
    //
    PlayTableScript playTableScript;
    SmartPiece spOrig;
    string[] lastTouchUids;
    bool[] lastYnTouchExists;
    int cntFps;
    //    float lastScanTimestamp;
    int xCoordinateLast;
    int yCoordinateLast;
    float distNear;
    string uidLast;

    private void Awake()
    {
        distNear = xAntSize / 4;
        playTableScript = GameObject.Find("Main Camera").GetComponent<PlayTableScript>();
        Debug.Log(playTableScript + " <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< BlockChainReader SmartPiece v7.02 >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
    }

    void Start()
    {
        lastTouchUids = new string[maxNumTouchGos];
        lastYnTouchExists = new bool[maxNumTouchGos];
        for (int n = 0; n < maxNumTouchGos; n++)
        {
            lastYnTouchExists[n] = false;
            lastTouchUids[n] = "null";
        }
        Input.multiTouchEnabled = true;
        if (Application.isEditor == false)
        {
            //pluginObject = new AndroidJavaObject("com.playprizm.playtablelauncher.IICMethods");
            pluginObject = new AndroidJavaObject("party.blok.smartpiece.IICMethods");
            Debug.Log("BlockChainReder >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> " + pluginObject + " SmartPiece: AndroidJavaObject instantiated.");
        }
        //        HeartbeatScanAuto();
        //        StartCoroutine(HeartbeatScanAuto2());
        HeartbeatScanAutoFast();
        InvokeRepeating("ShowFPS", 1, 1);
    }

    void ShowFPS()
    {
        Debug.Log("BlockChainReader  *****  fps = " + cntFps);
        cntFps = 0;
    }

    private void Update()
    {
        cntFps++;
        cntFrames++;
    }

    void HeartbeatScanAutoFast()
    {
        //Debug.Log("HeartbeatScanAutoFast.........................");
        if (Input.touchCount > 0)
        {
            int xCoordinate = 0;
            int yCoordinate = 0;
            bool ynFound = false;
            foreach (Touch touch in Input.touches)
            {
                if (touch.phase == TouchPhase.Began)
                {
                    ynFound = true;
                    xCoordinate = (int)touch.position.x;
                    yCoordinate = canvasHeight - (int)touch.position.y;
                    break;
                }
            }
            if (ynFound == true)
            {
                Vector2 p1 = new Vector2(xCoordinate, yCoordinate);
                Vector2 p2 = new Vector2(xCoordinateLast, yCoordinateLast);
                float dist = Vector2.Distance(p1, p2);
                if (dist > distNear || uidLast == "null")
                {
                    string uid = IssueScan(xCoordinate, yCoordinate);
                    spOrig = new SmartPiece(xCoordinate, canvasHeight - yCoordinate, uid);
                    playTableScript.DisplayToyData(spOrig);
                    string txt = "(" + cntScans + ") fast |||||||||||||||||| SmartPiece IssueScan for ";
                    txt += xCoordinate + ", " + yCoordinate + " |" + uid + "|";
                    //textLog.text += txt + "\n";
                    Debug.Log("BlockChainReader " + txt);
                    uidLast = uid;
                    xCoordinateLast = xCoordinate;
                    yCoordinateLast = yCoordinate;
                }
            }
        }
        Invoke("HeartbeatScanAutoFast", .01f);
    }

    IEnumerator HeartbeatScanAuto2()
    {
        while (true)
        {
            HeartbeatScan();
            //await Task.Delay(pauseBetweenScansMs);
            // await Task.Delay(TimeSpan.FromSeconds(pauseBetweenScansMs));
            yield return new WaitForSeconds(pauseBetweenScansMs);
        }
    }

    void HeartbeatScanAuto()
    {
        HeartbeatScan();
        Invoke("HeartbeatScanAuto", pauseBetweenScansMs);
    }

    void HeartbeatScan()
    {
        VerifyNextInTouches();
    }

    void VerifyNextInTouches()
    {
        if (Input.touchCount == 0)
        {
            // simulates heartbeat even when no touch, returning nulls
            for (int n = 0; n < maxNumTouchGos; n++)
            {
                lastTouchUids[n] = "null";
                lastYnTouchExists[n] = false;
            }
            return;
        }
        currentTouchN++;
        if (currentTouchN >= Input.touchCount)
        {
            currentTouchN = 0;
        }
        Debug.Log("TouchExists ---- currentTouchN: " + currentTouchN + " TouchCount: " + Input.touchCount + "-----------------------------------------");

        int xCoordinate = (int)Input.touches[currentTouchN].position.x;
        int yCoordinate = canvasHeight - (int)Input.touches[currentTouchN].position.y;

        // silent heartbeat
        string uid = IssueScan(xCoordinate, yCoordinate);

        // two consecutive nulls = touch up, non-null uid = touch down, touchup followed by touchdown calls delegate
        bool ynTouchExists = lastYnTouchExists[currentTouchN];
        if (uid != "null")
        {
            ynTouchExists = true;
        }
        else
        {
            if (lastTouchUids[currentTouchN] == "null" && uid == "null")
            {
                ynTouchExists = false;
            }
            //            if (Time.realtimeSinceStartup - lastScanTimestamp > 1f)
            //            {
            //                lastYnTouchExists[currentTouchN] = false;
            //            }
        }

        string txtCall = "";
        if (lastYnTouchExists[currentTouchN] == false && ynTouchExists == true)
        {
            spOrig = new SmartPiece(xCoordinate, canvasHeight - yCoordinate, uid);
            playTableScript.DisplayToyData(spOrig);
            Debug.Log(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> TouchExists SmartPieceManager calling delegate >>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
            txtCall = " >>>>>>>>>>>>>>>>>>>>>>>";
        }
        Debug.Log("TouchExists ---------------------------------------------");
        Debug.Log("TouchExists uids: " + lastTouchUids[currentTouchN] + ", " + uid);
        Debug.Log("TouchExists touch: " + lastYnTouchExists[currentTouchN] + ", " + ynTouchExists + "    " + txtCall);
        if (currentTouchN >= 0 && currentTouchN < maxNumTouchGos)
        {
            lastYnTouchExists[currentTouchN] = ynTouchExists;
            lastTouchUids[currentTouchN] = uid;
        }
        //        lastScanTimestamp = Time.realtimeSinceStartup;
    }

    string IssueScan(int xCoordinate, int yCoordinate)
    {
        if (Application.isEditor == true) return "null";
        string uid;
        uid = pluginObject.Call<string>("IssueScan", xCoordinate, yCoordinate);
        cntScans++;

        string txt = cntScans + " SmartPiece <<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>|||||||||||||||||| SmartPiece IssueScan for ";
        txt += xCoordinate + ", " + yCoordinate + " |" + uid + "|";
        Debug.Log(txt);
        //
        ShowScanInfo(xCoordinate, yCoordinate, uid);
        //        spOrig = new SmartPiece(xCoordinate, canvasHeight - yCoordinate, uid);
        //Debug.Log(">>>>>>>>>>>>>>>>>>>>>>>>>>> spOrig:" + spOrig);
        //        battleScript.smartTouchStartHandler(spOrig);
        return uid;
    }

    //private void Update()
    //{
    //    //UpdateTouchButton();
    //}

    //void UpdateTouchButton()
    //{
    //    if (Input.touchCount > 0 && Input.touches[0].phase == TouchPhase.Began)
    //    {
    //        Vector3 posTouch = Input.touches[0].position;
    //    }
    //}

    string ShowScanInfo(int xCoordinate, int yCoordinate, string uid)
    {
        string spText = "x = " + xCoordinate + ", y = " + yCoordinate;
        int nBank = GetBankNum(xCoordinate);
        string sBank = GetBankLetter(nBank);
        int nAntenna = GetAntennaIndex(xCoordinate, yCoordinate);
        spText += "|" + sBank + ":" + nAntenna + "|" + uid;
        Debug.Log("SmartPiece SmartPieceList: " + spText + "\n");
        return spText;
    }

    int GetBankNum(int xCoord)
    {
        int selected_bank_num = (xCoord - xOffsetL) / ((xAntSize - xOverlap) * numAntXPerBank);
        if (selected_bank_num > 5) selected_bank_num = 5; // amre
        return selected_bank_num;
    }

    string GetBankLetter(int selected_bank_num)
    {
        int unicode = 65 + selected_bank_num;
        char character = (char)unicode;
        string sBank = character.ToString();
        return sBank;
    }

    int GetAntennaIndex(int xCoord, int yCoord)
    {
        int selected_antenna_index = (yCoord - yOffsetT) / (yAntSize - yOverlap);
        if (selected_antenna_index > 11)
        {
            selected_antenna_index = 11;
        }
        if (IsAntennaIndexOdd(xCoord) == true)
        {
            selected_antenna_index = 11 - selected_antenna_index;
        }
        return selected_antenna_index;
    }

    bool IsAntennaIndexOdd(int xCoord)  // odd is second column
    {
        bool IsOdd = false;
        int evenOrOdd = (xCoord - xOffsetL) / (xAntSize - xOverlap);
        if (evenOrOdd % 2 == 1 || evenOrOdd >= numAntXPerBank * numAntBanks)
        {
            IsOdd = true;
        }
        return IsOdd;
    }

    string GetReaderLabel(int nBank, int nAntenna)
    {
        string txtBank = GetBankLetter(nBank);
        string txtLabel = txtBank + ":" + nAntenna;
        return txtLabel;
    }

    Vector3 GetReaderPos(int nBank, int nAntenna)
    {
        int x = xOffsetL + nBank * (xAntSize - xOverlap) * numAntXPerBank;
        if (nAntenna > 5)
        {
            nAntenna = 11 - nAntenna;
            x += (xAntSize - xOverlap);
        }
        x += xAntSize / 2;
        //
        int y = yOffsetT + nAntenna * (yAntSize - yOverlap);
        y += yAntSize / 2;
        y = canvasHeight - y;
        Vector3 pos = new Vector3(x, y, 0);
        return pos;
    }
}
