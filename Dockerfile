FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends dante-server ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -r -s /usr/sbin/nologin dante

COPY danted.conf /etc/danted.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 1080

CMD ["/entrypoint.sh"]
