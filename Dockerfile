FROM ghcr.io/gleam-lang/gleam:v1.12.0-erlang-alpine

WORKDIR /app/
COPY . ./

RUN gleam deps download \
    && gleam build

# Default to 8080 if unset.
EXPOSE 8080

# Pass the platform-provided $PORT to the app as an argument
CMD ["sh", "-lc", "gleam run -m mcp_full_server websocket ${PORT:-8080}"]
