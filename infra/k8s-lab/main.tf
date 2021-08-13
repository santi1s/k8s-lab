provider "azurerm" {
  features {}
  subscription_id = "<SUBSCRIPTION_ID>"
  client_id       = "<SP_CLIENT_APP_ID"
  client_secret   = "<SP_SECRET>"
  tenant_id       = "<TENANT_ID>"
}


# randomize some things
resource "random_integer" "random_int" {
    min = 100
    max = 999
}

# ************************** Terraform Bootcamp **************************** #
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group}"
  location = "${var.location}"
}

# ***************************** VNET / SUBNET ****************************** #
resource "azurerm_virtual_network" "vnet" {
  name                = "${azurerm_resource_group.rg.name}-vnet"
  location            = "${var.location}"
  address_space       = ["${var.address_space}"]
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_subnet" "mgmt-subnet" {
  name                 = "${azurerm_resource_group.rg.name}-mgmt-subnet"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefixes     = ["${var.mgmt-subnet_prefix}"]
}


# ********************** NETWORK SECURITY GROUP **************************** #
resource "azurerm_network_security_group" "mgmt-nsg" {
  name                = "${azurerm_resource_group.rg.name}-mgmt-nsg"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"

  security_rule {
    name                       = "allow-ssh"
    description                = "Allow SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}


# ************************** NETWORK INTERFACES **************************** #
resource "azurerm_network_interface" "nic" {
  name                = "${azurerm_resource_group.rg.name}-nic"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "${var.hostname}-ipconfig"
    subnet_id                     = "${azurerm_subnet.mgmt-subnet.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.pip.id}"
  }
}

# ************************** PUBLIC IP ADDRESSES **************************** #
resource "azurerm_public_ip" "pip" {
  name                         = "${azurerm_resource_group.rg.name}-pip"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  allocation_method            = "Dynamic"
  domain_name_label            = "${var.hostname}${random_integer.random_int.result}"
}

# ***************************** STORAGE ACCOUNT **************************** #
resource "azurerm_storage_account" "stor" {
  name                     = "${var.hostname}stor"
  location                 = "${var.location}"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  account_tier             = "${var.storage_account_tier}"
  account_replication_type = "${var.storage_replication_type}"
}

resource "azurerm_managed_disk" "datadisk" {
  name                 = "${var.hostname}-datadisk"
  location             = "${var.location}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "128"
}

# ***************************** VIRTUAL MACHINE **************************** #
resource "azurerm_virtual_machine" "vm" {
  name                  = "${azurerm_resource_group.rg.name}-vm"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  vm_size               = "${var.vm_size}"
  network_interface_ids = ["${azurerm_network_interface.nic.id}"]


  delete_os_disk_on_termination = true

  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "${var.image_publisher}"
    offer     = "${var.image_offer}"
    sku       = "${var.image_sku}"
    version   = "${var.image_version}"
  }

  storage_os_disk {
    name              = "${var.hostname}-osdisk"
    managed_disk_type = "Standard_LRS"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  storage_data_disk {
    name              = "${var.hostname}-datadisk"
    managed_disk_id   = "${azurerm_managed_disk.datadisk.id}"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = "128"
    create_option     = "Attach"
    lun               = 0
  }

  os_profile {
    computer_name  = "${var.hostname}"
    admin_username = "${var.admin_username}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${file("~/.ssh/id_rsa.pub")}"
    }
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = "${azurerm_storage_account.stor.primary_blob_endpoint}"
  }
}

resource "azurerm_virtual_machine_extension" "CSE-k8s" {
  name                 = "CustomScriptExtension"
  virtual_machine_id   = "${azurerm_virtual_machine.vm.id}"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  depends_on           = [azurerm_virtual_machine.vm]

  settings = <<SETTINGS
    {
        "fileUris": [
        "https://raw.githubusercontent.com/santi1s/k8s-lab/master/scripts/0_vm-setup.sh"
        ],
        "commandToExecute": "bash 0_vm-setup.sh"
    }
SETTINGS
}
