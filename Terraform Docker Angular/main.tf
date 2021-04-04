variable "name" {}
variable "vmsize" {}
variable "vnetaddrspace" {}
variable "subnetprefix" {}
variable "vmsshpublickey" {}
variable "vmsshprivatekey" {}
variable "githubsshprivatekey" {}
variable "initscript" {}
variable "sshconf" {}
variable "vscodesshpublickey" {}

# Configure the Azure provider
provider "azurerm" {
    version="=2.20.0"
    features {}
}

# Create a new resource group
resource "azurerm_resource_group" "rg" {
    name     = var.name
    location = "francecentral"
}

# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
    name                = "${var.name}VirtualNetwork"
    address_space       = var.vnetaddrspace
    location            = "francecentral"
    resource_group_name = azurerm_resource_group.rg.name
}


# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.name}Subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnetprefix
}

# Create public IP
resource "azurerm_public_ip" "publicip" {
  name                = "${var.name}PublicIP"
  location            = "francecentral"
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  domain_name_label   = "your name-${var.name}"
}


# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.name}NSG"
  location            = "francecentral"
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Port_8080"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Port_4200"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "4200"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

# Create network interface
resource "azurerm_network_interface" "nic" {
  name                      = "${var.name}NIC"
  location                  = "francecentral"
  resource_group_name       = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${var.name}NICConfg"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }

}

resource "azurerm_network_interface_security_group_association" "nic-nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Create a Linux virtual machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                            = var.name
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  network_interface_ids           = [azurerm_network_interface.nic.id]
  size                            = var.vmsize
  admin_username                  = "your name"
  computer_name                   = var.name
  disable_password_authentication = true

  admin_ssh_key {
    username   = "your name"
    public_key = file(var.vmsshpublickey)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  depends_on = [azurerm_network_interface_security_group_association.nic-nsg]
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "example" {
  virtual_machine_id    = azurerm_linux_virtual_machine.vm.id
  location              = azurerm_resource_group.rg.location
  enabled               = true
  daily_recurrence_time = "0100"
  timezone              = "Romance Standard Time"

  notification_settings {
    enabled = false
  }

}

# Files 
resource "null_resource" "init-script" {

  provisioner "local-exec" {
    command = "echo ${azurerm_public_ip.publicip.fqdn} > ${var.name}/fqdn"
  }

  provisioner "file" {
    source      = var.initscript
    destination = "init.sh"

    connection {
      type        = "ssh"
      user        = "your name"
      private_key = file(var.vmsshprivatekey)
      host        = azurerm_public_ip.publicip.fqdn
    }
  }

  provisioner "file" {
    source      = var.sshconf
    destination = ".ssh/config"

    connection {
      type        = "ssh"
      user        = "your name"
      private_key = file(var.vmsshprivatekey)
      host        = azurerm_public_ip.publicip.fqdn
    }
  }

  provisioner "file" {
    source      = var.githubsshprivatekey
    destination = ".ssh/GithubPrivateKey"

    connection {
      type        = "ssh"
      user        = "your name"
      private_key = file(var.vmsshprivatekey)
      host        = azurerm_public_ip.publicip.fqdn
    }
  }

  provisioner "file" {
    source      = var.vscodesshpublickey
    destination = ".ssh/VsCodePublicKey"

    connection {
      type        = "ssh"
      user        = "your name"
      private_key = file(var.vmsshprivatekey)
      host        = azurerm_public_ip.publicip.fqdn
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x init.sh",
      "./init.sh"
    ]

    connection {
      type        = "ssh"
      user        = "your name"
      private_key = file(var.vmsshprivatekey)
      host        = azurerm_public_ip.publicip.fqdn
    }

  }

  depends_on = [
    azurerm_linux_virtual_machine.vm
  ]

}
