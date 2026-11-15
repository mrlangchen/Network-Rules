# 策略组与规则调用顺序

策略组表仅控制展示位置；规则调用表决定先匹配谁。未新增第三方规则或服务组。

## 策略组展示

|序号|策略组|首选候选|
|---|---|---|
|1|🚀 节点选择|🔗 ISP 链式代理|
|2|🔗 ISP 链式代理|REJECT|
|3|🤖 ChatGPT|🔗 ISP 链式代理|
|4|🤖 Claude|🔗 ISP 链式代理|
|5|🤖 Gemini|🔗 ISP 链式代理|
|6|🤖 Copilot|🔗 ISP 链式代理|
|7|🍎 苹果服务|🚀 节点选择|
|8|📢 谷歌FCM|🚀 节点选择|
|9|Ⓜ️ 微软服务|🚀 节点选择|
|10|Ⓜ️ 微软云盘|🚀 节点选择|
|11|☁️ CloudFlare|🚀 节点选择|
|12|📲 电报消息|🚀 节点选择|
|13|📹 油管视频|🚀 节点选择|
|14|🎥 奈飞视频|🚀 节点选择|
|15|📹 TikTok|🚀 节点选择|
|16|🎥 亚马逊视频|🚀 节点选择|
|17|🎥 迪士尼+|🚀 节点选择|
|18|📺 哔哩哔哩|DIRECT|
|19|🎶 网易音乐|DIRECT|
|20|🎯 全球直连|DIRECT|
|21|🛑 广告拦截|REJECT|
|22|🍃 应用净化|REJECT|
|23|🐟 漏网之鱼|🚀 节点选择|
|24|🇸🇬 新加坡节点|REJECT|
|25|🇨🇳 台湾节点|REJECT|
|26|🇯🇵 日本节点|REJECT|
|27|🇭🇰 香港节点|REJECT|
|28|🇺🇸 美国节点|REJECT|

ISP 的 REJECT 是等待本地节点绑定的占位值，不是最终业务出口；地区组无节点时拒绝连接。当前全局脚本会重排分组，接入前需要对个人主配置分支停用那部分旧逻辑。

## 规则调用

拦截 → 专用服务例外（FCM、YouTube、Disney）→ AI → 其他通信与流媒体 → 科技服务 → 通用代理 → 显式直连 → GEOIP CN → MATCH。服务组保留手动选择出口的能力。

这里不直接照抄界面分类顺序：FCM、YouTube 必须先于 Gemini，防止 google.com / googleapis.com 的宽泛规则覆盖专用分组；Disney 先于 ChatGPT，保留 disney.my.sentry.io 的专用分组；OneDrive 先于微软服务，防止 live.com / sfx.ms 等宽泛规则覆盖云盘分组。它们均位于 PROXY 用途类别内，不影响 REJECT > PROXY > DIRECT 的类别优先级。

|序号|规则集|分流目标|用途类别|有效条数|注释条数|
|---|---|---|---|---|---|
|1|AdBlock|🛑 广告拦截|REJECT|613|1|
|2|AppClean|🍃 应用净化|REJECT|1009|27|
|3|Reject|REJECT|REJECT|104|0|
|4|GoogleFCM|📢 谷歌FCM|PROXY|35|0|
|5|YouTube|📹 油管视频|PROXY|14|0|
|6|Disney|🎥 迪士尼+|PROXY|20|0|
|7|ChatGPT|🤖 ChatGPT|PROXY|33|0|
|8|Claude|🤖 Claude|PROXY|18|3|
|9|Gemini|🤖 Gemini|PROXY|16|0|
|10|Copilot|🤖 Copilot|PROXY|30|27|
|11|Telegram|📲 电报消息|PROXY|12|0|
|12|Netflix|🎥 奈飞视频|PROXY|2288|0|
|13|TikTok|📹 TikTok|PROXY|29|0|
|14|AmazonPrime|🎥 亚马逊视频|PROXY|19|1|
|15|Bilibili|📺 哔哩哔哩|PROXY|32|4|
|16|NetEaseMusic|🎶 网易音乐|PROXY|37|0|
|17|Apple|🍎 苹果服务|PROXY|1588|1|
|18|OneDrive|Ⓜ️ 微软云盘|PROXY|16|0|
|19|Microsoft|Ⓜ️ 微软服务|PROXY|94|4|
|20|Cloudflare|☁️ CloudFlare|PROXY|27|0|
|21|Proxy|🚀 节点选择|PROXY|6098|180|
|22|Direct|DIRECT|DIRECT|1|0|
|23|GlobalDirect|🎯 全球直连|DIRECT|1069|1619|

最后两条为 `GEOIP,CN,🎯 全球直连` 和 `MATCH,🐟 漏网之鱼`。保留原有 CN 兜底，不改变 DNS 白名单。规则重排可能改变父子域名、包含网段的先后命中；相关条目见 audit/containment-review.csv，未将它们当作完全重复直接注释。
