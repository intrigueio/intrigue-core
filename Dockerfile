FROM ubuntu:14.04
MAINTAINER Jonathan Cran <jcran@intrigue.io>

RUN apt-get install -y software-properties-common
RUN apt-add-repository ppa:brightbox/ruby-ng
RUN apt-get update -qq && apt-get -y upgrade && \
	apt-get -y install ruby2.2 ruby2.2-dev libxml2-dev \
	libxslt-dev zmap nmap sudo default-jre libsqlite3-dev \
	git gcc g++ make libpcap-dev zlib1g-dev curl libcurl4-openssl-dev libpq-dev postgresql-server-dev-all \
        wget

# build masscan
WORKDIR /usr/share
RUN git clone https://github.com/robertdavidgraham/masscan
WORKDIR /usr/share/masscan
RUN make -j 3 && make install

# get intrigue-core code
COPY . /core
WORKDIR /core

ENV BUNDLE_JOBS=12
RUN gem install bundler && bundle install --system

EXPOSE 7777

WORKDIR /core
CMD ["./script/control.sh", "start"]
