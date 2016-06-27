FROM ubuntu:14.04
MAINTAINER Jonathan Cran <jcran@intrigue.io>

# Basic updates and dependencies
RUN apt-get update
RUN apt-get install -y software-properties-common
#RUN apt-add-repository ppa:brightbox/ruby-ng
RUN apt-get update -qq && apt-get -y upgrade && \
	apt-get -y install libxml2-dev libxslt-dev zmap nmap sudo default-jre libsqlite3-dev \
	git gcc g++ make libpcap-dev zlib1g-dev curl libcurl4-openssl-dev libpq-dev postgresql-server-dev-all \
    wget libgdbm-dev libncurses5-dev automake libtool bison libffi-dev libgmp-dev unzip

# masscan build and installation
WORKDIR /usr/share
RUN git clone https://github.com/robertdavidgraham/masscan
WORKDIR /usr/share/masscan
RUN make -j 3 && make install

# create an app user (would require us setting up sudo)
#RUN useradd -ms /bin/bash app
#USER app

# set up RVM
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
RUN /bin/bash -l -c "curl -L get.rvm.io | bash -s stable"
RUN /bin/bash -l -c "rvm install 2.3.0"
RUN /bin/bash -l -c "echo 'gem: --no-ri --no-rdoc' > ~/.gemrc"
RUN /bin/bash -l -c "gem install bundler --no-ri --no-rdoc"

# Install the deps
# https://medium.com/@fbzga/how-to-cache-bundle-install-with-docker-7bed453a5800#.f2hrjsvnz
COPY Gemfile* /tmp/
WORKDIR /tmp
ENV BUNDLE_JOBS=12
RUN /bin/bash -l -c "bundle install --system" --path /core

# get intrigue-core code
#COPY . /core/
RUN mkdir -p /root/core \
    && cd /root/core \
    && wget https://github.com/intrigueio/intrigue-core/archive/develop.zip \
    && unzip develop.zip \
    && mv /root/core/intrigue-core-develop/* .
COPY config/config.json /root/core/config/config.json

# Now modify puma.rb
RUN cd /root/core/config/ && sed -i 's:127.0.0.1:0.0.0.0:g' puma.rb

# Expose a port
EXPOSE 7777

# start the app
WORKDIR /root/core
RUN /bin/bash -l -c "rm /root/core/intrigue-core-develop/.ruby-gemset"
ENTRYPOINT ["/bin/bash", "-l"]
CMD ["/root/core/script/control.sh","start"]
