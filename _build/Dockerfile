FROM python:3.13.4-alpine

WORKDIR /usr/src/app

COPY ["_build/pyproject.toml", "_build/poetry.toml", "_build/poetry.lock", "/usr/src/app/"]

RUN apk add --no-cache bash build-base poetry yaml && \
  poetry install --no-root

COPY _build/entrypoint /bin/entrypoint

ENTRYPOINT [ "/bin/entrypoint" ]
