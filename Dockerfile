FROM ruby:2.6.4

RUN apt-get update && apt-get install -y bash nodejs --no-install-recommends && rm -rf /var/lib/apt/lists/*
RUN gem install rerun rb-fsevent

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

ADD Gemfile /usr/src/app/
ADD Gemfile.lock /usr/src/app/
RUN bundle install

ENV PATH="/usr/local/bundle/bin:${PATH}"

COPY . /usr/src/app

# Add a script to be executed every time the container starts.
# COPY entrypoint.sh /usr/bin/
# RUN chmod +x /usr/bin/entrypoint.sh
# ENTRYPOINT ["entrypoint.sh"]

EXPOSE 9292

# CMD ["bundle", "exec", "rerun", "rackup", ]
# CMD ["bundle", "exec", "rerun", "'rackup --host 0.0.0.0 -p 9292'"]
# CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "-p", "9292"]

