FROM swift:4.0.3 as builder
WORKDIR /app/
COPY . .
RUN \
  apt-get -q update && apt-get -q -y install \
  libmysqlclient-dev \
  && rm -r /var/lib/apt/lists/*
RUN mkdir -p /build/lib && cp -R /usr/lib/swift/linux/*.so /build/lib
RUN swift build -c release && mv `swift build -c release --show-bin-path` /build/bin

FROM ubuntu:16.04
RUN \
  apt-get -q update && apt-get -q -y install \
  libatomic1 \
  libbsd0 \
  libcurl3 \
  libicu55 \
  libmysqlclient20 \
  libxml2 \
  && rm -r /var/lib/apt/lists/*
WORKDIR /app/
COPY --from=builder /build/bin .
COPY --from=builder /build/lib/* /usr/lib/
COPY --from=builder /app/Config ./Config
# COPY --from=builder /app/Resources ./Resources  # only if you use views
# COPY --from=builder /app/Public ./Public # again, if you have this
EXPOSE 8080
CMD ["./Run"]