ARG BITWARDEN_TAG

FROM mcr.microsoft.com/dotnet/core/sdk:3.1 as build

WORKDIR /bitBetter

COPY ./src/bitBetter /bitBetter

RUN set -e; set -x; \
	dotnet add package Newtonsoft.Json --version 12.0.3 \
	&& dotnet restore \
	&& dotnet publish

FROM ${BITWARDEN_TAG}

COPY --from=build /bitBetter/bin/Debug/netcoreapp3.1/publish/* /bitBetter/
COPY ./publicKeys/cert.cert /newLicensing.cer

RUN set -e; set -x; \
    dotnet /bitBetter/bitBetter.dll && \
    mv /app/Core.dll /app/Core.orig.dll && \
    mv /app/modified.dll /app/Core.dll && \
    rm -rf /bitBetter && rm -rf /newLicensing.cer