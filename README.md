# tinychameleon.com

The complete source code and content of https://tinychameleon.com.

The build steps within this repository are only tested on MacOS; they are
almost guaranteed to be tied to the ecosystem, as they use `brew` liberally.


## Development

This project is built using Jekyll and rbenv; the required ruby and bundler
versions are specified in the [Makefile](Makefile).

To locally serve the website, run either `make` or `make serve`. Dependencies
will be installed, and marked as such, automatically.

To destroy generated site content use `make clean`.
