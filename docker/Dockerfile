FROM swift:6.1-noble AS build
WORKDIR /src
COPY . .
RUN swift build -c release --product ChessblazerUCI --static-swift-stdlib

FROM ubuntu:24.04
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4 \
    libxml2 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /src/.build/release/ChessblazerUCI /usr/local/bin/ChessblazerUCI
ENTRYPOINT ["ChessblazerUCI"]
