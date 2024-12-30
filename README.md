# PoCES
PoC Exploits Scripting 

## Creating LAB
Inside the `Vulnerable_VM_Installation` folder there is a script `create_vm.sh` that automatically:
- downloads the Ubuntu 20.04 ISO
- downloads virtual box (if not installed)
- downloads the virtual box guest additions
- creates the `Vulnerable_Ubuntu_20.04` virtual machine inside "`$HOME/VirtualBox VMs/`" folder

After installing Ubuntu in the virtual machine:
- mount the guest additions
- open it in the terminal and type `sudo ./VBoxLinuxAdditions.run`

> [!WARNING]
> OSs supported by the `create_vm.sh` script are Ubuntu like distros and openSUSE.
> If you want to add your OS, edit the `download_virtual_box()` function and add the corresponding `elif then` block 😊


VM setup:
- hard disk: 60 GB
- RAM: 8 GB
- CPUs: 6
- VRAM: 128 MB
- Network: bridge

If you want to modify VM specs, edit the `setup_vm()` function.

## Setting up environment
Each folder contains the script to set up the virtual machine in order to exploit the vulnerability and the PoC written in Rust. 
