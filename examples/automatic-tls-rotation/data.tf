data "vault_generic_secret" "linkerd" {
  path = "path/to/your/linkerd/certs"
}

data "template_file" "trust_anchor" {
  template = file("./templates/trust_anchor.yaml")
}