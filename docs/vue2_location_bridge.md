# Vue2 调用 Flutter 精确定位 Bridge

## 安全调用原则

Vue2 页面不得在 `created`、`mounted`、路由守卫或页面自动刷新时调用定位。
必须由用户点击“定位”“签到”或“获取当前位置”后再调用，这样应用内隐私确认和
系统“使用 App 期间”权限弹窗都有明确的用户操作来源。

Flutter 不启用后台定位，不在 App 启动时申请权限，也不缓存业务坐标。定位结果为
百度 BD-09 坐标；日志只记录精度和耗时，不记录经纬度及完整地址。

## Vue2 调用示例

```vue
<template>
  <div>
    <button :disabled="locating" @click="locate">
      {{ locating ? '定位中...' : '获取精确位置' }}
    </button>
    <p v-if="location">
      精度：±{{ location.accuracyMeters }} 米
      {{ location.address || '暂未获取到地址' }}
    </p>
    <p v-if="errorMessage">{{ errorMessage }}</p>
    <button v-if="canOpenSettings" @click="openSettings">前往系统设置</button>
  </div>
</template>

<script>
export default {
  data() {
    return {
      locating: false,
      location: null,
      errorMessage: '',
      canOpenSettings: false
    }
  },
  methods: {
    async locate() {
      if (!window.MERPBridge || this.locating) return

      this.locating = true
      this.errorMessage = ''
      this.canOpenSettings = false
      try {
        this.location = await window.MERPBridge.getCurrentPosition({
          timeoutMs: 25000,
          // 外勤/签到建议 50 米；室内弱信号场景可由业务评估后放宽。
          maximumAccuracyMeters: 50
        })
      } catch (error) {
        this.errorMessage = error.message || '定位失败'
        this.canOpenSettings = Boolean(
          error.details && error.details.canOpenSettings
        )
      } finally {
        this.locating = false
      }
    },
    async openSettings() {
      await window.MERPBridge.openAppSettings()
    }
  }
}
</script>
```

也可以使用通用调用入口：

```js
const location = await window.MERPBridge.call(
  'location.getCurrentPosition',
  { timeoutMs: 25000, maximumAccuracyMeters: 50 }
)
```

## 成功返回结构

```json
{
  "latitude": 39.915,
  "longitude": 116.404,
  "accuracyMeters": 18.5,
  "accuracy": 18.5,
  "coordinateType": "bd09ll",
  "provider": "baidu",
  "timestamp": "2026-07-15T10:00:00.000Z",
  "altitude": 42.0,
  "address": "北京市...",
  "city": "北京市",
  "district": "海淀区"
}
```

业务提交时必须同时上传 `coordinateType` 和 `accuracyMeters`。后端不能默认把 BD-09
当成 WGS-84 或 GCJ-02，也不能忽略定位精度。

## 错误结构

```json
{
  "code": "LOCATION_PERMISSION_PERMANENTLY_DENIED",
  "message": "定位权限已被永久拒绝...",
  "incidentId": null,
  "details": {
    "canOpenSettings": true
  }
}
```

| 错误码 | Vue2 处理建议 |
|---|---|
| `LOCATION_PRIVACY_REQUIRED` | 提示用户需要同意定位隐私说明 |
| `LOCATION_PERMISSION_DENIED` | 本次停止定位，允许用户再次点击 |
| `LOCATION_PERMISSION_PERMANENTLY_DENIED` | 展示“前往系统设置”按钮 |
| `LOCATION_SERVICE_DISABLED` | 提示开启系统定位服务，可展示设置按钮 |
| `LOCATION_KEY_MISSING` | 联系管理员检查 iOS AK 与启动参数 |
| `LOCATION_TIMEOUT` | 检查网络/GPS 后重试 |
| `LOCATION_ACCURACY_INSUFFICIENT` | 提示移动到开阔位置，不允许伪装成精确定位成功 |
| `LOCATION_SDK_FAILED` | 记录故障信息并联系研发 |
| `LOCATION_UNSUPPORTED_PLATFORM` | 当前 Demo 尚未配置该平台定位 SDK |

## 业务验收清单

1. 启动 App 和打开普通 Vue2 页面时不弹定位权限。
2. 用户点击定位后，首次先显示隐私说明，再显示系统权限。
3. 拒绝权限后页面不死循环、不自动再次申请。
4. 永久拒绝后只能由用户点击按钮打开系统设置。
5. 返回精度超过业务阈值时不允许完成签到或外勤提交。
6. 页面重复点击时 Flutter 合并并发定位请求，不重复弹窗。
7. 后端保存坐标系、精度和定位时间，避免坐标系误用。
