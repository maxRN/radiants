FROM ghcr.io/advplyr/audiobookshelf:latest

USER root

RUN apk add --no-cache rclone fuse3 openssh-client ca-certificates dcron \
 && echo "user_allow_other" >> /etc/fuse.conf

COPY entrypoint.sh check-volume-usage.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/check-volume-usage.sh \
 && echo "0 * * * * /usr/local/bin/check-volume-usage.sh" > /etc/crontabs/root

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["node", "index.js"]
