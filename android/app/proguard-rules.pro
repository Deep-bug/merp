# 百度地图和定位 SDK 包含 JNI、反射调用，Release 混淆时必须完整保留。
-keep class com.baidu.** { *; }
-keep class vi.com.** { *; }
-keep class com.baidu.vi.** { *; }
-dontwarn com.baidu.**
