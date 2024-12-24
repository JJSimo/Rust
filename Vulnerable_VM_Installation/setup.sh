#!/bin/bash

# Name of the ISO file and download URL
ISO_NAME="ubuntu-20.04.6-desktop-amd64.iso"
ISO_URL="https://releases.ubuntu.com/20.04/$ISO_NAME"
DOWNLOAD_DIR="$HOME/Downloads"
VM_NAME="Ubuntu_20.04_VM"
VM_DIR="$HOME/VirtualBox VMs/$VM_NAME"

# Function to check the previous command
check_command() {
  if [ $? -ne 0 ]; then
    echo -e "\e[31m[!] Error: $1\e[0m"
    exit 1
  fi
}

# Download Ubuntu ISO
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

if [ ! -f "$ISO_NAME" ]; then
  echo "[*] Downloading Ubuntu 20.04 ISO..."
  wget -c "$ISO_URL"
  check_command "Error during ISO downloading"
else
  echo "[*] ISO already downloaded: $DOWNLOAD_DIR/$ISO_NAME"
fi

# Create the virtual machine in VirtualBox
echo "[*] Creating the virtual machine"
vboxmanage createvm --name "$VM_NAME" --ostype Ubuntu_64 --register
check_command "VM creation failed."

# Configure the virtual machine
echo "[*] Setting up the virtual machine"
vboxmanage modifyvm "$VM_NAME" \
  --memory 2048 \
  --cpus 2 \
  --nic1 nat \
  --boot1 dvd \
  --vrde on \
  --graphicscontroller vmsvga
check_command "VM configuration failed."

# Create a virtual disk
echo "[*] Creating virtual disk..."
vboxmanage createhd --filename "$VM_DIR/$VM_NAME.vdi" --size 20000
check_command "Virtual disk creation failed."

# Attach the disk and ISO file
vboxmanage storagectl "$VM_NAME" --name "SATA Controller" --add sata --controller IntelAhci
vboxmanage storageattach "$VM_NAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$VM_DIR/$VM_NAME.vdi"
check_command "Disk attachment failed."

vboxmanage storagectl "$VM_NAME" --name "IDE Controller" --add ide
vboxmanage storageattach "$VM_NAME" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "$DOWNLOAD_DIR/$ISO_NAME"
check_command "ISO file attachment failed."

# Start the VM
echo "[*] Starting the virtual machine..."
vboxmanage startvm "$VM_NAME" --type gui
check_command "VM start failed."

echo -e "\e[32m[*] Virtual machine created and started successfully!\e[0m"
