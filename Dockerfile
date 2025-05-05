FROM ruby:3.4.1


RUN apt-get update && apt-get install -y \
    build-essential nodejs npm imagemagick libpq-dev \
    memcached libffi-dev libyaml-dev libgmp-dev \
    zlib1g-dev libssl-dev libreadline-dev \
    libxml2-dev libxslt1-dev postgresql-client git openssh-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . .

RUN gem install bundler -v 2.6.3


RUN bundle install

WORKDIR /app/frontend
RUN npm install


WORKDIR /app


ENV RAILS_ENV=production \
    MEMCACHE_SERVERS=memcached:11211 \
    OPENPROJECT_HTTPS=false


COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]


EXPOSE 3000
