FROM amd64/alpine:latest

LABEL made by Sof

RUN apk update \
	&& apk upgrade \
	&& apk add nginx \
	&& adduser -D -g 'www' www \
	&& mkdir /www \
	&& chown -R www:www /var/lib/nginx \
	&& chown -R www:www /www \
	&& mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig

COPY nginx.conf /etc/nginx/nginx.conf
COPY index.html /www/index.html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]