# next 分支测试清单 — V1.1.0-beta6

V1.1.0-beta6 在 beta1~beta5 已完整编译通过的基础上，加快模块化收尾：一次性把 `Diy_definition` 与 `Diy_prevent` 两个剩余大函数原样迁出 `common.sh`。本轮仍不修改函数内部逻辑。

## 1. 项目自检必须先通过

- `common/common.sh` 与全部 `common/lib/*.sh` 通过 `bash -n`
- `definition.sh / prevent.sh` 均由 `common.sh` 正常 source
- `Diy_definition / Diy_prevent` 只存在一份定义，且不再位于 `common.sh`
- `Diy_menu*` 调度函数仍保留在 `common.sh`
- `common.sh` 应缩减到 200 行以内
- beta1~beta4 的两阶段、诊断、Manifest 回归检查仍继续通过

## 2. 本轮模块迁移

仅原样迁移：

- `common/lib/definition.sh` → `Diy_definition`
- `common/lib/prevent.sh` → `Diy_prevent`

迁移脚本会对两个函数正文做 SHA256 对比，确保迁移前后逐字一致。

外部调用不变：

```bash
bash common.sh Diy_menu5
```

`Diy_menu5` 仍按原顺序执行：

```text
Diy_management → Diy_definition → Diy_prevent
```

## 3. 完整回归

继续使用 Lede x86_64：

1. Web2 / Telegram 正常
2. `make menuconfig` 正常
3. seed minimal + 回放校验正常
4. `Diy_menu5` 正常，不出现 `Diy_definition: command not found` / `Diy_prevent: command not found`
5. 插件冲突处理、FW3/FW4、AdGuardHome、GeoData 等原有行为保持不变
6. 两阶段普通 push + workflow_dispatch 正常
7. 第二阶段 `GIT_REFNAME=next`、`SAFE_BRANCH_MODE=true`、精确 `SEED_COMMIT`
8. 正式编译成功并生成 `build-manifest-*`

## 4. 本轮继续冻结

- 两阶段交接
- seed_finalize
- compile_firmware 错误诊断
- cachewrtbuild
- AutoUpdate
- Release / 固件命名
- `Diy_definition / Diy_prevent` 内部逻辑

Beta6 只完成 common.sh 模块化收尾；逻辑清理从 Beta7 开始。
