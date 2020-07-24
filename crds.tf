data "template_file" "crds" {
  template = file("${path.module}/templates/crds.yaml")
}

resource "null_resource" "crds" {

  triggers = {
    manifest_sha1 = sha1("${data.template_file.crds.rendered}")
  }

  provisioner "local-exec" {
    command = "kubectl apply -f - <<EOF\n${data.template_file.crds.rendered}\nEOF"
  }

  provisioner "local-exec" {
    when = "destroy"
    command = "kubectl delete -f - <<EOF\n${data.template_file.crds.rendered}\nEOF"
  }
}
