# next 分支测试清单 — V1.1.0-beta2

V1.1.0-beta2 在 beta1 已验证成功的“两阶段构建”基础上，只优化正式编译阶段的稳定性、诊断、可复现性和 GitHub Actions 兼容性。

## 1. 两阶段交接不回归

第一阶段仍应：

1. Web2/SSH 运行 `make menuconfig`
2. 保存 minimal seed 并回放校验
3. 普通 push 到 `next`
4. workflow_dispatch 触发第二阶段

第二阶段应看到：

- `GIT_REFNAME: next`
- `SAFE_BRANCH_MODE: true`
- `UPLOAD_RELEASE: false`
- `UPDATE_FIRMWARE_ONLINE: false`

## 2. 构建清单

第二阶段“生成构建清单和缓存标识”应打印：

- 源码提交 SHA
- `.config` SHA256
- seed SHA256
- 缓存标识

成功编译后 Actions → Artifacts 应多出：

`build-manifest-<源码>-<配置>-<run number>`

其中 `build-manifest.json` 应包含 source / feeds / target / configuration / host 等字段，不包含 Token 或 Secret。

## 3. 缓存

缓存日志中的 mixkey 应使用：

`SOURCE_CODE-REPO_BRANCH-TARGET_BOARD-TARGET_SUBTARGET`

`cachewrtbuild` 自己仍会追加 tools/toolchain Git hash，并为 ccache 使用恢复前缀，因此不需要把每次 seed hash 强行塞进缓存 key。

## 4. 编译失败行为

正常成功时不会触发任何专用补丁。

如果普通软件包失败：

- 先执行一次 `make -j1 V=s` 定位真实包
- 不应出现无条件清理/重编 `xray-core`
- 自动生成 `build-diagnostics-*` Artifact

只有失败目标实际是 `xray-core` 且日志/依赖符合 gVisor Go 1.26 场景时，才允许执行对应修复。

失败诊断包应至少包含：

- `openwrt-build.log`
- `.config`
- `seed`
- `build-manifest.json`
- `build-context.txt`
- `environment.txt`
- `failed-targets/*.log`

## 5. GitHub Actions Node.js 24

本分支已将：

- `actions/checkout@v4` → `actions/checkout@v5`
- `actions/upload-artifact@v4` → `actions/upload-artifact@v7`

正常情况下不应再出现这两个官方 Action 的 Node.js 20 deprecation 警告。

## 6. 项目自检

`项目自检` workflow 应通过：

- bash -n
- ShellCheck（beta2 新增脚本）
- YAML 解析
- Node24 官方 Action 版本检查
- 两阶段交接安全检查
- beta2 编译诊断逻辑检查

Actionlint 暂为观察项（continue-on-error），先用于暴露旧 workflow 的历史问题，不在 beta2 阻断测试。
