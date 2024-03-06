resource "null_resource" "rbac"{
  provisioner "local-exec" {
    command = "az login"
  }
  provisioner "local-exec" {
    command = "az ad sp create-for-rbac --name aks-rbac --role Contributor --scopes /subscriptions/78d54a33-be25-4cad-824e-dea184279fc9 --year 100"
  }
}