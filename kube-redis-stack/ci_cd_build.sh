podman build -t redis-with-ssl .

# # Run the first Redis container
# podman run -d --name redis1 -p 6379:6379 redis-with-ssl
# # Run the second Redis container
# podman run -d --name redis2 -p 6380:6379 redis-with-ssl
