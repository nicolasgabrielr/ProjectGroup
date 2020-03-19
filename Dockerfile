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

EXPOSE 9292

