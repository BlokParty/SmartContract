using BestHTTP;
using System.Collections;
using System.Collections.Generic;
using Newtonsoft.Json;
using UnityEngine;

public class MetadataHtmlReader {

    [System.Serializable]
    public class Metadata
    {
        public string Uid { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public string Image { get; set; }
    }

    public Metadata DeserializeMetadata(string result)
    {
        return JsonConvert.DeserializeObject<Metadata>(result);
    }
}