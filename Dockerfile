FROM alpine:3.5

WORKDIR /app

ADD gophr /app/
ADD assets /app/assets
ADD templates /app/templates

EXPOSE 3000
CMD /app/gophr
