resource "azurerm_public_ip" "we" {
    
    name                = "PIP-we"
    resource_group_name = azurerm_resource_group.vmss-we.name
    location            = azurerm_resource_group.vmss-we.location
    allocation_method   = "Static"
    sku                 = "Standard"
    tags                = azurerm_resource_group.vmss-we.tags
}

resource "azurerm_lb" "we" {
  name                = "LB-we"
  resource_group_name = azurerm_resource_group.vmss-we.name
  location            = azurerm_resource_group.vmss-we.location
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.we.id
  }
  tags = azurerm_resource_group.vmss-we.tags
}

resource "azurerm_lb_probe" "we" {
  name            = "LB-HealthProbe-we"
  loadbalancer_id = azurerm_lb.we.id
  protocol        = "Tcp"
  port            = 80
}

resource "azurerm_lb_backend_address_pool" "we" {
  name            = "LB-BackendPool-we"
  loadbalancer_id = azurerm_lb.we.id

}

resource "azurerm_lb_rule" "we" {
  name                           = "LB-Rule-Http"
  loadbalancer_id                = azurerm_lb.we.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.we.id]
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.we.id
}