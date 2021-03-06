---
layout: "post"
title: "阿里云产品使用"
date: "2020-05-11 21:08"
categories: [arch]
---

## 域名证书

- SSL证书
    - 单个域名 - DV域名级SSL - 免费版
    - 一次只能申请一个二级域名，有效期1年，可申请多个，同一域名可重复申请
    - 生成成功后会自动解析到阿里云域名，如申请`api.aezo.cn`的证书，会生成一个`_dnsauth.api`的解析

## DataV可视化大屏

- 如果进入控制台通过`https://datav.aliyuncs.com/`进入，则生成的发布链接也是HTTPS，且调试和发布后的API都需要是HTTPS，图片也要是HTTPS；如果进入控制台通过`http://datav.aliyuncs.com/`进入，则HTTP即可

### 基础平面地图

- 基于蓝图编辑器更新组件配置，可设置参数如下

```js
// 基础平面地图可更新配置项说明
{
	// 无极缩放
	"steplessZooming": true,
	// 高清渲染
	"highPerformance": false,
	// 全局配置
	"mapOptions": {
		// 地图背景
		"background": "rgba(0,0,0,0)",
		// 地图缩放
		"zoom": {
			// 缩放范围
			"zoomRange": [
				0,
				18
			],
			// 默认级别
			"defaultZoom": 12.9
		},
		// 中心点坐标
		"center": {
			"lng": 121.6165,
			"lat": 31.1593
		},
		// 比例尺控件
		"scaleControl": {
			// 是否展示
			"show": false,
			"fontColor": "#fff",
			"borderColor": "#777"
		}
	},
	// 弹框配置
	"popupStyle": {
		"textStyle": {
			"fontFamily": "Microsoft Yahei",
			"fontWeight": "normal",
			"fontSize": 12,
			"color": "#FFFFFF"
		},
		"lineHeight": 1.4,
		"borderRadius": 5,
		"margin": {
			"top": 10,
			"bottom": 10,
			"left": 20,
			"right": 20
		},
		"backgroundColor": "rgba(6, 75, 199, 0.8)",
		"closeBtn": {
			"color": "rgba(255, 255, 255, 0)",
			"size": 16,
			"top": 0,
			"right": 0
		}
	},
	// 交互配置
	"interactive": {
		"dragging": true,
		"scrollWheelZoom": true,
		"isInteractive": true
	}
}
```

### 三维城市地图

- 三维城市只支持部分城市和城市的部分区域，且最大范围是9Km2。如果需要显示范围较大可多使用几个三维城市组件对地图区域进行切割，然后动态进行组件显示和隐藏。需要(独立)显卡和机器配置较好
- 暂时不支持基于蓝图编辑器进行组件配置更新，如动态更新三维城市区域



