FROM dhi.io/nginx:1-alpine-dev AS content

USER 0

RUN apk add --no-cache git

WORKDIR /content
COPY . .

RUN set -eu; \
    if [ -f .git/shallow ]; then git fetch --quiet --unshallow origin; fi; \
    : > /tmp/git-mtimes; \
    git ls-files -z | while IFS= read -r -d '' path; do \
        [ -e "$path" ] || continue; \
        timestamp="$(git log -1 --format=%ct -- "$path")"; \
        [ -z "$timestamp" ] || printf '%s\t%s\n' "$timestamp" "$path" >> /tmp/git-mtimes; \
    done; \
    find . -type d ! -path './.git*' -print0 | while IFS= read -r -d '' path; do \
        timestamp="$(git log -1 --format=%ct -- "$path")"; \
        [ -z "$timestamp" ] || printf '%s\t%s\n' "$timestamp" "$path" >> /tmp/git-mtimes; \
    done; \
    rm -rf .git Dockerfile .dockerignore docker-entrypoint.sh nginx.conf vercel.json index.html 50x.html

FROM dhi.io/nginx:1-alpine

USER 0

COPY nginx.conf /etc/nginx/nginx.conf
COPY --chmod=755 docker-entrypoint.sh /usr/local/bin/assets-entrypoint
RUN rm -rf /usr/share/nginx/html && mkdir -p /usr/share/nginx/html
COPY --chown=nginx:nginx --from=content /content/ /usr/share/nginx/html/
COPY --chown=nginx:nginx --from=content /tmp/git-mtimes /tmp/git-mtimes

USER nginx

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget -q -O /dev/null http://localhost/icon-rounded.svg || exit 1

ENTRYPOINT ["/usr/local/bin/assets-entrypoint"]
CMD ["nginx", "-g", "daemon off;"]
