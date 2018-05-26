FROM ubuntu:16.04
MAINTAINER Jonathan Cran <jcran@intrigue.io>

RUN apt-get update -qq && apt-get -y upgrade && \
	apt-get -y install libxml2-dev libxslt-dev zmap nmap sudo default-jre \
	libsqlite3-dev sqlite3 git gcc g++ make libpcap-dev zlib1g-dev curl \
	libcurl4-openssl-dev libpq-dev wget libgdbm-dev \
	libncurses5-dev automake libtool bison libffi-dev libgmp-dev \
	software-properties-common bzip2 gawk libreadline6-dev libyaml-dev \
	pkg-config redis-server net-tools clang

# Set up nginx?
# TODO

# set up postgres
RUN sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
RUN wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -
RUN sudo apt-get update
RUN sudo apt-get -y install postgresql-9.6 postgresql-contrib-9.6

# Install phantomjs & imagemagick
RUN apt-get -y install build-essential chrpath libssl-dev libxft-dev libfreetype6-dev libfreetype6 libfontconfig1-dev libfontconfig1 imagemagick
RUN sudo sh -c 'wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2'
RUN sudo sh -c 'tar xvjf phantomjs-2.1.1-linux-x86_64.tar.bz2 -C /usr/local/share/'
RUN sudo sh -c 'ln -s /usr/local/share/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/bin/'

# Install Masscan
WORKDIR /usr/share
RUN git clone https://github.com/robertdavidgraham/masscan
WORKDIR /usr/share/masscan
RUN make -j 3 && make install

# Create an app user (would require us setting up sudo)
#RUN useradd -ms /bin/bash app
#USER app

# Install rbenv and ruby-build
WORKDIR /root
RUN git clone https://github.com/sstephenson/rbenv.git /root/.rbenv
RUN git clone https://github.com/sstephenson/ruby-build.git /root/.rbenv/plugins/ruby-build
RUN git clone https://github.com/rbenv/rbenv-default-gems.git /root/.rbenv/plugins/rbenv-default-gems
RUN /root/.rbenv/plugins/ruby-build/install.sh
ENV PATH /root/.rbenv/bin:$PATH
#RUN echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh
RUN echo 'eval "$(rbenv init -)"' >> .bashrc

# Install multiple versions of ruby
ENV CONFIGURE_OPTS --disable-install-doc
RUN rbenv install 2.5.1
RUN rbenv global 2.5.1

# Fix an rbenv path issue
RUN echo export PATH=/root/.rbenv/shims:$PATH >> /etc/profile.d/rbenv.sh
RUN echo export PATH=/root/.rbenv/shims:$PATH >> .bashrc

# Install the deps
# https://medium.com/@fbzga/how-to-cache-bundle-install-with-docker-7bed453a5800#.f2hrjsvnz
COPY Gemfile* /tmp/
WORKDIR /tmp
ENV BUNDLE_JOBS=12
RUN /bin/bash -l -c "gem install bundler"
RUN /bin/bash -l -c "bundle config --global silence_root_warning 1"
RUN /bin/bash -l -c "bundle install --system"

# get intrigue-core code
RUN /bin/bash -l -c "rm -rf /core && mkdir -p /core"
ADD . /core/

# check networks
#RUN /bin/bash -l -c "apt-get install net-tools && ifconfig && netstat -lnt"

# Migrate!
WORKDIR /core

# Ensure we listen on all ipv4 interfaces, and background the file
RUN cp /core/config/puma.rb.default /core/config/puma.rb
RUN sed -i "s/tcp:\/\/127.0.0.1:7777/tcp:\/\/0.0.0.0:7777/g" /core/config/puma.rb

# Expose a port
EXPOSE 7777

# Set up the service file
RUN cp /core/util/control.sh.default /core/util/control.sh
RUN ln -s /core/util/control.sh /etc/init.d/intrigue

# Configure postgres
RUN /bin/bash -l -c "sed -i 's/md5/trust/g' /etc/postgresql/9.6/main/pg_hba.conf"

# start the app (also migrates DB)
CMD /bin/bash -l -c "PATH=/root/.rbenv/shims:$PATH && service postgresql start && service redis-server start && su - postgres -c 'createuser -d -w intrigue && createdb intrigue_dev' && service intrigue start"

#ENTRYPOINT "/bin/bash"
