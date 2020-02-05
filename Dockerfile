FROM golang:1.14-rc-alpine AS Builder

RUN echo "Getting Builder Packages..." && \
  apk --no-cache add \
      curl git ca-certificates && \
  echo "Downloading dep to Builder for dependency management..." && \
  go get -u github.com/golang/dep/... && \
  echo "Downloading supercronic source..." && \
  go get -d github.com/phin1x/supercronic && \
  cd "${GOPATH}/src/github.com/phin1x/supercronic" && \
  echo "Getting sueprcronic depdencies..." && \
  dep ensure -vendor-only && \
  echo "Building Supercronic..." && \
  sed -i 's|/aptible/supercronic|/phin1x/supercronic|g' main.go && \
  sed -i 's|/aptible/supercronic|/phin1x/supercronic|g' cron/cron_test.go && \
  sed -i 's|/aptible/supercronic|/phin1x/supercronic|g' cron/cron.go && \
  CGO_ENABLED=0 GOOS=linux go build -a -o supercronic . && \
  mkdir /built && \
  cp supercronic /built

FROM hongkongkiwi/overdrive:latest
COPY --from=builder "/built" /usr/bin
COPY ./crontab /etc/crontab

RUN apk --no-cache add python3 && \
    pip3 install mutagen && \
    touch "/etc/crontab" && \
    echo "Fixing Permissions..." && \
    chmod +x /usr/bin/supercronic

ENV TZ=Asia/Hong_Kong \
    MONITOR_DIR="/odm" \
    OUTPUT_DIR="/mp3"

VOLUME ["/odm", "/mp3"]

ENTRYPOINT ["supercronic"]
CMD ["/etc/crontab"]
