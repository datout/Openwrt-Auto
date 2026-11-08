#!/usr/bin/env bash
set -euo pipefail

: "${HOME_PATH:?HOME_PATH is required}"
: "${FIRMWARE_PATH:?FIRMWARE_PATH is required}"

CFG="${HOME_PATH}/.config"

if [[ ! -f "${CFG}" ]]; then
  echo "::warning::未找到 .config，跳过 ESXi VMDK 生成"
  exit 0
fi

if ! grep -qx 'CONFIG_TARGET_x86_64=y' "${CFG}"; then
  echo "非 x86_64 目标，跳过 ESXi VMDK 生成"
  exit 0
fi

command -v qemu-img >/dev/null 2>&1 || {
  echo "::error::未找到 qemu-img，无法生成 ESXi VMDK"
  exit 1
}

shopt -s nullglob
images=("${FIRMWARE_PATH}"/*combined-efi.img.gz)
shopt -u nullglob

if (( ${#images[@]} != 1 )); then
  echo "::error::x86_64 编译完成后未找到唯一的 combined-efi.img.gz（找到 ${#images[@]} 个）"
  printf '  %s\n' "${images[@]:-（无）}"
  exit 1
fi

source_gz="${images[0]}"
source_img="${source_gz%.gz}"
base="${source_img%.img}"
descriptor="${base}-ESXi.vmdk"
flat="${base}-ESXi-flat.vmdk"

tmp_img="${source_img}.tmp"

cleanup() {
  rc=$?
  rm -f "${source_img}" "${tmp_img}"
  if (( rc != 0 )); then
    rm -f "${descriptor}" "${flat}"
  fi
  exit "${rc}"
}
trap cleanup EXIT

rm -f "${source_img}" "${tmp_img}" "${descriptor}" "${flat}"

echo "生成 ESXi VMDK：$(basename "${source_gz}")"
set +e
gzip -dc -- "${source_gz}" > "${tmp_img}"
gzip_rc=$?
set -e

case "${gzip_rc}" in
  0)
    ;;
  2)
    echo "::warning::gzip 返回警告（exit 2，通常为 trailing garbage）；解压数据已生成，将继续校验并转换"
    ;;
  *)
    echo "::error::EFI 镜像解压失败，gzip exit=${gzip_rc}"
    exit "${gzip_rc}"
    ;;
esac

[[ -s "${tmp_img}" ]] || {
  echo "::error::EFI 镜像解压结果为空"
  exit 1
}

mv -f "${tmp_img}" "${source_img}"

qemu-img convert -p \
  -f raw \
  -O vmdk \
  -o adapter_type=lsilogic,subformat=monolithicFlat \
  "${source_img}" "${descriptor}"

rm -f "${source_img}"

[[ -s "${descriptor}" ]] || {
  echo "::error::ESXi VMDK 描述文件生成失败"
  exit 1
}
[[ -s "${flat}" ]] || {
  echo "::error::ESXi VMDK 数据文件生成失败"
  exit 1
}

descriptor_info="$(qemu-img info "${descriptor}")"
grep -q 'file format: vmdk' <<<"${descriptor_info}"
grep -q 'create type: monolithicFlat' <<<"${descriptor_info}"
grep -q 'adapter type: lsilogic' <<<"${descriptor_info}"

flat_info="$(qemu-img info "${flat}")"
grep -q 'file format: raw' <<<"${flat_info}"

echo "ESXi VMDK 生成完成："
ls -lh "${descriptor}" "${flat}"
