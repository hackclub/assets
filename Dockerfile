FROM dhi.io/nginx:1-alpine-dev AS content

USER 0

RUN apk add --no-cache git

WORKDIR /content
COPY . .

RUN set -eu; \
    git ls-files -z | while IFS= read -r -d '' path; do \
        [ -e "$path" ] || continue; \
        timestamp="$(git log -1 --format=%ct -- "$path")"; \
        [ -z "$timestamp" ] || touch -d "@$timestamp" "$path"; \
    done; \
    find . -type d ! -path './.git*' -print0 | while IFS= read -r -d '' path; do \
        timestamp="$(git log -1 --format=%ct -- "$path")"; \
        [ -z "$timestamp" ] || touch -d "@$timestamp" "$path"; \
    done; \
    rm -rf .git Dockerfile .dockerignore nginx.conf vercel.json index.html 50x.html

FROM dhi.io/nginx:1-alpine

USER 0

COPY nginx.conf /etc/nginx/nginx.conf
COPY --from=content /content/ /usr/share/nginx/html/

USER nginx

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget -q -O /dev/null http://localhost/icon-rounded.svg || exit 1

CMD ["-g", "daemon off;"]
