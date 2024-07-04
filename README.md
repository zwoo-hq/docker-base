# docker-base

This is the base image for the build stage of all zwoo docker images.

It is composed of:

- `mcr.microsoft.com/dotnet/sdk:8.0-alpine3.19` (using `alpine:3.19` as base)
- `node:20-alpine3.19`
- `zwooc` v1.0.1

It should only be used for the build stage. The production image depend on the technology used. Common images are:

- `nginx:stable-alpine` (frontend/docs)
- `mcr.microsoft.com/dotnet/aspnet:8.0` (backend)

## version compatibilities

| image version | included                                                               |
| ------------- | ---------------------------------------------------------------------- |
| v0.1.0        | alpine:3.19.2 <br> dotnet-sdk:8.0.6 <br> node:20.15.0 <br> zwooc:1.0.1 |