# tinychameleon.com

The complete source code and content of https://tinychameleon.com.

The build steps within this repository are only tested on MacOS; they are
almost guaranteed to be tied to the ecosystem, as they use `brew` liberally
and do not consider Linux at all.

## Managing Posts

New posts can be created using the `scripts/hugo` script, or if `direnv` is
installed, simply `hugo`. This script simply proxies normal Hugo commands
into a containerized version of Hugo for easier dependency management.


## Development

This project is built using Hugo and Docker; the [Makefile](Makefile) default
target is the `server` recipe which runs a local development server.

Manual installation of dependencies can be done via `make deps`, but they are
also installed by default via the `server` recipe.


## Deployment

All deployments for this website rely on the Azure command line tool to copy
data into blob storage. The installation of the tool is handled automatically
during `make deps`.

The website infrastructure can be deployed to Azure using `make infra`, but
note that Azure Deployment Manager does not support all the necessary pieces
for activating static website hosting. To set up the infrastructure, these
steps will need to be taken:

1. run the `infra` recipe and wait for the deployment to complete;
2. activate the storage account static website hosting via the Azure web portal;
3. create a CloudFlare proxy record via the web portal which points to the
   storage account static website address.

Publishing the website content is done via `make deploy`; a production build
and infrastructure changes will be automatically run if necessary.

Builds can be run manually via `make build` and removed via `make clean`.


### Required Configuration

There are a few required configuration values, which depend on what recipes
are being run. The Makefile will error if a recipe requires a missing value.

The current required configuration values are:
- `AZ_RESOURCE_GROUP` &mdash; The Azure resource group name;
- `AZ_STORAGE_ACCOUNT` &mdash; The Azure storage account name;
- `AZ_DEPLOYMENT_NAME` &mdash; The Azure resource group deployment name;
- `CLOUDFLARE_API_TOKEN` &mdash; The CloudFlare API bearer token for authentication;
- `CLOUDFLARE_ZONE_ID` &mdash; The domain zone within CloudFlare


### Infrastructure Trade Offs

The notable trade-off with this infrastructure approach is the website does not
have its own SSL certificate. CloudFlare's free SSL option uses shared
certificates across a handful of sites. This group of sites has the ability to
spy on each other's requests. At this time, this is of sufficiently low danger
that it is not considered a threat to reader privacy.

In exchange for this certificate sharing the website:

1. is protected from attacks without my active involvement in mitigation;
2. can utilize apex domain name flattening to host no-www and mx records;
3. can redirect www subdomain to apex.

At this point these free features are a large benefit compared to the small
risk of the shared certificate.


## Licensing

Website content and content source files are
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) licensed.
Supporting code to build, develop, and deploy the website is
[BSD 3-Clause](./LICENSE) licensed.
