<a href="https://github.com/alexyao2015/BitBetter/actions"><img alt="GitHub Actions Build" src="https://github.com/alexyao2015/BitBetter/workflows/BitBetter%20Image/badge.svg"></a>
<a href="https://hub.docker.com/r/yaoa/bitbetter"><img alt="Docker Pulls" src="https://img.shields.io/docker/pulls/yaoa/bitbetter.svg"></a>

# BitBetter

BitBetter is is a tool to modify Bitwarden's core dll to allow you to generate your own individual and organisation licenses. **You must have an existing installation of Bitwarden for BitBetter to modify.**

Please see the FAQ below for details on why this software was created.

_Beware! BitBetter does janky stuff to rewrite the bitwarden core dll and allow the installation of a self signed certificate. Use at your own risk!_

Credit to https://github.com/h44z/BitBetter and https://github.com/jakeswenson/BitBetter

# Refactor Notice

There was a major refactor done that improved the rebustness of the patching to
remove the need to recompile bitwarden images.

Several BREAKING changes were made:

- Previously generated certificates are no longer compatible and will need to be
  regenerated
- Previously generated licenses will need to be regenerated and installed
- Previously, the public images did not have a suffix and now will have the
  -public suffix
- patch-bitwarden-custom.sh and patch-bitwarden.sh (renamed to
  patch-bitwarden-public.sh) scripts were updated and need to be locally
  redownloaded
- This project will work for bitwarden versions 2025.7.0 and onward

# Install methods

There are two installation methods. One utilizes public licensing certificates
and keys to ease the installation and remove the need for you to manually keep
track of certificates. The custom method keeps certificates private but requires
you to generate and store them. Sinc the certificates are only used for
licensing, there is no security concerns.

It is recommended to use the public method for ease of setup.

## Install with standard bitwarden setup

The following methods detail installation of bitbetter with the standard install method

### Using Public Images

First patch the Bitwarden script to use BitBetter Images:

```bash
sudo curl -o patch-bitwarden.sh https://raw.githubusercontent.com/alexyao2015/BitBetter/public/patch-bitwarden.sh && sudo chmod 755 patch-bitwarden.sh && sudo ./patch-bitwarden.sh
```

Generate a License:

```bash
sudo docker run -it --rm -v $(pwd)/license:/bitbetter/output ghcr.io/alexyao2015/bitbetter:licensegen-public-latest
```

Updating:

```bash
sudo ./patch-bitwarden.sh
```

### Using Custom Images

Patch the Bitwarden script to use BitBetter Images (Automatically generates certificates):

```bash
sudo curl -o patch-bitwarden-custom.sh https://raw.githubusercontent.com/alexyao2015/BitBetter/public/patch-bitwarden-custom.sh && sudo chmod 755 patch-bitwarden-custom.sh && sudo ./patch-bitwarden-custom.sh
```

Generate Custom License:

```bash
sudo docker run -it --rm -v $PWD/bwdata/bitbetter/certs/bitwarden.cer:/bitbetter/certs/bitbetter.cer -v $(pwd)/license:/bitbetter/output ghcr.io/alexyao2015/bitbetter:licensegen-custom-latest
```

Updating:

```bash
sudo ./patch-bitwarden-custom.sh
```

### Updating Bitwarden and BitBetter

WARNING: This section may or may not be accurate

To update Bitwarden, ran `patch-bitwarden.sh` or `patch-bitwarden-custom.sh ` script, depending or your installation. It will rebuild the BitBetter images and automatically update Bitwarden afterwards. Docker pull errors can be ignored for api and identity images.

You can either run these scripts without providing any parameters, in interactive mode (e.g. `./patch-bitwarden.sh`) or by setting the parameters as follows, to run the script in non-interactive mode:

```bash
./patch-bitwarden.sh <bitwarden-path> <update-override>
./patch-bitwarden-custom.sh <bitwarden-path> <update-override> <regenerate-certificates>
```

`<bitwarden-path>`: The path to the directory containing your bwdata directory

`<update-override>`: If you want the docker-compose.override.yml file to be updated (either `y` or `n`)

`<regenerate-certificates>`: It you want to regenerate the custom certificates in bitwarden-path/bwdata/bitbetter (either `y` or `n`)

## Install using Bitwarden unified

Follow the [official unified installation
instructions](https://bitwarden.com/help/install-and-deploy-unified-beta), but
replace `ghcr.io/bitwarden/self-host:beta` with

```
ghcr.io/alexyao2015/bitbetter:self-host-<self_host_method>-<bitwarden_version>
```

where `<bitwarden_version>` is `latest` or the bitwarden version you want (e.g. `2025.7.0`)

### Using public images

Replace `self_host_method` with `public`.

#### Generate a License:

```bash
sudo docker run -it --rm -v $(pwd)/license:/bitbetter/output ghcr.io/alexyao2015/bitbetter:licensegen-public-<bitwarden_version>
```

### Using custom images

- Replace `self_host_method` with `custom`

- Generate certificates using

```bash
docker run --rm -v <path_to_store_certs>:/certs ghcr.io/alexyao2015/bitbetter:certificate-gen-<bitwarden_version>
```

- Mount `<path_to_store_certs>/bitbetter/certs/bitbetter.cer` to `/bitbetter/certs/bitbetter.cer` in the container.

  - For docker compose, add this to your `volumes` section

```
<path_to_store_certs>/bitbetter/certs/bitbetter.cer:/bitbetter/certs/bitbetter.cer
```

- For docker run, use the following

```
-v <path_to_store_certs>/bitbetter/certs/bitbetter.cer:/bitbetter/certs/bitbetter.cer
```

#### Generate a License:

```bash
sudo docker run -it --rm -v <path_to_store_certs>/bitbetter/certs/bitbetter.key:/bitbetter/certs/bitbetter.key -v $(pwd)/license:/bitbetter/output ghcr.io/alexyao2015/bitbetter:licensegen-custom-<bitwarden_version>
```
