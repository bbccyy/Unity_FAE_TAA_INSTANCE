using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using UnityEngine.UI;
using UnityEditor;
using System.IO;

public class ArtResourceEdit : EditorWindow
{
    [MenuItem("Tools/资源/模型法线写入切线", false)]
    public static void WriteAverageNormalToTangent()
    {
        string[] allPath = AssetDatabase.FindAssets("t:mesh", new string[] { "Assets/ArtResources/character/bulma_2/" });
        for (int index = 0; index < allPath.Length; ++index)
        {
            string path = AssetDatabase.GUIDToAssetPath(allPath[index]);
            Mesh mesh = (Mesh)AssetDatabase.LoadAssetAtPath(path,typeof(Mesh));

            //
            if(mesh == null)
                continue;
            var averageNormalHash = new Dictionary<Vector3, Vector3>();
            for (var j = 0; j < mesh.vertexCount; j++)
            {
                if (!averageNormalHash.ContainsKey(mesh.vertices[j]))
                {
                    averageNormalHash.Add(mesh.vertices[j], mesh.normals[j]);
                }
                else
                {
                    averageNormalHash[mesh.vertices[j]] =
                        (averageNormalHash[mesh.vertices[j]] + mesh.normals[j]).normalized;
                }
            }

            var averageNormals = new Vector3[mesh.vertexCount];
            for (var j = 0; j < mesh.vertexCount; j++)
            {
                averageNormals[j] = averageNormalHash[mesh.vertices[j]];
            }

            var tangents = new Vector4[mesh.vertexCount];
            for (var j = 0; j < mesh.vertexCount; j++)
            {
                tangents[j] = new Vector4(averageNormals[j].x, averageNormals[j].y, averageNormals[j].z, 0);
            }
            mesh.tangents = tangents;

            //AssetDatabase.SaveAssets();
            // bool temp;
            // PrefabUtility.SaveAsPrefabAsset(prefabGameobject, path, out temp);
            // MonoBehaviour.DestroyImmediate(prefabGameobject);
        }

        AssetDatabase.SaveAssets();
        EditorUtility.DisplayDialog("成功", "所有资源修改完成", "确定");

        EditorUtility.ClearProgressBar();
    }
}
