# Running with Electron Chrome sandboxing enabled

For simplicity and because of the security offered by containers and orchestrators we leverage the `--no-sandbox` Chrome flag.  This is also possible because we don't load any external site url/content but only local application code. 

Doing so allows us to remove the need for providing the **securityPolicies.json** file as a seccomp profile, as we used to do previously when running Hackolade cli docker image.  Having to use this security profile **may be problematic** in some security contexts.

If you prefer to still enable Chrome sandboxing, you can do like following by enabling and using **WITH_SANDBOXING** environment variable and making sure you are using the [**securityPolicies.json**](../securityPolicies.json) file security profile.

```bash
docker compose run --rm -e WITH_SANDBOXING=true hackoladeStudioCLI <command>
```