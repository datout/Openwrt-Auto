# next 分支测试清单 — V1.1.0-beta9

Beta9 第一项只增加网络预设输入，不改 seed/savedefconfig、Cache、固件命名、Release、AutoUpdate 和编译失败诊断核心流程。

## 1. 项目自检

- [ ] `项目自检` 整体 Success
- [ ] `common/tests/network_inputs_test.sh` 通过
- [ ] 六套源码 Workflow 均包含同一组 6 个网络参数
- [ ] `common/common.sh` 与全部 `build/*/relevance/actions_version` 均为 `2.13.0`
- [ ] 两阶段 `BUILD_CONTEXT` 同时包含 6 个网络字段

## 2. Run workflow 页面

在 LEDE 和 ImmortalWrt 的 Run workflow 页面确认出现：

```text
LAN管理地址
LAN子网掩码
上级网关
上游DNS
DHCP服务模式
OpenWrt主机名
```

其中 DHCP 必须有：

```text
保持仓库预设
开启 DHCP
关闭 DHCP
```

## 3. 默认兼容回归

所有网络文本框留空，DHCP 选择“保持仓库预设”，运行一次 LEDE：

- [ ] 日志显示“沿用 build/Lede/diy-part.sh”
- [ ] LEDE 仍使用原来的 `10.0.0.252 / 255.255.255.0`
- [ ] 上级网关仍为 `10.0.0.253`
- [ ] DNS 仍为 `210.22.70.225 210.22.70.3`
- [ ] DHCP 仍按 LEDE 预设关闭
- [ ] 原 seed 内容不因网络输入产生无关变化

## 4. 自定义网络回归

建议在 `next` 运行 LEDE x86_64，填写：

```text
LAN管理地址：192.168.50.2
LAN子网掩码：/24
上级网关：192.168.50.1
上游DNS：223.5.5.5,119.29.29.29
DHCP服务模式：开启 DHCP
OpenWrt主机名：OpenWrt-B9
```

检查：

- [ ] 第一阶段将 `/24` 标准化为 `255.255.255.0`
- [ ] DNS 标准化为空格分隔并去重
- [ ] 第二阶段显示完全相同的网络参数
- [ ] `config_generate` 中写入 LAN 地址、掩码、网关和 DNS
- [ ] 首次启动脚本写入 `dhcp.lan.ignore='0'`
- [ ] 固件主机名为 `OpenWrt-B9`

## 5. `0` 语义回归

LEDE 填写：

```text
LAN管理地址：0
上级网关：0
上游DNS：0
OpenWrt主机名：0
```

应当不再使用 LEDE `diy-part.sh` 中对应的自定义值，而是保留上游源码默认行为。

## 6. 错误输入拦截

以下输入必须在下载源码前失败，并显示“网络参数校验失败”：

```text
LAN管理地址：10.0.0.999
LAN子网掩码：255.0.255.0
上游DNS：1.1.1.1;rm -rf /
OpenWrt主机名：bad hostname
```

下面的组合必须在应用最终网络预设时失败：

```text
LAN管理地址：10.0.0.2
LAN子网掩码：255.255.255.0
上级网关：192.168.1.1
```

## 7. 两阶段一致性

- [ ] 第一阶段 `mishi` 完成标准化
- [ ] `trigger` 将 6 个字段写入 `BUILD_CONTEXT`
- [ ] `compile.yml` 从 `BUILD_CONTEXT` 恢复 6 个字段
- [ ] 第二阶段不得重新回退到空值或 `diy-part.sh` 的另一组值

## 8. 定时编译兼容

各 `build/*/settings.ini` 已增加同名字段。保持空值时行为不变；填入值时应与手工 Run workflow 使用相同校验和覆盖逻辑。

## 9. 本轮继续冻结

- seed_finalize / savedefconfig
- 两阶段精确 `SEED_COMMIT`
- Cache key 与 `dl/` 缓存
- 固件命名与 build-manifest schema
- Release / AutoUpdate 发布顺序
- 编译失败诊断
