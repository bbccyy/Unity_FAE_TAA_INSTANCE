//using Babeltime.CSharpLib.Sys;
//using Babeltime.DB.DTO;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace Babeltime.DB.GameUtils
{
    public enum DeviceLevel
    {
        Low = 1,
        Middle = 2,
        High = 3,
        MaxHigh = 4,    //超高配置
    }
    //设备分级管理器
    public static class GameQualityUtil
    {
        /// <summary>
        /// 白名单
        /// </summary>
        public static Dictionary<string, DeviceLevel> deviceQuality = new Dictionary<string, DeviceLevel>
        {
            //模拟器
            { "Netease MuMu",DeviceLevel.Middle },
            { "Tencent virtual machine",DeviceLevel.Low },
            //华为
            { "HUAWEI EVA%-AL00",DeviceLevel.Low },     //p9
            { "HUAWEI EVA%-AL10",DeviceLevel.Low },     //p9
            { "HUAWEI VIE%-AL10",DeviceLevel.Low },     //p9 Plus
            { "HUAWEI NXT%-AL10",DeviceLevel.Low },     //Mate 8
            { "HUAWEI DUK%-AL20",DeviceLevel.Low },     //v9
            { "HUAWEI COL%-AL10",DeviceLevel.Middle },  //Honor 10
            // OPPO
            {"OPPO PACM00",DeviceLevel.Low }, // R15
            {"OPPO PACT00",DeviceLevel.Low }, // R15
            {"OPPO PADM00",DeviceLevel.Low }, // A3
            {"OPPO PADT00",DeviceLevel.Low }, // A3
            {"OPPO PBBM00",DeviceLevel.Low }, // A7X
            {"OPPO A73",DeviceLevel.Low },
            {"OPPO A83",DeviceLevel.Low },
            {"OPPO V1813A",DeviceLevel.Low }, // Y97
            {"OPPO V1813T",DeviceLevel.Low }, // Z3i

            // 小米
            {"Xiaomi Redmi Note 4",DeviceLevel.Low },
            {"Xiaomi MI MAX 2",DeviceLevel.Low },

            {"Xiaomi MI 8 Lite",DeviceLevel.Middle},
            // VIVO
            {"vivo Y75",DeviceLevel.Low },

            // 魅族
            {"Meizu S6",DeviceLevel.Low },

            // >>>>>>>>>>>>>>  Apple iPhone 系列   <<<<<<<<<<<<<,
            // 处理器 A8 //-(iphone6) （RAM 1G) (应该游戏不支持)
            {"iPhone7,1",DeviceLevel.Low},   // @"iPhone 6";
            {"iPhone7,2",DeviceLevel.Low},   // @"iPhone 6 Plus";

            // 处理器 A9 //-(iphone6s) （RAM 2G)
            {"iPhone8,1",DeviceLevel.Low},   // @"iPhone 6s";
            {"iPhone8,2",DeviceLevel.Low},   // @"iPhone 6s Plus";

            // 处理器 A9 //-(iphone SE) （RAM 2G)
            {"iPhone8,4",DeviceLevel.Low},   // @"iPhone se";

            // 处理器 A10 //-(iphone7)  （RAM  7 2G  7 plus 3G）
            {"iPhone9,1",DeviceLevel.Low},   // @"iPhone 7";
            {"iPhone9,2",DeviceLevel.Low},   // @"iPhone 7 Plus";
            {"iPhone9,3",DeviceLevel.Low},   // @"iPhone 7";
            {"iPhone9,4",DeviceLevel.Low},   // @"iPhone 7 Plus";

            // 处理器 A11//(iphone8) (RAM 3G)
            {"iPhone10,1",DeviceLevel.Middle},   // @"iPhone 8";
            {"iPhone10,2",DeviceLevel.Middle},   // @"iPhone 8 Plus";
            {"iPhone10,4",DeviceLevel.Middle},   // @"iPhone 8";
            {"iPhone10,5",DeviceLevel.Middle},   // @"iPhone 8 Plus";

            // 处理器 A11//-(iphoneX) (RAM 3G)
            {"iPhone10,3",DeviceLevel.Middle},   // @"iPhone X";
            {"iPhone10,6",DeviceLevel.Middle},   // @"iPhone X";

            // 处理器 A12//-(iphone XS) (RAM 4G)
            {"iPhone11,2",DeviceLevel.High},   // @iPhone XS;
            {"iPhone11,4",DeviceLevel.High},   // @iPhone XS MAX;
            {"iPhone11,6",DeviceLevel.High},   // @iPhone XS MAX;

            // 处理器 A12//-(iphone XR) (RAM 3G)
            {"iPhone11,8",DeviceLevel.High},   // @iPhone XR;

            // 处理器 A13//-(iphone 11) (RAM 4G)
            {"iPhone12,1",DeviceLevel.High},   // @iPhone 11;
            {"iPhone12,3",DeviceLevel.High},   // @iPhone 11 Pro;
            {"iPhone12,5",DeviceLevel.High},   // @iPhone 11 Pro MAX;

            // 处理器 A14//-(iphone 12) (RAM 4G)
            {"iPhone13,1",DeviceLevel.High},   // @iPhone 12 mini;
            {"iPhone13,2",DeviceLevel.High},    // @iPhone;
            {"iPhone13,3",DeviceLevel.High},   // @iPhone 12 Pro ;
            {"iPhone13,4",DeviceLevel.High},   // @iPhone 12 Pro MAX;
            // >>>>>>>>>>>>>>  Apple iPad 系列   <<<<<<<<<<<<<,
            //// A8 双核64位 M8   RAM 2G
            {"iPad5,1",DeviceLevel.Low},   // @iPad Mini 4;
            {"iPad5,2",DeviceLevel.Low},   // @iPad Mini 4;

            //// A8X 3核64位 M8   RAM 2G
            {"iPad5,3",DeviceLevel.Low},   // @iPad Air2;
            {"iPad5,4",DeviceLevel.Low},   // @iPad Air2;

            //// A9X 双核64位 M9   RAM 2G
            {"iPad6,3",DeviceLevel.Low},   // @iPad Pro 9.7;
            {"iPad6,4",DeviceLevel.Low},   // @iPad Pro 9.7;

            //// A9X 双核64位 M9   RAM 4G
            {"iPad6,7",DeviceLevel.Low},   // @iPad Pro 12.9;
            {"iPad6,8",DeviceLevel.Low},   // @iPad Pro 12.9;


            //// A9 双核64位 M9   RAM 2G
            {"iPad6,11",DeviceLevel.Middle},   // @iPad 5;
            {"iPad6,12",DeviceLevel.Middle},   // @iPad 5;


            //// A10X 6核 M10   RAM 4G
            {"iPad7,1",DeviceLevel.Middle},   // @iPad Pro 12.9 inch 2nd gen;
            {"iPad7,2",DeviceLevel.Middle},   // @iPad Pro 12.9 inch 2nd gen;
            {"iPad7,3",DeviceLevel.Middle},   // @iPad Pro 10.5 inch;
            {"iPad7,4",DeviceLevel.Middle},   // @iPad Pro 10.5 inch;

            //// A10X 四核 M10   RAM 2G
            {"iPad7,5",DeviceLevel.Middle},   // @iPad 6;
            {"iPad7,6",DeviceLevel.Middle},   // @iPad 6;

            //// A10 M10   RAM 3G
            {"iPad7,11",DeviceLevel.Middle},   // @iPad 7;
            {"iPad7,12",DeviceLevel.Middle},   // @iPad 7;

            //// A12X 仿生8核 M12   RAM 4G
            {"iPad8,1",DeviceLevel.High},   // @iPad Pro 11-inch;
            {"iPad8,2",DeviceLevel.High},   // @iPad Pro 11-inch;
            {"iPad8,3",DeviceLevel.High},   // @iPad Pro 11-inch;
            {"iPad8,4",DeviceLevel.High},   // @iPad Pro 11-inch;

            //// A12X 仿生8核 M12   RAM 4G
            {"iPad8,5",DeviceLevel.High},   // @iPad Pro 12.9-inch 3rd gen;
            {"iPad8,6",DeviceLevel.High},   // @iPad Pro 12.9-inch 3rd gen;
            {"iPad8,7",DeviceLevel.High},   // @iPad Pro 12.9-inch 3rd gen;
            {"iPad8,8",DeviceLevel.High},   // @iPad Pro 12.9-inch 3rd gen;
            {"iPad8,9",DeviceLevel.High},   // @iPad Pro 11-inch 2nd gen;
            {"iPad8,10",DeviceLevel.High},   // @iPad Pro 11-inch 2nd gen;
            {"iPad8,11",DeviceLevel.High},   // @iPad Pro 12.9-inch 4th gen;
            {"iPad8,12",DeviceLevel.High},   // @iPad Pro 12.9-inch 4th gen;

            //// A12  M12   RAM 3G
            {"iPad11,1",DeviceLevel.High},   // @iPad Mini5;
            {"iPad11,2",DeviceLevel.High},   // @iPad Mini5;

            //// A12  M12   RAM 3G
            {"iPad11,3",DeviceLevel.High},   // @iPad Air 3;
            {"iPad11,4",DeviceLevel.High},   // @iPad Air 3;

            ////64 位架构的 A12 仿生  RAM 3G
            {"iPad11,6",DeviceLevel.High},   // @iPad 8;
            {"iPad11,7",DeviceLevel.High},   // @iPad 8;

            ////配置64位A14仿生处理器  RAM 4G
            {"iPad13,1",DeviceLevel.High},   // @iPad Air 4;
            {"iPad13,2",DeviceLevel.High},   // @iPad Air 4;
        };

        /// <summary>
        /// Gpu名单
        /// </summary>
        public static Dictionary<string, Dictionary<string, DeviceLevel>> gpuQuality = new Dictionary<string, Dictionary<string, DeviceLevel>>
        {
            { "Mali",new Dictionary<string, DeviceLevel>
                {
                    {"400",DeviceLevel.Low},
                    {"450",DeviceLevel.Low},
                    {"G51",DeviceLevel.Low},
                    {"G52",DeviceLevel.Low},
                    {"G71",DeviceLevel.Low},
                    {"G72",DeviceLevel.Middle},
                    {"G76",DeviceLevel.Middle},
                    {"G77",DeviceLevel.Middle},
                    {"G78",DeviceLevel.High},       //Mali-G78  麒麟9000 Exynos 1080
                    {"T604",DeviceLevel.Low},
                    {"T624",DeviceLevel.Low},
                    {"T628",DeviceLevel.Low},
                    {"T720",DeviceLevel.Low},
                    {"T760",DeviceLevel.Low},
                    {"T830",DeviceLevel.Low},
                    {"T860",DeviceLevel.Low},
                    {"T880",DeviceLevel.Low},
                }
            },
            {
                "Apple",new Dictionary<string, DeviceLevel>
                {
                    {"A10 ",DeviceLevel.Middle},
                    {"A11 ",DeviceLevel.High},
                    {"A12",DeviceLevel.High},
                    {"A13",DeviceLevel.High},
                    {"A14",DeviceLevel.High},   //iPhone 12 Pro/iPhone 12 Pro Max/iPhone 12 mini/iPhone 12
                    {"A9",DeviceLevel.Middle},
                    {"M1",DeviceLevel.MaxHigh},    //11 英寸 iPad Pro/12.9 英寸 iPad Pro
                }
            },
            {
                "Tegra",new Dictionary<string, DeviceLevel>
                {
                    {"4",DeviceLevel.Low},
                    {"K1",DeviceLevel.Middle},
                    {"X1",DeviceLevel.High},
                }
            },
            {
                "PowerVR",new Dictionary<string, DeviceLevel>
                {
                    {"G6200",DeviceLevel.Low},
                    {"G6400",DeviceLevel.Low},
                    {"G6430",DeviceLevel.Low},
                    {"GE8100",DeviceLevel.Middle},
                    {"GE8300",DeviceLevel.Middle},
                    {"GE8320",DeviceLevel.Middle},
                    {"GE8322",DeviceLevel.Low},
                    {"GM9446",DeviceLevel.Middle},
                    {"GX6250",DeviceLevel.Low},
                    {"GX6450",DeviceLevel.Middle},
                    {"GXA6850",DeviceLevel.Middle},
                    {"SGX530",DeviceLevel.Low},
                    {"SGX531",DeviceLevel.Low},
                    {"SGX535",DeviceLevel.Low},
                    {"SGX540",DeviceLevel.Low},
                    {"SGX543",DeviceLevel.Low},
                    {"SGX544",DeviceLevel.Low},
                    {"SGX545",DeviceLevel.Low},
                    {"SGX554",DeviceLevel.Low},
                }
            },
            {
                "Adreno",new Dictionary<string, DeviceLevel>
                {
                    {"200",DeviceLevel.Low},
                    {"203",DeviceLevel.Low},
                    {"205",DeviceLevel.Low},
                    {"220",DeviceLevel.Low},
                    {"225",DeviceLevel.Low},
                    {"302",DeviceLevel.Low},
                    {"304",DeviceLevel.Low},
                    {"305",DeviceLevel.Low},
                    {"306",DeviceLevel.Low},
                    {"308",DeviceLevel.Low},
                    {"320",DeviceLevel.Low},
                    {"330",DeviceLevel.Low},
                    {"405",DeviceLevel.Low},
                    {"418",DeviceLevel.Low},
                    {"420",DeviceLevel.Low},
                    {"430",DeviceLevel.Low},
                    {"504",DeviceLevel.Low},
                    {"505",DeviceLevel.Low},
                    {"506",DeviceLevel.Low},
                    {"508",DeviceLevel.Low},
                    {"509",DeviceLevel.Low},
                    {"510",DeviceLevel.Low},
                    {"512",DeviceLevel.Low},
                    {"530",DeviceLevel.Low},
                    {"540",DeviceLevel.Low},
                    {"610",DeviceLevel.Low},
                    {"612",DeviceLevel.Low},
                    {"615",DeviceLevel.Low},
                    {"616",DeviceLevel.Low},
                    {"618",DeviceLevel.Low},
                    {"620",DeviceLevel.Middle},
                    {"630",DeviceLevel.Middle},
                    {"640",DeviceLevel.High},
                    {"650",DeviceLevel.High},
                    {"660",DeviceLevel.High},//骁龙888   骁龙888plus
                }
            },
        };

        /// <summary>
        /// 我的设备分级
        /// </summary>
        public static DeviceLevel myDeviceLevel;

        /// <summary>
        /// 设置我的
        /// </summary>
        public static void InitDeviceLevelSetting()
        {
#if UNITY_EDITOR_WIN || UNITY_EDITOR_OSX
            myDeviceLevel = DeviceLevel.High;
#else
            myDeviceLevel = OtherDeviceLevel();
#endif
            //BtLogger.Log($"本机分级状态：{myDeviceLevel}");
            initSettings();
        }

        /// <summary>
        /// 测试方法，人为切换加载等级
        /// 之后会删除
        /// </summary>
        /// <param name="level"></param>
        public static void ChangeDeviceLevelTest(DeviceLevel level)
        {
            myDeviceLevel = level;
            initSettings();
        }

        private static DeviceLevel OtherDeviceLevel()
        {
            string deviceName = SystemInfo.deviceModel;
            Debug.Log($"本机deviceName:{deviceName}");
            DeviceLevel targetLevel = DeviceLevel.Low;
            foreach (var item in deviceQuality)
            {
                if (deviceName.Contains(item.Key))
                {
                    targetLevel = item.Value;
                    return targetLevel;
                }
            }
            string gpuName = SystemInfo.graphicsDeviceName;
            Debug.Log($"本机gpuName:{gpuName}");
            foreach (var item in gpuQuality)
            {
                if (gpuName.Contains(item.Key))
                {
                    foreach (var temp in item.Value)
                    {
                        if (gpuName.Contains(temp.Key))
                        {
                            targetLevel = temp.Value;
                            return targetLevel;
                        }
                    }
                }
            }
            return targetLevel;
        }

        //所有的都在 TestMain 中
        private static DeviceLevel IOSDeviceLevel()
        {
            string modelStr = SystemInfo.deviceModel;
            if (
                modelStr.Equals("iPhone12,1") || modelStr.Equals("iPhone12,3") ||   //iPhone_11/iPhone_11_Pro
                modelStr.Equals("iPhone12,5") ||                                    //iPhone_11_Pro_Max
                modelStr.Equals("iPhone13,1") || modelStr.Equals("iPhone13,2") ||   //iPhone_12_mini/iPhone_12
                modelStr.Equals("iPhone13,3") || modelStr.Equals("iPhone13,4"))     //iPhone_12_Pro/iPhone_12_Pro_Max
            {
                return DeviceLevel.High;
            }
            else if (
                modelStr.Equals("iPhone10,3") || modelStr.Equals("iPhone10,6") ||   //iPhone_X
                modelStr.Equals("iPhone11,8") || modelStr.Equals("iPhone11,2") ||   //iPhone_XR/iPhone_XS
                modelStr.Equals("iPhone11,4") || modelStr.Equals("iPhone11,6") ||   //iPhone_XS_Max_China、iPhone_XS_Max
                modelStr.Equals("iPhone8,3") || modelStr.Equals("iPhone8,4") ||     //iPhoneSE
                modelStr.Equals("iPhone12,8"))                                      //iPhone_SE_2
            {
                return DeviceLevel.Middle;
            }
            return DeviceLevel.Low;
        }


        private static void initSettings()
        {
            switch (myDeviceLevel)
            {
                case DeviceLevel.High:
                    {
                        QualitySettings.SetQualityLevel(3);
                    }
                    break;
                case DeviceLevel.Middle:
                    {
                        QualitySettings.SetQualityLevel(2);

                    }
                    break;
                case DeviceLevel.Low:
                    {
                        QualitySettings.SetQualityLevel(1);

                    }
                    break;

            }
        }
    }
}
