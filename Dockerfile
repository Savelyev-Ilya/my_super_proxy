FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        dante-server \
        ca-certificates \
        passwd \
        iproute2 \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -r -s /usr/sbin/nologin dante

COPY danted.conf.template /etc/danted.conf.template
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 1080

CMD ["/entrypoint.sh"]
