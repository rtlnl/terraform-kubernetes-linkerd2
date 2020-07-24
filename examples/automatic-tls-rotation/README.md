# Automatic TLS rotation

This is an opinionated way of doing automatic rotation of the TLS certificates for the controlplane components. We encourage to read the official Linkerd2 [documentation](https://linkerd.io/2/tasks/automatically-rotating-control-plane-tls-credentials/) about the subject. There are two steps to do:

1. Creating a signing-key pair
2. Push the certificate to Vault (or another system that Terraform has access to)

For the sake of the tutorial, we assume that you can push them to `Vault` and that you have `cert-manager` installed in your cluster (or you can install it in this tutorial).

You need to create the signing-key pair. As the above documentation says, you can use the following command for a long-living certificate

```bash
$: step certificate create identity.linkerd.cluster.local ca.crt ca.key --profile root-ca --no-password --insecure --not-after=87600h
```

After that, two files (`ca.crt` and `ca.key`) have been generated. Now, push those to Vault and change the `path = "path/to/your/linkerd/certs"` in `data.tf`. Make sure that the following two lines are correct for your case

```yaml
"tls.crt" = data.vault_generic_secret.linkerd.data["ca.crt"]
"tls.key" = data.vault_generic_secret.linkerd.data["ca.key"]
```

Now, you can run the whole `main.tf` and it should be able to automatically fetch the certificates from Vault, the `cert-manager` will create the `Certificates` in the secret called `linkerd-identity-issuer` and the `identity` component will automatically read the secret and dispatch it to the other services.