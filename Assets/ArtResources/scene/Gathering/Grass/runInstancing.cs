using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Text.RegularExpressions;

public class runInstancing : MonoBehaviour
{
    public Material instanceMat;    //֧��GPU Instance�Ĳ���
    public Mesh instanceMesh;       //��ʵ������ģ�� 

    Mesh mergedMesh;        //�ϲ����ʵ����ģ�� 
    Matrix4x4[] matrices;   //DrawMeshInstance������Ҫ��ObjectToWorld���󣬱����ǵ�λ����(�����κα任) 

    int instanceNum = 0;    //GPU Instance ��������
    int totalNum = 0;       //һ���ж����굥λ

    [SerializeField] public int PerInstanceNum = 16;        //�ϲ���һ��Instance�ڵĵ�λ��
                                                            //�������ҪMergeMesh�����Խ�����ֵ����Ϊ1  

    List<Transform> m_CollectedGrass = new List<Transform>();

    Matrix4x4[] mPerUnitMatrix_M;   //��¼��ÿһ�굥λ������ռ�ת������ 
    Vector4[] mPerUnitVector_M;     //ȡMatrix_M��ǰ3�У���3��Vector4Ϊһ�飬��������ݻ��� 

    MaterialPropertyBlock block;    //��ʵ���������ݿ�
    bool option;                    //��ǰ�����Ƿ�֧��ʵ���� 
    GraphicsBuffer gb;              //ʵ����shader��Ҫ���buffer�������->�ᵼ��mPerUnitVector_M 


    int BuildMatrixAndBlock(int aTotalNum, int aBatchNum, Matrix4x4[] perUnitMatrix_M)
    {
        if (perUnitMatrix_M.Length != aTotalNum)
        {
            Debug.LogWarning("Mis-match array length: length of perUnitMatrix_M doesn't match aTotalNum");
            return 0;
        }

        instanceMat.SetInt(Shader.PropertyToID("_TotalNum"), aTotalNum);
        instanceMat.SetInt(Shader.PropertyToID("_BatchNum"), aBatchNum);

        //��shader���һᶨ�� -> Buffer<half4> _InputConstData <- �Լ���GPU�ڴ�ʹ���� 
        //��������ǰ����������ʧλ�þ��� -> ���ڴ��͵�ͼ�����飬������������Ŀ�п����ȳ���һ�� 
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

    //���赱ǰ�ű������ڵ��� environment ������ 
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
    /// �ϲ�Ƭ��ݵ��������ݣ���ÿһ����Ԫ�����ţ����洢������ɫ�� 
    /// </summary>
    /// <param name="aSrcMesh">������Ƭ�ݵ�ģ��</param>
    /// <param name="aNum">����Instance�ڰ�����ģ�Ͳݸ���������ϲ����Mesh�ܶ��������ڵ���256</param> 
    /// <param name="aBounds">�ϲ���ģ�͵İ�Χ�У��������ù�С����Ȼ���ܱ�������޳�</param> 
    /// <returns></returns>
    private static Mesh mergeGrassMesh(Mesh aSrcMesh, int aNum, Bounds aBounds) 
    {
        Mesh output = new Mesh(); 

        Vector3[] vertices = new Vector3[(int)aNum * aSrcMesh.vertexCount]; 
        int[] triangles = new int[(int)aNum * aSrcMesh.triangles.Length]; 
        Vector3[] normals = new Vector3[(int)aNum * aSrcMesh.normals.Length]; 
        Vector3[] uv1 = new Vector3[(int)aNum * aSrcMesh.uv.Length]; 
        Color[] colors = new Color[(int)aNum * aSrcMesh.colors.Length]; 
        //Vector3[] uv2 = new Vector3[(int)aNum * aSrcMesh.uv2.Length];  //�ڶ���UV����lightmap����Ƥû�У�����ȥ�� 

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
                colors[colIdx + j] = new Color(aSrcMesh.colors[j].r, idx, 0);     //����idxʱִ��: floor(color.g * aNum) 
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

        //ֻ�е�֧��GPU Instance���Ҵ���Ⱦ��������ﵽһ���̶�ʱ�ŻῪ������Ȼ���˵�ԭ����srp-batch���� 
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
