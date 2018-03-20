# Docker images for Vapor

| Branch |      Status                                                                                                                                |
|--------|:------------------------------------------------------------------------------------------------------------------------------------------:|
| master | [![Build Status](https://drone.hagen-hasenbalg.de/api/badges/hhasenbalg/vapor-docker/status.svg?branch=master)](https://drone.hagen-hasenbalg.de/hhasenbalg/vapor-docker) |
| develop| [![Build Status](https://drone.hagen-hasenbalg.de/api/badges/hhasenbalg/vapor-docker/status.svg?branch= develop)](https://drone.hagen-hasenbalg.de/hhasenbalg/vapor-docker)  |

Docker images for multi staged builds of Vapor apps. Run your Swift app in a 65 MB small Image.

## Useage in Dockerfile

Build the Images

```Shell
docker build -f Dockerfile-builder -t vapor-builder .
docker build -f Dockerfile-runner -t vapor-runner .
```

You can build your app image using the builder and runner. 

```Dockerfile
FROM vapor-builder:latest as builder
WORKDIR /app/
COPY . .

RUN mkdir -p /build/lib && cp -R /usr/lib/swift/linux/*.so /build/lib
RUN swift build -c release && mv `swift build -c release --show-bin-path` /build/bin


FROM vapor-runner

WORKDIR /app/
COPY --from=builder /app/docker-entrypoint.sh /app/docker-entrypoint.sh
COPY --from=builder /build/bin .
COPY --from=builder /build/lib/* /usr/lib/
COPY --from=builder /app/Config ./Config
# COPY --from=builder /app/Resources ./Resources  # only if you use views
# COPY --from=builder /app/Public ./Public # again, if you have this

EXPOSE 9000
# CMD ["./Run",  "serve --env=production"]

RUN ["chmod", "+x", "./docker-entrypoint.sh"]
ENTRYPOINT ["./docker-entrypoint.sh"]
```

The docker-entrypoint.sh supports environment variables and docker secrets for Postgres and MySql.


```YAML
version: '3.1'

services:
  app:
  image: app
    secrets:
      - postgres_password
      - hash_key
      - cipher_key
    environment:
      PORT: 9001
      POSTGRES_HOSTNAME: postgres-db
      POSTGRES_PORT: 5432
      POSTGRES_USER: username
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password
      POSTGRES_DB: dbname      
      HASH_KEY_FILE: /run/secrets/hash_key
      CIPHER_KEY_FILE: /run/secrets/cipher_key
```

## Usage in drone CI


```YAML
workspace:
  base: /app

pipeline:
  build:
    image: waddle/vapor-builder
    commands:
      - swift build
    when:
      event: push

  test:
    image: waddle/vapor-builder
    commands:
      - swift test

  publish:
    image: plugins/docker
    repo: user/repo
    auto_tag: true
    secrets: [ docker_username, docker_password ]
    when:
      status: [ success ]
      branch: master
```
