using System;
using System.Reflection;
using HarmonyLib;
using TenCrowns.AppCore;
using TenCrowns.GameCore;
using UnityEngine;

namespace MyMod
{
    public class ModEntryPoint : ModEntryPointAdapter
    {
        private const string HarmonyId = "com.yourname.mymod";
        private static Harmony _harmony;

        public override void Initialize(ModSettings modSettings)
        {
            base.Initialize(modSettings);

            if (_harmony != null) return; // Triple-load guard: game loads DLL three times

            try
            {
                _harmony = new Harmony(HarmonyId);
                ApplyPatches();
                Debug.Log("[MyMod] Harmony patches applied successfully.");
            }
            catch (Exception ex)
            {
                Debug.LogError($"[MyMod] Failed to apply patches: {ex}");
            }
        }

        public override void Shutdown()
        {
            _harmony?.UnpatchAll(HarmonyId);
            _harmony = null;
            Debug.Log("[MyMod] Harmony patches removed.");
            base.Shutdown();
        }

        private void ApplyPatches()
        {
            // Example: Patch a method in Assembly-CSharp (which can't be referenced
            // at compile time). Use AccessTools.TypeByName for runtime type resolution
            // and Harmony's manual Patch() API.
            //
            // Type targetType = AccessTools.TypeByName("SomeClassName");
            // if (targetType == null)
            // {
            //     Debug.LogError("[MyMod] Could not find target type.");
            //     return;
            // }
            //
            // MethodInfo targetMethod = AccessTools.Method(targetType, "MethodName");
            // if (targetMethod == null)
            // {
            //     Debug.LogError("[MyMod] Could not find target method.");
            //     return;
            // }
            //
            // _harmony.Patch(
            //     original: targetMethod,
            //     postfix: new HarmonyMethod(typeof(ModEntryPoint), nameof(MyPostfix))
            // );

            Debug.Log("[MyMod] Patches registered.");
        }

        // Example postfix — receives the patched object as __instance.
        // Use Traverse to access fields when patching Assembly-CSharp types.
        //
        // private static void MyPostfix(object __instance)
        // {
        //     try
        //     {
        //         Traverse t = Traverse.Create(__instance);
        //         // t.Field("fieldName").SetValue(newValue);
        //     }
        //     catch (Exception ex)
        //     {
        //         Debug.LogError($"[MyMod] Error in postfix: {ex}");
        //     }
        // }
    }
}
