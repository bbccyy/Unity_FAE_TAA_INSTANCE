using GameOldBoy.Rendering;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class Demo : MonoBehaviour
{
    TAAComponent taa;

    bool taaEnabled;
    int blend;
    float Blend
    {
        get
        {
            return 1 - 1f / blend;
        }
        set
        {
            blend = (int)(1 / (1 - value));
        }
    }

    bool antiGhosting;
    bool vSync = true;

    int frameCount = 0;
    float timer = 0;
    int fps = 0;

    UniversalRenderPipelineAsset renderPipelineAsset;
    int renderScale;
    float RenderScale
    {
        get
        {
            return renderScale / 10f;
        }
        set
        {
            renderScale = (int)(value * 10);
        }
    }

    void Start()
    {
        taa = GetComponent<TAAComponent>();
        taaEnabled = taa.Enabled;
        Blend = taa.Blend;
        antiGhosting = taa.AntiGhosting;
        QualitySettings.vSyncCount = 1;

        renderPipelineAsset = (UniversalRenderPipelineAsset)GraphicsSettings.currentRenderPipeline;
        RenderScale = renderPipelineAsset.renderScale;
    }

    void Update()
    {
        // fps
        timer += Time.deltaTime;
        frameCount++;
        if (timer >= 1)
        {
            timer -= 1;
            fps = frameCount;
            frameCount = 0;
        }

        if (taaEnabled != taa.Enabled)
        {
            taa.Enabled = taaEnabled;
        }
        if (Blend != taa.Blend)
        {
            taa.Blend = Blend;
        }
        if (antiGhosting != taa.AntiGhosting)
        {
            taa.AntiGhosting = antiGhosting;
        }
        if (RenderScale != renderPipelineAsset.renderScale)
        {
            renderPipelineAsset.renderScale = RenderScale;
        }
        if (vSync != QualitySettings.vSyncCount > 0)
        {
            QualitySettings.vSyncCount = vSync ? 1 : 0;
        }
    }

    private void OnGUI()
    {
        float x = 20, y = 20;
        GUI.Box(new Rect(x, y, 240, 185), $"FPS:{fps}");
        x += 20; y += 30;
        taaEnabled = GUI.Toggle(new Rect(x, y, 100, 30), taaEnabled, "TAA Enabled");
        GUI.enabled = taaEnabled;
        y += 30;
        GUI.Label(new Rect(x, y, 100, 30), "Blend");
        blend = (int)GUI.HorizontalSlider(new Rect(x + 40, y + 5, 100, 30), blend, 1, 32);
        GUI.Label(new Rect(x + 145, y, 50, 20), $"{Blend.ToString("f5")}");
        y += 30;
        antiGhosting = GUI.Toggle(new Rect(x, y, 100, 30), antiGhosting, "Anti-Ghosting");
        GUI.enabled = true;
        y += 30;
        GUI.Label(new Rect(x, y, 100, 30), "Render Scale");
        renderScale = (int)GUI.HorizontalSlider(new Rect(x + 85, y + 5, 100, 30), renderScale, 1, 20);
        GUI.Label(new Rect(x + 190, y, 50, 20), $"{RenderScale.ToString("f1")}");
        y += 30;
        vSync = GUI.Toggle(new Rect(x, y, 110, 30), vSync, "VSync");
    }
}
