resource "azurerm_resource_group" "vmss-fc" {

  name     = "RG-FC"
  location = "francecentral"
  tags     = {
    owner = "rpo"
    workload = "backend"
    region = "FC"
  }
}

resource "azurerm_virtual_network" "vmss-fc" {
  
  name                = "VNET-fc"
  resource_group_name = azurerm_resource_group.vmss-fc.name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.vmss-fc.location
  tags                = azurerm_resource_group.vmss-fc.tags
}

resource "azurerm_subnet" "vmss-fc" {

  name                 = "Public-subnet"
  resource_group_name  = azurerm_resource_group.vmss-fc.name
  virtual_network_name = azurerm_virtual_network.vmss-fc.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "vmss-fc" {
  
  name                = "NSG-fc"
  resource_group_name = azurerm_resource_group.vmss-fc.name
  location            = azurerm_resource_group.vmss-fc.location
  tags                = azurerm_resource_group.vmss-fc.tags
}

resource "azurerm_network_security_rule" "http-vmss-fc" {
  
  name                        = "http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.vmss-fc.name
  network_security_group_name = azurerm_network_security_group.vmss-fc.name
}

resource "azurerm_network_security_rule" "https-vmss-fc" {
  
  name                        = "https"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.vmss-fc.name
  network_security_group_name = azurerm_network_security_group.vmss-fc.name
}

resource "azurerm_subnet_network_security_group_association" "fc" {

  subnet_id                 = azurerm_subnet.vmss-fc.id
  network_security_group_id = azurerm_network_security_group.vmss-fc.id
}

resource "azurerm_linux_virtual_machine_scale_set" "fc" {

  name                            = "vmss-fc-fc"
  resource_group_name             = azurerm_resource_group.vmss-fc.name
  location                        = azurerm_resource_group.vmss-fc.location
  sku                             = "Standard_B1s"
  computer_name_prefix            = "vm-vmss-fc-fc"
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
    name    = "nic-vmss-fc-fc"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.vmss-fc.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.fc.id]
    }
  }
}

resource "azurerm_monitor_autoscale_setting" "fc" {
  
  name                = "autoscale-vmss-fc"
  resource_group_name = azurerm_resource_group.vmss-fc.name
  location            = azurerm_resource_group.vmss-fc.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.fc.id

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
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.fc.id
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
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.fc.id
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