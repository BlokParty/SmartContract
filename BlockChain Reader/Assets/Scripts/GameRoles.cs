using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class GameRoles : MonoBehaviour {

    [System.Serializable]
    public class Role
    {
        public string name;
        public string data;
    }

    [System.Serializable]
    public class BattleGridRole : Role
    {
        public string type;
        public string rfid;
        public string component;
        public string property_type;
        public string property_function;
        public string property_cardName;
        public string property_playerAffected;
        public string property_caster;
    }

    [System.Serializable]
    public class ToyBoxStadiumRole : Role
    {
        public int defenseBase;
        public int attackBase;
        public int hpBase;
        public int speedBase;

        public int defenseExp;
        public int attackExp;
        public int hpExp;
        public int speedExp;
    }

    public class CatanRole : Role
    {
        bool isRobber;
    }

    [System.Serializable]
    public class SmartPieceGame<T>
    {
        public string gameName;
        public List<T> roles;
    }

    public SmartPieceGame<BattleGridRole> BattleGrid = new SmartPieceGame<BattleGridRole>();
    public SmartPieceGame<ToyBoxStadiumRole> ToyBoxStadium = new SmartPieceGame<ToyBoxStadiumRole>();

    public ArrayList games = new ArrayList();
    public GameObject[] roleButtons;
    public GameObject roleButton;

    public void Start()
    {

    }

    public void DisplayGame(int index)
    {

    }

    void MakeNewButton(int i)
    {

        GameObject newButton = Instantiate(roleButton, transform.position, transform.rotation) as GameObject;
        newButton.name = " (" + i + ")";
        newButton.transform.SetParent(transform);
        newButton.transform.localScale = Vector3.one;
        newButton.GetComponent<Button>().onClick.AddListener(delegate
        {
            PickRole(i);
        });
    }

    void PickRole(int i)
    {
        
    }
}
