FROM squidfunk/mkdocs-material as mkdocs-builder
WORKDIR /docs
COPY . /docs
RUN mkdocs build

FROM nginx:alpine
COPY --from=mkdocs-builder /docs/site /usr/share/nginx/html
