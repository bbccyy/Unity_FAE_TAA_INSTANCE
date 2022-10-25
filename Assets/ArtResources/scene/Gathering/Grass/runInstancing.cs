using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Text.RegularExpressions;

public class runInstancing : MonoBehaviour
{
    public Material instanceMat;    //支持GPU Instance的材质
    public Mesh instanceMesh;       //待实例化的模型 

    Mesh mergedMesh;        //合并后的实例化模型 
    Matrix4x4[] matrices;   //DrawMeshInstance方法需要的ObjectToWorld矩阵，必须是单位矩阵(不做任何变换) 

    int instanceNum = 0;    //GPU Instance 发射数量
    int totalNum = 0;       //一共有多少株单位

    [SerializeField] public int PerInstanceNum = 16;        //合并到一次Instance内的单位数
                                                            //如果不需要MergeMesh，可以将此数值设置为1  

    List<Transform> m_CollectedGrass = new List<Transform>();

    Matrix4x4[] mPerUnitMatrix_M;   //记录了每一株单位的世界空间转换矩阵 
    Vector4[] mPerUnitVector_M;     //取Matrix_M的前3行，以3个Vector4为一组，存入该数据缓冲 

    MaterialPropertyBlock block;    //逐实例材质数据块
    bool option;                    //当前环境是否支持实例化 
    GraphicsBuffer gb;              //实例化shader需要这个buffer里的数据->会导入mPerUnitVector_M 


    int BuildMatrixAndBlock(int aTotalNum, int aBatchNum, Matrix4x4[] perUnitMatrix_M)
    {
        if (perUnitMatrix_M.Length != aTotalNum)
        {
            Debug.LogWarning("Mis-match array length: length of perUnitMatrix_M doesn't match aTotalNum");
            return 0;
        }

        instanceMat.SetInt(Shader.PropertyToID("_TotalNum"), aTotalNum);
        instanceMat.SetInt(Shader.PropertyToID("_BatchNum"), aBatchNum);

        //在shader端我会定义 -> Buffer<half4> _InputConstData <- 以减少GPU内存使用量 
        //这样做的前提是允许损失位置精度 -> 对于大型地图不建议，但是在龙珠项目中可以先尝试一下 
        gb = new GraphicsBuffer(GraphicsBuffer.Target.Structured, aTotalNum * 3, sizeof(float) * 4); 
        mPerUnitVector_M = new Vector4[aTotalNum * 3]; 
        for (int i = 0; i < aTotalNum; i++) 
        {
            mPerUnitVector_M[i * 3] = perUnitMatrix_M[i].GetRow(0);
            mPerUnitVector_M[i * 3 + 1] = perUnitMatrix_M[i].GetRow(1);
            mPerUnitVector_M[i * 3 + 2] = perUnitMatrix_M[i].GetRow(2);
        }

        gb.SetData(mPerUnitVector_M);
        instanceMat.SetBuffer(Shader.PropertyToID("_InputConstData"), gb);

        List<float> perInstanceIndex = new List<float>();
        instanceNum = (int)Mathf.Ceil((float)aTotalNum / (float)aBatchNum);
        
        block = new MaterialPropertyBlock();
        matrices = new Matrix4x4[instanceNum];

        for (int i = 0; i < instanceNum; i++)
        {
            perInstanceIndex.Add((float)i);
            matrices[i] = Matrix4x4.TRS(new Vector3(0, 0, 0), Quaternion.identity, Vector3.one);
        }

        block.SetFloatArray("_InstanceIdx", perInstanceIndex);

        return instanceNum;
    }

    //假设当前脚本被挂在到了 environment 对象上 
    void CollectInfo(out int totalNum, out Matrix4x4[] perUnitMatrix_M)
    {
        totalNum = 0;   
        perUnitMatrix_M = null;

        m_CollectedGrass.Clear();

        const string patternScene = "scene_level_[1-3]";
        const string patternGrass = "grass[0-9]*";

        for (int i = 0; i < gameObject.transform.childCount; i++)
        {
            var curObj = gameObject.transform.GetChild(i).gameObject;

            if (Regex.IsMatch(curObj.name, patternScene))  //scene_level_[1|2|3] 
            {
                var staticObj = curObj.transform.Find("static");
                if (staticObj != null)
                {
                    for (int j = 0; j < staticObj.childCount; j++)
                    {
                        if (Regex.IsMatch (staticObj.GetChild(j).name, patternGrass))
                        {
                            m_CollectedGrass.Add(staticObj.GetChild(j).transform);
                        }
                    }
                }
            }
        }

        for (int i = 0; i < m_CollectedGrass.Count; i++)
        {
            totalNum += m_CollectedGrass[i].childCount;
        }

        perUnitMatrix_M = new Matrix4x4[totalNum];
        int idx = 0;

        for (int i = 0; i < m_CollectedGrass.Count; i++)
        {
            for (int k = 0; k < m_CollectedGrass[i].childCount; k++)
            {
                m_CollectedGrass[i].GetChild(k).gameObject.SetActive(true);
                perUnitMatrix_M[idx++] = m_CollectedGrass[i].GetChild(k).localToWorldMatrix;
            }
        }

    }

