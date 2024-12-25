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

## Setting up environment
Each folder contains the script to set up the virtual machine in order to exploit the vulnerability and the PoC written in Rust. 
