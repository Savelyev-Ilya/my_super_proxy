FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        dante-server \
        ca-certificates \
        passwd \
        iproute2 \
        python3 \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -r -s /usr/sbin/nologin dante

COPY danted.conf.template /etc/danted.conf.template
COPY entrypoint.sh /entrypoint.sh
COPY healthcheck.py /healthcheck.py
RUN chmod +x /entrypoint.sh /healthcheck.py

EXPOSE 1080 8080

CMD ["/entrypoint.sh"]
