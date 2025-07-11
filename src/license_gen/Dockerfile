FROM ghcr.io/astral-sh/uv:debian-slim AS custom

WORKDIR /bitbetter

RUN --mount=type=bind,source=./requirements.txt,target=requirements.txt \
    uv python install 3.13 \
    && uv venv \
    && uv pip sync requirements.txt

COPY license_gen.py /bitbetter

RUN mkdir -p /bitbetter/output

ENTRYPOINT [ "uv", "run", "/bitbetter/license_gen.py" ]

FROM custom AS public

COPY --from=certs . /bitbetter/certs
