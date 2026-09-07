#!/bin/bash
# Compatibility stub retained for older workflow references.
# Since V1.0.11, seed persistence is handled by seed_finalize.sh using
# Kconfig's native savedefconfig mechanism.
set -euo pipefail
printf '[seed-refresh] V1.0.11 起已改用 Kconfig minimal seed；旧 snapshot/cleanup 逻辑已停用。\n'
exit 0