    //only for test use 
    void CollectInfoTest(out int totalNum, out Matrix4x4[] perUnitMatrix_M)
    {
        totalNum = 1023;
        perUnitMatrix_M = new Matrix4x4[totalNum];  //0-1022

        for (var i = 0; i < 32; i++)
        {
            for (var j = 0; j < 32; j++)
            {
                var ind = i * 32 + j;
                if (ind >= 1023) break;

                perUnitMatrix_M[ind] = Matrix4x4.TRS(new Vector3(j, i * 0.5f, 0), Quaternion.identity, Vector3.one);
            }
        }
    }

    private void OnInit(bool aSupport)
    {
        if (!aSupport)
            return;

        CollectInfo(out totalNum, out mPerUnitMatrix_M);

        //CollectInfoTest(out totalNum, out mPerUnitMatrix_M); // only for test, Replace it!

        if (totalNum < 10 || totalNum < PerInstanceNum)
        {
            totalNum = 0;  //fall back to srp-batch in case too less targets to render in the scene 
            return;
        }

        if (PerInstanceNum <= 0)
        {
            Debug.LogError("Set PerInstanceNum on script inspector before apply GPU Instance!");
            totalNum = 0;
            return;
        }

        instanceNum = BuildMatrixAndBlock(totalNum, PerInstanceNum, mPerUnitMatrix_M);

        mergedMesh = mergeGrassMesh(instanceMesh, PerInstanceNum, new Bounds(Vector3.zero, new Vector3(1000, 1000, 1000)));

    }


    /// <summary>
    /// 合并片面草的网格数据，对每一个单元赋予编号，并存储到顶点色中 
    /// </summary>
    /// <param name="aSrcMesh">单个面片草的模型</param>
    /// <param name="aNum">单个Instance内包含的模型草个数，建议合并后的Mesh总顶点数大于等于256</param> 
    /// <param name="aBounds">合并后模型的包围盒，不能设置过小，不然可能被摄像机剔除</param> 
    /// <returns></returns>
    private static Mesh mergeGrassMesh(Mesh aSrcMesh, int aNum, Bounds aBounds) 
    {
        Mesh output = new Mesh(); 

        Vector3[] vertices = new Vector3[(int)aNum * aSrcMesh.vertexCount]; 
        int[] triangles = new int[(int)aNum * aSrcMesh.triangles.Length]; 
        Vector3[] normals = new Vector3[(int)aNum * aSrcMesh.normals.Length]; 
        Vector3[] uv1 = new Vector3[(int)aNum * aSrcMesh.uv.Length]; 
        Color[] colors = new Color[(int)aNum * aSrcMesh.colors.Length]; 
        //Vector3[] uv2 = new Vector3[(int)aNum * aSrcMesh.uv2.Length];  //第二组UV用于lightmap，草皮没有，所以去除 

        int vertIdx = 0, normalIdx = 0, uvIdx = 0, triIdx = 0, colIdx = 0; 

        for (int i = 0; i < aNum; i++)
        {
            for (int j = 0; j < aSrcMesh.vertexCount; j++)
            {
                vertices[vertIdx + j] = aSrcMesh.vertices[j];
            }
            for (int j = 0; j < aSrcMesh.normals.Length; j++)
            {
                normals[normalIdx + j] = aSrcMesh.normals[j];
            }
            for (int j = 0; j < aSrcMesh.uv.Length; j++)
            {
                uv1[uvIdx + j] = aSrcMesh.uv[j];
            }
            for (int j = 0; j < aSrcMesh.triangles.Length; j++)
            {
                triangles[triIdx + j] = aSrcMesh.triangles[j] + vertIdx;
            }
            for (int j = 0; j < aSrcMesh.colors.Length; j++)
            {
                float idx = ((float)i + 0.1f) / (float)aNum;                      // 0 ~ (aNum-1) 
                colors[colIdx + j] = new Color(aSrcMesh.colors[j].r, idx, 0);     //解码idx时执行: floor(color.g * aNum) 
            }

            vertIdx += aSrcMesh.vertexCount;
            normalIdx += aSrcMesh.normals.Length;
            uvIdx += aSrcMesh.uv.Length;
            triIdx += aSrcMesh.triangles.Length;
            colIdx += aSrcMesh.colors.Length;
        }

        output.SetVertices(vertices);
        output.SetTriangles(triangles, 0);
        output.SetNormals(normals);
        output.SetColors(colors);
        output.SetUVs(0, uv1);
        output.RecalculateBounds();

        output.bounds = aBounds;

        return output;
    }

    private void Render()
    {
        if (option && totalNum > 0)
        {
            Graphics.DrawMeshInstanced(mergedMesh, 0, instanceMat, matrices, instanceNum, block, UnityEngine.Rendering.ShadowCastingMode.Off, false);
        }
    }

    // Start is called before the first frame update
    void Start()
    {
        option = SystemInfo.supportsInstancing;
        Debug.Log("Support Instance or Not = " + option);

        OnInit(option);

        //只有当支持GPU Instance，且待渲染对象数理达到一定程度时才会开启，不然回退到原本的srp-batch方案 
        if (!option || totalNum <= 0) 
        {
            for (int i = 0; i < m_CollectedGrass.Count; i++)
            {
                m_CollectedGrass[i].gameObject.SetActive(true); 
            }
        }
        else
        {
            for (int i = 0; i < m_CollectedGrass.Count; i++)
            {
                m_CollectedGrass[i].gameObject.SetActive(false);
            }
        }
    }



    // Update is called once per frame
    void Update()
    {
        Render();
    }
}
