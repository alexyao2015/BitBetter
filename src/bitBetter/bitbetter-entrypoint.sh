#!/bin/bash

set -e; set -x; \
    dotnet /bitBetter/bitBetter.dll && \
    mv /app/Core.dll /app/Core.orig.dll && \
    mv /app/modified.dll /app/Core.dll

/bin/bash /entrypoint.sh
