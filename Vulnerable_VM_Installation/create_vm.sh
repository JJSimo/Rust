#!/bin/bash

# Name of the ISO file and download URL
ISO_NAME="ubuntu-20.04.6-desktop-amd64.iso"
ISO_URL="https://releases.ubuntu.com/20.04/$ISO_NAME"
DOWNLOAD_DIR="$HOME/Downloads"
VM_NAME="Vulnerable_Ubuntu_20.04"
VM_DIR="$HOME/VirtualBox VMs/$VM_NAME"

# Function to check the previous command
check_command() {
  if [ $? -ne 0 ]; then
    echo -e "\e[31m[!] Error: $1\e[0m"
    exit 1
  fi
}

# Check if VirtualBox is installed
if ! command -v vboxmanage &> /dev/null; then
  echo -e "\e[31m[!] VirtualBox is not installed.\e[0m"
  echo -e "\e[32m[*] Installing VirtualBox...\e[0m"
  
  # Install VirtualBox based on the system package manager
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ $NAME == "Ubuntu" || $NAME == "Debian" ]]; then
      sudo apt update
      sudo apt install -y virtualbox
      check_command "VirtualBox installation failed"
    elif [[ $NAME == "openSUSE" || $NAME == "SUSE Linux Enterprise" ]]; then
      sudo zypper install -y virtualbox
      check_command "VirtualBox installation failed"
    else
      echo -e "\e[31m[!] Unsupported OS for automatic installation.\e[0m"
      exit 1
    fi
  else
    echo -e "\e[31m[!] Could not detect the operating system.\e[0m"
    exit 1
  fi
else
  echo -e "\e[32m[*] VirtualBox is already installed\e[0m"
fi

# Download Ubuntu ISO
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

if [ ! -f "$ISO_NAME" ]; then
  echo -e "\e[32m[*] Downloading Ubuntu 20.04 ISO...\e[0m"
  wget -c "$ISO_URL"
  check_command "Error during ISO downloading"
else
  echo -e "\e[32m[*] ISO already downloaded:\e[0m $DOWNLOAD_DIR/$ISO_NAME"
fi

# Check if the virtual machine already exists
if vboxmanage list vms | grep -q "\"$VM_NAME\""; then
  echo -e "\e[32m[*] Virtual machine '$VM_NAME' already exists. Skipping creation.\e[0m"
else
  # Create the virtual machine in VirtualBox
  echo -e "\e[32m[*] Creating the virtual machine...\e[0m"
  vboxmanage createvm --name "$VM_NAME" --ostype Ubuntu_64 --register
  check_command "VM creation failed."

  # Configure the virtual machine
  echo -e "\e[32m[*] Setting up the virtual machine...\e[0m"
  vboxmanage modifyvm "$VM_NAME" \
    --memory 8192 \
    --cpus 6 \
    --nic1 nat \
    --boot1 dvd \
    --vrde on \
    --graphicscontroller vmsvga
  check_command "VM configuration failed."

  # Create a virtual disk
  echo -e "\e[32m[*] Creating virtual disk (60 GB)\e[0m"
  vboxmanage createhd --filename "$VM_DIR/$VM_NAME.vdi" --size 61440 
  check_command "Virtual disk creation failed."

  # Attach the disk and ISO file
  vboxmanage storagectl "$VM_NAME" --name "SATA Controller" --add sata --controller IntelAhci
  vboxmanage storageattach "$VM_NAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$VM_DIR/$VM_NAME.vdi"
  check_command "Disk attachment failed."

  vboxmanage storagectl "$VM_NAME" --name "IDE Controller" --add ide
  vboxmanage storageattach "$VM_NAME" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "$DOWNLOAD_DIR/$ISO_NAME"
  check_command "ISO file attachment failed."
fi

# Start the VM
echo -e "\e[32m[*] Starting the virtual machine...\e[0m"
vboxmanage startvm "$VM_NAME" --type gui
check_command "VM start failed."

echo -e "\e[32m[*] Virtual machine created and started successfully!\e[0m"