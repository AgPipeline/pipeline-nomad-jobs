# Deploy gantry & drone image pipeline components as Nomad jobs

Warning: This is a proof-of-concept and not ready for production!

This assumes you have the Nomad binary installed and that you have access to a 
Nomad cluster. 

For setting up your own Nomad cluster see:

- [Set up a Nomad cluster on OpenStack using Terraform](https://github.com/az-digitalag/openstack-terraform-nomad), or
- [Get started with Nomad quickly in a sandbox environment on the public cloud or on your computer.](https://github.com/hashicorp/nomad#getting-started)


## Add basic services configuration to Consul

Create Consul key/value pairs for configuring services, using
secure credentials instead of the fake ones below.

TODO: Use Vault for storing secrets!


### PostgreSQL Consul configuration

Key: `service/postgresql/environment`

Value:

```bash
POSTGRES_PASSWORD = "choose-an-actual-password-not-this-one"
```


## Start load balancer

```bash
nomad job run fabio.nomad
```


## Start standard services
 
```bash
nomad job run postgresql.nomad
nomad job run mongo.nomad
nomad job run rabbitmq.nomad
nomad job run elasticsearch.nomad
```

Make sure that you can access the services, and that they function as expected.


## Start Clowder 

```bash
nomad job run clowder.nomad
```

Make sure that you can access Clowder.


## Create Clowder account and a space

Create an account on Clowder and note the username and password, as well as
the extraction/pipeline key.

Create a space in Clowder and note the ID.


## Extractor Consul configuration

Using the Clowder account and space details from above, create a key/value pair
in Consul:  

Key: `service/bin2tif/environment`

Value: 

```bash
REGISTRATION_ENDPOINTS="http://clowder:9000/api/extractors?key=deadbeef-dead-beef-dead-deadbeefdead"
CLOWDER_SPACE="c0ff33c0ff33c0ff33c0ff33"
CLOWDER_USERNAME="you@example.com"
CLOWDER_PASSWORD="xxxxxxx"
PIPELINE_KEY="deadbeef-dead-beef-dead-deadbeefdead"
CLOWDER_USER="you@example.com"
CLOWDER_PASS="xxxxxxx"
```
 
TODO: Use Vault for storing secrets!


## Start an extractor

```bash
nomad job run bin2tif-extractor.nomad
```

Confirm that the extractor is running and has registered itself to Clowder.


## Modify Clowder space to automatically run extractor

- Navigate to the space in Clowder
- Click on the 'Extractors' link on the right menu
- Ensure the extractor is listed
- Select the 'Enabled' checkbox if it is not, and press the 'Update' button


## Test that the extractor works by loading a sample data set

Create the Nomad batch job for uploading sample data:

```bash
nomad job run pipeline-setup-example.nomad
```


In your terminal (where you're running the `nomad` binary) set the following
environment variables specifically for this sample data set:

```bash
CAPTURE_SENSOR_NAME="stereoTop"
CAPTURE_TIMESTAMP="2018-05-07__16-58-55-097"
CAPTURE_RAW_DATA_URL="https://de.cyverse.org/dl/d/00F871F7-800D-4E84-B1C0-3B15BB9DB2F4/stereoTop-2018-05-07__16-58-55-097.zip"
CAPTURE_RAW_DATA_MD5="d5ac49a9cfe509e4fb0f9bdcf8b6f83a"
```

Also set environment variables based on the Clowder configuration:

```bash
CLOWDER_BASE_URL="http://clowder:9000/"
CLOWDER_USERNAME="you@example.com"
CLOWDER_PASSWORD="xxxxxxx"
CLOWDER_SPACE="c0ff33c0ff33c0ff33c0ff33"
CLOWDER_PIPELINE_KEY="deadbeef-dead-beef-dead-deadbeefdead"
```

Also set an an environment variable for the BETYdb API key:
 
```bash
BETYDB_KEY="GET-THE-REAL-BETYDB-KEY"
```
 
Finally dispatch a job that downloads the sample data set, cleans metadata,
 and uploads it to Clowder:
 
 ```bash
nomad job dispatch -verbose \
-meta CLOWDER_BASE_URL=${CLOWDER_BASE_URL} \
-meta CLOWDER_USERNAME=${CLOWDER_USERNAME} \
-meta CLOWDER_PASSWORD=${CLOWDER_PASSWORD} \
-meta CLOWDER_SPACE=${CLOWDER_SPACE} \
-meta CAPTURE_SENSOR_NAME=${CAPTURE_SENSOR_NAME} \
-meta CAPTURE_TIMESTAMP=${CAPTURE_TIMESTAMP} \
-meta CAPTURE_RAW_DATA_URL=${CAPTURE_RAW_DATA_URL} \
-meta CAPTURE_RAW_DATA_MD5=${CAPTURE_RAW_DATA_MD5} \
-meta BETYDB_KEY=${BETYDB_KEY} \
pipeline-setup-example
```

Confirm that the job did not exit with an error, and that the data is uploaded
and extracted as expected.

 