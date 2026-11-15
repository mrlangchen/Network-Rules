# Network Rules

整理现有 WgetCloud 分流规则与当前个人策略组，准备作为个人 GitHub 主配置。
本版本：2026-11-15。未添加第三方规则集、银行/邮件等新分组。

## 文件

|位置|用途|
|---|---|
|mihomo.yaml|主配置：策略组、rule-providers、rules；以后新增第三方规则/组直接编辑这里|
|rules/*.list|当前规则集。# 开头为注释，不执行；低优先级重复项保留在原文件|
|docs/ORDER.md|完整展示顺序与调用顺序|
|docs/DEDUPLICATION.md|去重口径和结果|
|audit/|原规则、注释记录、变更对照及包含关系|

## 接入状态

这是待绑定本地节点的公开主配置，尚未在当前 Clash 启用。AIRPORT 仅含一个拒绝连接的占位节点，ISP 组暂以 REJECT 占位。它们必须由本地专属脚本替换。不要把未绑定版本直接设为活动订阅。
DNS、Hosts、Sniffer 继续由当前本地全局脚本管理，公开文件不另放一套 DNS。机场 URL、实际节点和 ISP 地址/账号/密码均只留在设备本地。
当前 WgetCloud 卡片的恢复脚本只关联该卡片，不会自动应用到新的个人订阅。新卡片要另行绑定恢复逻辑；现有全局脚本的分组排序、节点注入逻辑也要分离，避免覆盖这里的分组顺序。

## GitHub

目标仓库：https://github.com/mrlangchen/Network-Rules
公开主配置地址：https://raw.githubusercontent.com/mrlangchen/Network-Rules/main/mihomo.yaml
上传本目录内部的文件和子目录，不上传外层压缩包，不上传其他旧版私密包。
当前未核实远程仓库已有内容；如仓库非空，应保留无关文件并按差异更新，不整体删除替换。

## 日常维护

修改某个 list 后刷新对应规则集；调整分组、增加 provider、修改 rules 顺序后刷新主订阅。
添加第三方规则集需要同时定义 rule-providers 项并在 rules 中插入 RULE-SET 调用；添加分组后检查其名称和引用。
分组展示顺序与 rules 匹配顺序独立，规则从上往下取首次匹配。第三方规则可能与现有规则重叠，需按用途放置。
分流顺序调整不等于 DNS 放行，国内 DNS 仍由本地显式白名单决定。
