# docker-base

This is the base image for the build stage of all zwoo docker images.

It is composed of:

- `mcr.microsoft.com/dotnet/sdk:8.0.401-bookworm-slim-amd64` (using `debian:bookworm-slim` as base)
- `node:20.16.0-bookworm-slim`
- `zwooc` v1.1.0

It should only be used for the build stage. The production image depend on the technology used. Common images are:

- `nginx:stable-alpine` (frontend/docs)
- `mcr.microsoft.com/dotnet/aspnet:8.0` (backend)

## version compatibilities

| image version | included                                                                                                           |
| ------------- | ------------------------------------------------------------------------------------------------------------------ |
| v0.1.0        | alpine:3.19.2 <br> dotnet-sdk:8.0.6 <br> node:20.15.0 <br> zwooc:1.0.1                                             |
| v0.2.0        | debian:bookworm-slim <br> mcr.microsoft.com/dotnet/sdk:8.0.401 <br> node:20.16.0 <br> yarn:1.22.22 <br>zwooc:1.1.0 |