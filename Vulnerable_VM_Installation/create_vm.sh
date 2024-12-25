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
    print_message "red" "Error: $1"
    exit 1
  fi
}

# Function to print messages with color
print_message() {
  local color=$1
  local message=$2

  if [ "$color" == "green" ]; then
    echo -e "\n\e[32m[*] $message\e[0m"
  elif [ "$color" == "red" ]; then
    echo -e "\n\e[31m[!] $message\e[0m"
  else
    echo -e "\n$message"
  fi
}

# Check if VirtualBox is installed and if not install it
download_virtual_box() {
  if ! command -v vboxmanage &> /dev/null; then
    print_message "red" "VirtualBox is not installed."
    print_message "green" "Installing VirtualBox..."
    
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
        print_message "red" "Unsupported OS for automatic installation."
        exit 1
      fi
    else
      print_message "red" "Could not detect the operating system."
      exit 1
    fi
  else
    print_message "green" "VirtualBox is already installed"
  fi
}


# Download Ubuntu ISO
download_iso_ubuntu(){
  mkdir -p "$DOWNLOAD_DIR"
  cd "$DOWNLOAD_DIR"

  if [ ! -f "$ISO_NAME" ]; then
    print_message "green" "Downloading Ubuntu 20.04 ISO..."
    wget -c "$ISO_URL"
    check_command "Error during ISO downloading"
  else
    print_message "green" "ISO already downloaded: $DOWNLOAD_DIR/$ISO_NAME"
  fi
}

# Install virtual box and create the virtual machine
setup_vm() {
  if vboxmanage list vms | grep -q "\"$VM_NAME\""; then
    print_message "green" "Virtual machine '$VM_NAME' already exists. Skipping creation."
  else
    # Create the virtual machine in VirtualBox
    print_message "green" "Creating the virtual machine..."
    vboxmanage createvm --name "$VM_NAME" --ostype Ubuntu_64 --register
    check_command "VM creation failed."

    # Configure the virtual machine
    print_message "green" "Setting up the virtual machine..."
    vboxmanage modifyvm "$VM_NAME" \
      --memory 8192 \
      --cpus 6 \
      --nic1 nat \
      --boot1 dvd \
      --vrde on \
      --graphicscontroller vmsvga \
      --clipboard bidirectional \
      --draganddrop bidirectional \
      --vram 128
      
    check_command "VM configuration failed."

    # Create a virtual disk
    print_message "green" "Creating virtual disk (60 GB)"
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
}

# Start the VM
start_vm(){
  print_message "green" "Starting the virtual machine..."
  vboxmanage startvm "$VM_NAME" --type gui
  check_command "VM start failed."

  print_message "green" "Virtual machine created and started successfully!"
}

# ---------------------------------------------------------------------------------------------------------
download_virtual_box
download_iso_ubuntu
setup_vm
start_vm