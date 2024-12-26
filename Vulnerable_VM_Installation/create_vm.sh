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

# Detect the correct VBoxManage command
detect_vboxmanage_command() {
  if command -v vboxmanage &> /dev/null; then
    VBOXMANAGE="vboxmanage"
  elif command -v VBoxManage &> /dev/null; then
    VBOXMANAGE="VBoxManage"
  else
    print_message "red" "VBoxManage command not found."
    exit 1
  fi
}

# Check if VirtualBox is installed and if not install it
download_virtual_box() {
  if ! command -v vboxmanage &> /dev/null; then
    print_message "red" "VirtualBox is not installed."
    print_message "green" "Installing VirtualBox"
    
    # Install VirtualBox based on the system package manager
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      if [[ $NAME == "Ubuntu" || $NAME == "Debian" ]]; then
        sudo apt update
        sudo apt install -y virtualbox
        check_command "VirtualBox installation failed"
        VBOXMANAGE="vboxmanage"

      # check if os starts with openSUSE
      elif [[ $NAME =~ "openSUSE" || $NAME == "SUSE Linux Enterprise" ]]; then
        sudo zypper install -y virtualbox
        check_command "VirtualBox installation failed"
        VBOXMANAGE="VBoxManage"

      # add your OS here
      
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
    print_message "green" "Downloading Ubuntu 20.04 ISO"
    wget -c "$ISO_URL"
    check_command "Error during ISO downloading"
  else
    print_message "green" "ISO already downloaded: $DOWNLOAD_DIR/$ISO_NAME"
  fi
}

# Install virtual box and create the virtual machine
setup_vm() {
  if $VBOXMANAGE list vms | grep -q "\"$VM_NAME\""; then
    print_message "green" "Virtual machine '$VM_NAME' already exists. Skipping creation."
  else
    # Create the virtual machine in VirtualBox
    print_message "green" "Creating the virtual machine"
    $VBOXMANAGE createvm --name "$VM_NAME" --ostype Ubuntu_64 --register
    check_command "VM creation failed."

    # Configure the virtual machine
    print_message "green" "Setting up the virtual machine"
    $VBOXMANAGE modifyvm "$VM_NAME" \
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
    $VBOXMANAGE createhd --filename "$VM_DIR/$VM_NAME.vdi" --size 61440
    check_command "Virtual disk creation failed."

    # Attach the disk and ISO file
    $VBOXMANAGE storagectl "$VM_NAME" --name "SATA Controller" --add sata --controller IntelAhci
    $VBOXMANAGE storageattach "$VM_NAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$VM_DIR/$VM_NAME.vdi"
    check_command "Disk attachment failed."

    $VBOXMANAGE storagectl "$VM_NAME" --name "IDE Controller" --add ide
    $VBOXMANAGE storageattach "$VM_NAME" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "$DOWNLOAD_DIR/$ISO_NAME"
    check_command "ISO file attachment failed."
  fi
}

# Attach the correct version of Guest Additions ISO
get_guest_additions_iso() {
  # Get the VirtualBox version
  local vb_version
  vb_version=$($VBOXMANAGE --version | cut -d '_' -f 1)
  check_command "Failed to retrieve VirtualBox version."

  # Set download URL
  local iso_name="VBoxGuestAdditions_$vb_version.iso"
  local iso_url="https://download.virtualbox.org/virtualbox/$vb_version/$iso_name"
  local iso_path="$DOWNLOAD_DIR/$iso_name"

  # Check if ISO is already downloaded
  if [ ! -f "$iso_path" ]; then
    print_message "green" "Downloading Guest Additions ISO for VirtualBox $vb_version"
    wget -O "$iso_path" "$iso_url"
    check_command "Failed to download Guest Additions ISO."
  else
    print_message "green" "Guest Additions ISO already downloaded: $iso_path"
  fi

  # Attach the ISO to the VM
  print_message "green" "Attaching Guest Additions ISO"
  $VBOXMANAGE storageattach "$VM_NAME" \
    --storagectl "IDE Controller" \
    --port 1 --device 0 \
    --type dvddrive \
    --medium "$iso_path"
  check_command "Failed to attach Guest Additions ISO."
}

# Start the VM
start_vm() {
  echo ""
  read -p "[?] Do you want to start the virtual machine now? (Y/n): " user_input
  if [[ "$user_input" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    print_message "green" "Starting the virtual machine"
    $VBOXMANAGE startvm "$VM_NAME" --type gui
    check_command "VM start failed."

    print_message "green" "Virtual machine started successfully!"
  else
    print_message "green" "Virtual machine setup complete. You can start it manually later."
  fi
}


# ---------------------------------------------------------------------------------------------------------
detect_vboxmanage_command
download_virtual_box
download_iso_ubuntu
setup_vm
get_guest_additions_iso
start_vm