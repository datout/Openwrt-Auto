# next 分支测试清单 — V1.1.0-beta7

Beta7 从“纯模块化”进入低风险逻辑优化。本轮重点是 feeds 优先级可维护性、下载缓存与缓存统计，以及 GitHub Actions 源码步骤名称显示。

## 1. 项目自检必须先通过

- 全部 Shell / YAML / 两阶段交接检查继续通过
- `common/config/datout-priority-packages.txt` 存在且可读取
- `feeds.sh` 不再内嵌历史冲突长字符串
- `compile.yml` 使用 `actions/cache@v5` 缓存 `dl/`
- 第二阶段源码步骤名不能再出现字面量 `${{ env.FOLDER_NAME }}`

## 2. feeds 优先级整理

原行为保持：datout 中实际存在的包自动优先；历史兼容优先包继续保留。

区别是历史名单改为：

```text
common/config/datout-priority-packages.txt
```

以后增删优先包无需修改 `feeds.sh` 代码。

## 3. 编译缓存加速

开启“缓存加速编译”后：

1. 继续使用 cachewrtbuild 的 toolchain + ccache
2. 新增 `openwrt/dl` 源码包下载缓存
3. `dl` 缓存按源码/分支/自然周滚动，避免永久固定成第一次的内容
4. 编译结束打印 ccache 命中率以及 `.ccache` / `dl` 大小

关闭缓存开关时，上述新增缓存步骤全部跳过。

## 4. GitHub Actions 显示

第二阶段应显示类似：

```text
下载 Lede-master 源码
```

ImmortalWrt / Official / Lienol 等入口触发第二阶段时，应自动显示对应 `FOLDER_NAME`，不再显示：

```text
下载"${{ env.FOLDER_NAME }}"源码
```

## 5. 完整回归

继续用 Lede x86_64：

- Web2 / Telegram 正常
- menuconfig / seed 回放正常
- 两阶段精确 SEED_COMMIT 正常
- datout / PassWall / Nikki / SSR Plus 等 feeds 行为与 beta6 一致
- `make download` 正常
- 正式编译成功
- build-manifest 正常生成
- 开启缓存时日志出现“缓存源码下载目录”和“缓存命中统计”

## 6. 本轮继续冻结

- 两阶段交接协议
- seed_finalize
- AutoUpdate / Release
- 固件命名
- 编译失败诊断核心逻辑
- `Diy_definition / Diy_prevent` 内部行为
