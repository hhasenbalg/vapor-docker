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