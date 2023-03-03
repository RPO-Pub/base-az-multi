resource "azurerm_resource_group" "vmss-we" {

  name     = "RG-we"
  location = "francecentral"
  tags     = {
    owner = "rpo"
    workload = "backend"
    region = "we"
  }
}

resource "azurerm_virtual_network" "vmss-we" {
  
  name                = "VNET-we"
  resource_group_name = azurerm_resource_group.vmss-we.name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.vmss-we.location
  tags                = azurerm_resource_group.vmss-we.tags
}

resource "azurerm_subnet" "vmss-we" {

  name                 = "Public-subnet"
  resource_group_name  = azurerm_resource_group.vmss-we.name
  virtual_network_name = azurerm_virtual_network.vmss-we.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "vmss-we" {
  
  name                = "NSG-we"
  resource_group_name = azurerm_resource_group.vmss-we.name
  location            = azurerm_resource_group.vmss-we.location
  tags                = azurerm_resource_group.vmss-we.tags
}

resource "azurerm_network_security_rule" "http-vmss-we" {
  
  name                        = "http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.vmss-we.name
  network_security_group_name = azurerm_network_security_group.vmss-we.name
}

resource "azurerm_network_security_rule" "https-vmss-we" {
  
  name                        = "https"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.vmss-we.name
  network_security_group_name = azurerm_network_security_group.vmss-we.name
}

resource "azurerm_subnet_network_security_group_association" "we" {

  subnet_id                 = azurerm_subnet.vmss-we.id
  network_security_group_id = azurerm_network_security_group.vmss-we.id
}

resource "azurerm_linux_virtual_machine_scale_set" "we" {

  name                            = "vmss-we-we"
  resource_group_name             = azurerm_resource_group.vmss-we.name
  location                        = azurerm_resource_group.vmss-we.location
  sku                             = "Standard_B1s"
  computer_name_prefix            = "vm-vmss-we-we"
  instances                       = 1
  admin_username                  = "adminuser"
  disable_password_authentication = false
  admin_password                  = "MyP4ssword8541!"

  custom_data = filebase64("cloud-init.yml")

  upgrade_mode = "Manual"

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name    = "nic-vmss-we-we"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.vmss-we.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.we.id]
    }
  }
}

resource "azurerm_monitor_autoscale_setting" "we" {
  
  name                = "autoscale-vmss-we"
  resource_group_name = azurerm_resource_group.vmss-we.name
  location            = azurerm_resource_group.vmss-we.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.we.id

  profile {
    name = "defaultProfile"

    capacity {
      default = 1
      minimum = 1
      maximum = 10
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.we.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.we.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }
}