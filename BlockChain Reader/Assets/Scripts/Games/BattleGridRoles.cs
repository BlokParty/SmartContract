using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BattleGridRoles : MonoBehaviour {
    [System.Serializable]
    public class Role
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

    public class DeletableObject
    {
        public int id;
        public string type;
        public string rfid;
        public string component;
        public string property_type;
        public string property_function;
        public string property_cardName;
        public string property_playerAffected;
        public string property_caster;
    }

    public Role[] roles;
}
