FROM ghcr.io/advplyr/audiobookshelf:latest

USER root

RUN apk add --no-cache rclone fuse3 openssh-client ca-certificates \
 && echo "user_allow_other" >> /etc/fuse.conf

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["node", "index.js"]
