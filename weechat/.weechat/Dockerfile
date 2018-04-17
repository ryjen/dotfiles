FROM alpine
MAINTAINER Ryan Jennings <ryan@coda.life>

RUN apk add --update\
    weechat\
    python\
    bash\
    && rm -rf /var/cache/apk/*

ENV LANG C.UTF-8
ENV HOME /weechat

#Create user to run screen/weechat
RUN mkdir -p $HOME/.weechat\
    && addgroup weechat\
    && adduser -h $HOME -D -s /bin/bash -G weechat weechat

COPY . /weechat/.weechat/

RUN chown -R weechat:weechat $HOME

#Expose for persistance
VOLUME /weechat/.weechat

WORKDIR $HOME
USER weechat

EXPOSE 9001

CMD ["weechat"]





