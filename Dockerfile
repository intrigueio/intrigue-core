FROM ubuntu:16.04
MAINTAINER Jonathan Cran <jcran@intrigue.io>

#RUN apt-add-repository ppa:brightbox/ruby-ng
RUN apt-get update -qq && apt-get -y upgrade && \
	apt-get -y install libxml2-dev libxslt-dev zmap nmap sudo default-jre \
	libsqlite3-dev sqlite3 git gcc g++ make libpcap-dev zlib1g-dev curl \
	libcurl4-openssl-dev libpq-dev postgresql-server-dev-all wget libgdbm-dev \
	libncurses5-dev automake libtool bison libffi-dev libgmp-dev \
	software-properties-common bzip2 gawk libreadline6-dev libyaml-dev pkg-config

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
RUN /bin/bash -l -c "rvm install 2.3.1"
RUN /bin/bash -l -c "echo 'gem: --no-ri --no-rdoc' > ~/.gemrc"
RUN /bin/bash -l -c "gem install bundler --no-ri --no-rdoc"

# Install the deps
# https://medium.com/@fbzga/how-to-cache-bundle-install-with-docker-7bed453a5800#.f2hrjsvnz
COPY Gemfile* /tmp/
WORKDIR /tmp
ENV BUNDLE_JOBS=12
RUN /bin/bash -l -c "bundle install --system"

# get intrigue-core code
RUN /bin/bash -l -c "rm -rf /core && mkdir -p /core"
ADD . /core/

# Ensure we listen on all ipv4 interfaces
# RUN /bin/bash -l -c "sed -i \"s/127.0.0.1/0.0.0.0/g\" /core/config/puma.rb"

# Expose a port
EXPOSE 7777

# Set our working directory
WORKDIR /core

# start the app (also migrates DB)
RUN /bin/bash -l -c "rm .ruby-gemset"
ENTRYPOINT ["/bin/bash", "-l"]
CMD ["/core/script/control.sh","start"]
