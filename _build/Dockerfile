FROM python:3.12.7-alpine

WORKDIR /usr/src/app

COPY _build/requirements.txt .

RUN apk add --no-cache bash build-base yaml && \
  pip install --no-cache-dir -r requirements.txt

COPY _build/entrypoint /bin/entrypoint

ENTRYPOINT [ "/bin/entrypoint" ]
