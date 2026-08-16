FROM alpine:3.22

RUN mkdir -p /app/server

COPY docker/entrypoint.sh /usr/local/bin/helpsupport-entrypoint

RUN chmod 0755 /usr/local/bin/helpsupport-entrypoint

ENTRYPOINT ["/usr/local/bin/helpsupport-entrypoint"]
CMD ["init-secrets"]
