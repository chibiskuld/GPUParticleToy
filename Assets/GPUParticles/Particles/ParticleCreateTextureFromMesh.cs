#if UNITY_EDITOR
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;

public class ParticleCreateTextureFromMesh : EditorWindow
{
    public Mesh mesh;
    public Material worldExecute;
    public Texture texture;
    public int size;
    public int cloudSize;
    public Vector3 offset;

    [MenuItem("Window/Skuld/GPU Particles/Create Default Mesh Texture")]
    static void Init()
    {
        ParticleCreateTextureFromMesh window = (ParticleCreateTextureFromMesh)EditorWindow.GetWindow(typeof(ParticleCreateTextureFromMesh));
        window.Show();
        Debug.Log("Wut?");
    }

    private void OnGUI()
    {
        mesh = (Mesh)EditorGUILayout.ObjectField(mesh, typeof(Mesh), false);
        size = EditorGUILayout.IntField("Texture Size:",size);
        offset = EditorGUILayout.Vector3Field("Offset",offset);
        if ( mesh !=null){
            if (GUILayout.Button("Show Stats"))
            {
                Debug.Log("If I can be a texture containing " + mesh.triangles.Length + " verticies as pixels.");
            }

            if (GUILayout.Button("Make Texture"))
            {
                int width = size;
                int height = size;


                if ( mesh.triangles.Length > size * size)
                {
                    Debug.Log("Output texture too small for mesh. " + mesh.triangles.Length + ":" + (size*size) );
                    return;
                }
                Texture2D tex = new Texture2D(width, height, TextureFormat.RGBAFloat, false);

                //reset (clear) the texture first.
                for (int i = 0; i < size; i++)
                {
                    for (int j = 0; j < size; j++)
                    {
                        tex.SetPixel(i, j, Vector4.zero);
                    }
                }

                Debug.Log("If I can be a texture containing " + mesh.triangles.Length + " verticies as pixels named " + mesh.name + ".exr");

                for (int i = 0; i < mesh.triangles.Length; i++)
                {
                    int x = i % size;
                    int y = i / size;
                    int t = mesh.triangles[i];

                    Vector4 color = new Vector4(mesh.vertices[t].x+offset.x, mesh.vertices[t].y+offset.y, mesh.vertices[t].z+offset.z, 1);
                    tex.SetPixel(x, y, color);
                    if (i % 100 == 0)
                    {
                        EditorUtility.DisplayProgressBar(
                            "If I'm a progress bar",
                            "Then I will give you the illusion of progress: " + i.ToString() + "/" + mesh.triangles.Length.ToString(),
                            (float)i / (float)mesh.triangles.Length
                        );
                    }
                }
                EditorUtility.ClearProgressBar();
                tex.Apply();
                byte[] bytes = tex.EncodeToEXR(Texture2D.EXRFlags.None);
                Object.DestroyImmediate(tex);
                File.WriteAllBytes(Application.dataPath + "/GPUParticles/default shape.exr", bytes);
                Debug.Log("Then, I will give you my pixels for execution.");
            }
            cloudSize = EditorGUILayout.IntField("Point Cloud Multiplier",cloudSize);
            if (GUILayout.Button("Make Point Mesh"))
            {
                Mesh pointMesh = new Mesh();
                Vector3[] verticies = new Vector3[mesh.vertexCount * cloudSize];
                int[] indicies = new int[mesh.vertexCount * cloudSize];
                for ( int i = 0; i < mesh.vertexCount; i++ ){
                    for ( int j = 0; j < cloudSize; j++ ){
                        int k = (j*mesh.vertexCount) + i;
                        verticies[k] = mesh.vertices[i];
                        indicies[k] = k;
                    }
                    EditorUtility.DisplayProgressBar(
                        "If I'm a progress bar",
                        "Then I will give you the illusion of progress: " + i.ToString() + "/" + mesh.vertices.Length.ToString(),
                        (float)i / (float)mesh.vertices.Length
                    );
                }
                EditorUtility.DisplayProgressBar(
                    "If I'm a progress bar",
                    "Then I will give you the illusion of progress: Saving",
                    1.0f
                );
                pointMesh.SetVertices(verticies);
                pointMesh.SetIndices(indicies,MeshTopology.Points,0);
                AssetDatabase.CreateAsset(pointMesh,"Assets/GPUParticles/PointCloud.asset");
                AssetDatabase.SaveAssets();
                EditorUtility.ClearProgressBar();
                Debug.Log("If I can be a Mesh converted to PointCloud then I will give you:");
                Debug.Log("Number of points in PointCloud:" + (verticies.Length ));
            }
        }
    }
}
#endif