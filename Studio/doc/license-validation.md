# How to validate a concurrent Hackolade license

## Online, if your are connected to the internet

Use the following command to validate your license in one go:
```bash
docker compose run --rm hackoladeStudioCLI validatekey \
            --key=<concurrent-license-key> \
            --identifier=$(docker compose run --rm --entrypoint show-computer-id.sh hackoladeStudioCLI)

```

## Without Internet connection (offline)

If your server has no Internet connection, it is necessary to do an offline validation of your license key.  The process is as follows:

1. Fetch the UUID from the docker image you built: 
    ```bash
    docker compose run --rm --entrypoint show-computer-id.sh hackoladeStudioCLI
    ```
2. From the browser of a computer with Internet access, go to this page: [https://quicklicensemanager.com/hackolade/QlmCustomerSite](https://quicklicensemanager.com/hackolade/QlmCustomerSite)

    <img src="../lib/Offline_license_activation.png" style="zoom:50%;" />

    - enter your license key in the "Activation Key" field
    - select the version "Hackolade 5.0" or above
    - enter the UUID fetched above in the "Computer ID" field
    - make sure to check the options "Generate a license file" and "I consent to the Privacy Policy"
    - click the Activate button

    A file **LicenseFile.xml** will be generated and downloaded by your browser.  Do NOT edit or alter the content of the file as it contains integrity validation to prevent abuse.  

3. copy the **LicenseFile.xml** to your server aside the **docker-compose.yml** file.

4. Validate the license key the command in the SAME image as was used in step 1 while providing the LicenseFile.xml to the container, here with a bind mount in the following example.

   ```bash
    docker compose run --rm -v ${PWD}/LicenseFile.xml:/LicenseFile.xml hackoladeStudioCLI validatekey \
        --key=<concurrent-license-key> \
        --file=/LicenseFile.xml
    ```

    If you get the error message `Your computer ID does not match the activation key information on our license server`, it means that you failed to use the same image in steps 1 and 4, resulting in unmatched UUID's.

**Important:** If your docker-compose.yml subfolder volumes configuration is different than the example above, please make sure to adjust the path accordingly.  The **--file** argument is a path **inside** the container.

**Note:** The entire above process must be repeated for each new Docker image as the UUID changes with each creation.
