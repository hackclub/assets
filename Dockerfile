FROM dhi.io/nginx:1-alpine

USER 0

COPY nginx.conf /etc/nginx/nginx.conf

COPY . /usr/share/nginx/html

RUN rm -f /usr/share/nginx/html/Dockerfile \
          /usr/share/nginx/html/.dockerignore \
          /usr/share/nginx/html/nginx.conf \
          /usr/share/nginx/html/vercel.json \
          /usr/share/nginx/html/index.html \
          /usr/share/nginx/html/50x.html

USER nginx

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget -q -O /dev/null http://localhost/icon-rounded.svg || exit 1

CMD ["-g", "daemon off;"]
