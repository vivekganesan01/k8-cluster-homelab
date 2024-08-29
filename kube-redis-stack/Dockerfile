# FROM redis:latest

# # Install stunnel
# RUN apt-get update && apt-get install -y stunnel4

# # Copy Redis and stunnel configuration files
# COPY redis.conf /usr/local/etc/redis/redis.conf
# COPY stunnel.conf /etc/stunnel/stunnel.conf

# # Copy SSL certificates
# COPY server-cert.pem /etc/stunnel/server-cert.pem
# COPY server-key.pem /etc/stunnel/server-key.pem
# COPY ca-cert.pem /etc/stunnel/ca-cert.pem

# # Create stunnel configuration
# RUN mkdir -p /var/run/stunnel && chown redis:redis /var/run/stunnel

# # Entrypoint to start both Redis and stunnel
# CMD ["sh", "-c", "redis-server /usr/local/etc/redis/redis.conf & stunnel /etc/stunnel/stunnel.conf"]
FROM redis:latest

# Install stunnel
RUN apt-get update && apt-get install -y stunnel4

# Copy Redis and stunnel configuration files
COPY redis.conf /usr/local/etc/redis/redis.conf
COPY stunnel.conf /etc/stunnel/stunnel.conf

# Copy SSL certificates
COPY server-cert.pem /etc/stunnel/server-cert.pem
COPY server-key.pem /etc/stunnel/server-key.pem
COPY ca-cert.pem /etc/stunnel/ca-cert.pem

# Copy the start script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Create stunnel log directory
RUN mkdir -p /var/log/stunnel && chown redis:redis /var/log/stunnel

# Entrypoint to start both Redis and stunnel
ENTRYPOINT ["/usr/local/bin/start.sh"]