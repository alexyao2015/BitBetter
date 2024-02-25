ARG BITWARDEN_TAG

FROM mcr.microsoft.com/dotnet/sdk:8.0 as build

WORKDIR /bitBetter

COPY ./src/bitBetter /bitBetter

RUN set -ex \
    && dotnet add package Newtonsoft.Json --version 13.0.1 \
    && dotnet restore \
    && dotnet publish -o bin

FROM ${BITWARDEN_TAG} as base

COPY --from=build /bitBetter/bin/* /bitBetter/

FROM base as public

COPY ./publicKeys/cert.cert /newLicensing.cer

RUN set -ex \
    && dotnet /bitBetter/bitBetter.dll \
    && mv /app/Core.dll /app/Core.orig.dll \
    && mv /app/modified.dll /app/Core.dll \
    && rm -rf /bitBetter \
    && rm -rf /newLicensing.cer

FROM base as custom

COPY ./src/bitBetter/bitbetter-entrypoint.sh /
RUN set -ex \
    && chmod +x /bitbetter-entrypoint.sh

ENTRYPOINT [ "/bitbetter-entrypoint.sh" ]
