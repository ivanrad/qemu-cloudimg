#!/usr/bin/env bash

set -eu

base_image="$1"
uniq_id=$(mktemp --dry-run XXXX)
image_name="${base_image##*/}"
image_name="${image_name%.img}"
image_name="${image_name##*/}.${uniq_id}.qcow2"
seed_image="seed.${uniq_id}.iso"
image_size="5G"
ram_size=1024
# forward to guest tcp/22
hostfwd_ssh_port=2122

# build seed ISO
mkisofs -quiet -joliet -rock -l -volid cidata -output "$seed_image" ./seed/meta-data ./seed/user-data

# make a new qcow2 image with a backing base image
qemu-img create -b "$1" -f qcow2 "$image_name" "$image_size"

qemu-system-x86_64 \
    -enable-kvm \
    -m $ram_size \
    -vga none \
    -nographic \
    -display none \
    -serial mon:stdio \
    -device virtio-net,netdev=n0 \
    -netdev user,id=n0,hostfwd=tcp::${hostfwd_ssh_port}-:22 \
    -device virtio-scsi-pci,id=scsi \
    -device scsi-hd,drive=hd \
    -drive file="$image_name",media=disk,index=0,id=hd,if=none,format=qcow2 \
    -cdrom "$seed_image"
