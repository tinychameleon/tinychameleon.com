# tinychameleon.com

The complete source code and content of https://tinychameleon.com.

The build steps within this repository are only tested on MacOS; they are
almost guaranteed to be tied to the ecosystem, as they use `brew` liberally
and do not consider Linux at all.

## Managing Posts

New draft posts can be created by issuing the `post` command from inside the
repository; after creating the draft file it opens it via `$EDITOR`. Once
completed, a draft can be made public by using the `publish` command; public
implies being moved to the `_posts/` directory and having the date of the post
updated in the file name and front matter.

These commands are placed onto the path by `direnv`, which is an automatically
installed dependency. Though `direnv` is not necessary, it is nice to avoid
typing the `_bin/` prefix.


## Development

This project is built using Jekyll and rbenv; the required ruby and bundler
versions are specified in the [Makefile](Makefile).

To locally serve the website, run either `make` or `make serve`. Dependencies
will be installed, and marked as such, automatically.

Manual installation of dependencies can be done via `make deps`.


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
- `AZ_DEPLOYMENT_NAME` &mdash; The Azure resource group deployment name


### Infrastructure Trade Offs

The notable trade-off with this infrastructure approach is the website does not
have its own SSL certificate. CloudFlare's free SSL option uses shared
certificates across a handful of sites. This group of sites has the ability to
spy on each other's requests. At this time, this is of sufficiently low danger
that it is not considered a threat to reader privacy.

In exchange for this certificate sharing the website:

1. is protected from attacks without my active involvement in mitigation;
2. can utilize apex domain name flattening to host no-www and mx records;
3. can redirect www to no-www.

At this point these free features are a large benefit compared to the small
risk of the shared certificate.


## Licensing

Website content and content source files are
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) licensed.
Supporting code to build, develop, and deploy the website is
[BSD 3-Clause](./LICENSE) licensed.
