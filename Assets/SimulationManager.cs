using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class SimulationManager : MonoBehaviour
{
    public Material material;
    public Text fps;
    public Toggle touch;
    public bool canReposition = false;
    Vector3 worldPosition;
    Plane plane;
    float distance;
    Ray ray;

    public void Awake(){
        material.SetFloat("_Speed",0);
        material.SetFloat("_Reset",1);
        material.SetFloat("_Decelleration",0);
        material.SetFloat("_Strength",0);
        plane = new Plane(Vector3.forward, 0);
    }

    private bool CanTouch(){
       Vector2 localMousePosition = touch.graphic.rectTransform.InverseTransformPoint(Input.mousePosition);
        if (touch.graphic.rectTransform.rect.Contains(localMousePosition))
        {
            return false;
        }
        return true;
    }

    public void Update(){
        int f = (int)( 1.0f / Time.deltaTime);
        fps.text = f.ToString() + " fps";
        if ( Input.GetMouseButton(0) && canReposition && CanTouch() ){
            ray = Camera.main.ScreenPointToRay(Input.mousePosition);
            if (plane.Raycast(ray, out distance))
            {
                worldPosition = ray.GetPoint(distance);
                material.SetVector("_GravityPoint",worldPosition);
            }
        }
    }
    public void SetSpeed(float i){
        material.SetFloat("_Speed",i);
    }
    public void SetGravity(float i){
        material.SetFloat("_Strength",i*10.0f);
    }
    public void SetFriction(float i){
        material.SetFloat("_Decelleration",i*100.0f);
    }
    public void SetReset(float i){
        material.SetFloat("_Reset",i);
    }
    public void SetReposition(bool i){
        canReposition = i;
    }
}
