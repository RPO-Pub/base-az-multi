resource "azurerm_public_ip" "fc" {
    
    name                = "PIP-fc"
    resource_group_name = azurerm_resource_group.vmss-fc.name
    location            = azurerm_resource_group.vmss-fc.location
    allocation_method   = "Static"
    sku                 = "Standard"
    tags                = azurerm_resource_group.vmss-fc.tags
}

resource "azurerm_lb" "fc" {
  name                = "LB-fc"
  resource_group_name = azurerm_resource_group.vmss-fc.name
  location            = azurerm_resource_group.vmss-fc.location
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.fc.id
  }
  tags = azurerm_resource_group.vmss-fc.tags
}

resource "azurerm_lb_probe" "fc" {
  name            = "LB-HealthProbe-fc"
  loadbalancer_id = azurerm_lb.fc.id
  protocol        = "Tcp"
  port            = 80
}

resource "azurerm_lb_backend_address_pool" "fc" {
  name            = "LB-BackendPool-fc"
  loadbalancer_id = azurerm_lb.fc.id

}

resource "azurerm_lb_rule" "fc" {
  name                           = "LB-Rule-Http"
  loadbalancer_id                = azurerm_lb.fc.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.fc.id]
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.fc.id
}