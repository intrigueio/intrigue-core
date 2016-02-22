FROM ubuntu:14.04
MAINTAINER Jonathan Cran <jcran@intrigue.io>

# basic updates and dependencies
RUN apt-get install -y software-properties-common
RUN apt-add-repository ppa:brightbox/ruby-ng
RUN apt-get update -qq && apt-get -y upgrade && \
	apt-get -y install ruby2.2 ruby2.2-dev libxml2-dev \
	libxslt-dev zmap nmap sudo default-jre libsqlite3-dev \
	git gcc g++ make libpcap-dev zlib1g-dev curl libcurl4-openssl-dev libpq-dev postgresql-server-dev-all \
        wget

# masscan build and installation
WORKDIR /usr/share
RUN git clone https://github.com/robertdavidgraham/masscan
WORKDIR /usr/share/masscan
RUN make -j 3 && make install

# get the Gemfile & Gemfile.lock in
# https://medium.com/@fbzga/how-to-cache-bundle-install-with-docker-7bed453a5800#.f2hrjsvnz
COPY Gemfile* /tmp/
WORKDIR /tmp
ENV BUNDLE_JOBS=12
RUN gem install bundler && bundle install --system

# get intrigue-core code
EXPOSE 7777
COPY . /core

# start the app
WORKDIR /core
CMD ["./script/control.sh", "start"]
