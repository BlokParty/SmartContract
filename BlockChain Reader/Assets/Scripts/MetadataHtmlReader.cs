using BestHTTP;
using System.Collections;
using System.Collections.Generic;
using Newtonsoft.Json;
using UnityEngine;

public class MetadataHtmlReader {
    
    public static class JsonHelper
    {
        public static T[] FromJson<T>(string json)
        {
            Wrapper<T> wrapper = JsonUtility.FromJson<Wrapper<T>>(json);
            return wrapper.Items;
        }

        public static string ToJson<T>(T[] array)
        {
            Wrapper<T> wrapper = new Wrapper<T>();
            wrapper.Items = array;
            return JsonUtility.ToJson(wrapper);
        }

        public static string ToJson<T>(T[] array, bool prettyPrint)
        {
            Wrapper<T> wrapper = new Wrapper<T>();
            wrapper.Items = array;
            return JsonUtility.ToJson(wrapper, prettyPrint);
        }

        [System.Serializable]
        private class Wrapper<T>
        {
            public T[] Items;
        }
    }

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

    public List<Metadata> DeserializeMetadataBlob(string result)
    {
        Debug.LogError(result);
        return JsonConvert.DeserializeObject<List<Metadata>>(result);
    }
}