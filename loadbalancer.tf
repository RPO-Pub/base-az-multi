resource "azurerm_resource_group" "lb" {
  name     = "RG-LoadBalancer"
  location = "francecentral"
  tags =   {
    owner = "rpo"
    workload = "frontend"
  }
}

resource "azurerm_public_ip" "lb" {
  name                = "PIP-LoadBalancer"
  resource_group_name = azurerm_resource_group.lb.name
  location            = azurerm_resource_group.lb.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = azurerm_resource_group.lb.tags
}

resource "azurerm_lb" "this" {
  name                = "LB-frontend"
  resource_group_name = azurerm_resource_group.lb.name
  location            = azurerm_resource_group.lb.location
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
  tags = azurerm_resource_group.lb.tags
}

resource "azurerm_lb_probe" "this" {
  name            = "LB-HealthProbe"
  loadbalancer_id = azurerm_lb.this.id
  protocol        = "Tcp"
  port            = 80
}

resource "azurerm_lb_backend_address_pool" "fc-frontend" {
  name            = "LB-BackendPool-fc"
  loadbalancer_id = azurerm_lb.this.id

}

resource "azurerm_lb_backend_address_pool" "we-frontend" {
  name            = "LB-BackendPool-we"
  loadbalancer_id = azurerm_lb.this.id

}
/*
resource "azurerm_lb_backend_address_pool_address" "fc-frontend" {
  name = "Address-fc"
  virtual_network_id = azurerm_virtual_network.vmss-fc.id
  ip_address      = azurerm_public_ip.fc.ip_address
  backend_address_pool_id = azurerm_lb_backend_address_pool.fc-frontend.id
}

resource "azurerm_lb_backend_address_pool_address" "we-frontend" {
  name = "Address-we"
  virtual_network_id = azurerm_virtual_network.vmss-we.id
  ip_address      = azurerm_public_ip.we.ip_address
  backend_address_pool_id = azurerm_lb_backend_address_pool.we-frontend.id
}*/