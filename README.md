# tinychameleon.com

The complete source code and content of https://tinychameleon.com.

The build steps within this repository are only tested on MacOS; they are
almost guaranteed to be tied to the ecosystem, as they use `brew` liberally
and do not consider Linux at all.


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
for activating static website hosting. The static website hosting must be
manually activated via the Azure portal.

Custom domain name support is still required for the Azure infrastructure code
to be considered complete.

Publishing the website content is not complete; it currently has no Makefile
recipe.

Builds can be run manually via `make build` and removed via `make clean`.
