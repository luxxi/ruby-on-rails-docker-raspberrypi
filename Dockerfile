FROM resin/rpi-raspbian:jessie

RUN apt-get update

# Install ruby dependencies
RUN apt-get install -y wget curl \
    build-essential patch git git-core \
    zlib1g-dev libssl-dev liblzma-dev libreadline-dev libyaml-dev \
		libsqlite3-dev sqlite3 postgresql-client \
		libxml2-dev libxslt1-dev \
		ca-certificates

# Install ruby-install
RUN cd /tmp &&\
  wget -O ruby-install-0.6.0.tar.gz https://github.com/postmodern/ruby-install/archive/v0.6.0.tar.gz &&\
  tar -xzvf ruby-install-0.6.0.tar.gz &&\
  cd ruby-install-0.6.0/ &&\
  make install

# Install MRI Ruby
RUN ruby-install ruby 2.3.0

# Add Ruby binaries to $PATH
ENV PATH /opt/rubies/ruby-2.3.0/bin:$PATH

# Add options to gemrc
RUN echo "install: --no-document\nupdate: --no-document" > ~/.gemrc

# Install nodejs
RUN apt-get install -qq -y nodejs

# Install Nginx.
RUN apt-get update --fix-missing
RUN apt-get install nginx
RUN apt-get update
RUN echo "\ndaemon off;" >> /etc/nginx/nginx.conf
RUN chown -R www-data:www-data /var/lib/nginx
# Add default nginx config
ADD nginx-sites.conf /etc/nginx/sites-enabled/default

# Install bundler
RUN gem install bundler

# Install foreman
RUN gem install foreman

# Install nokogiri
RUN gem install nokogiri -- --use-system-libraries=true --with-xml2-include=/usr/include/libxml2

# Install Rails App
WORKDIR /app
ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN bundle install --without development test
ADD . /app

# Add default unicorn config
ADD unicorn.rb /app/config/unicorn.rb

# Add default foreman config
ADD Procfile /app/Procfile

ENV RAILS_ENV production

CMD bundle exec rake assets:precompile && foreman start -f Procfile
