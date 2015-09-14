FROM phusion/baseimage:0.9.15

# Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8
ENV TERM       vt100
ENV HOME /root

RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

CMD ["/sbin/my_init"]


RUN add-apt-repository -y ppa:ondrej/php5
RUN add-apt-repository -y ppa:nginx/stable
RUN apt-add-repository --yes ppa:brightbox/ruby-ng

RUN apt-get update && apt-get install -y vim git

RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y vim curl wget build-essential python-software-properties
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y --force-yes php5-cli php5-fpm php5-mysql php5-pgsql php5-sqlite php5-curl\
		       php5-gd php5-mcrypt php5-intl php5-imap php5-tidy

# to run phpunit
RUN wget https://phar.phpunit.de/phpunit.phar
RUN chmod +x phpunit.phar
RUN sudo mv phpunit.phar /usr/local/bin/phpunit

RUN sed -i "s/;date.timezone =.*/date.timezone = America\/New_York/" /etc/php5/fpm/php.ini
RUN sed -i "s/;date.timezone =.*/date.timezone = America/\/New_York/" /etc/php5/cli/php.ini

RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y nginx

RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini

RUN rm -rf          /var/www
RUN mkdir -p        /var/www
ADD build/default   /etc/nginx/sites-available/default
ADD build/webgrind.nginx.conf /etc/nginx/sites-enabled/webgrind.conf
RUN mkdir           /etc/service/nginx
ADD build/nginx.sh  /etc/service/nginx/run
RUN chmod +x        /etc/service/nginx/run
RUN mkdir           /etc/service/phpfpm
ADD build/phpfpm.sh /etc/service/phpfpm/run
RUN chmod +x        /etc/service/phpfpm/run

# End Nginx-PHP

RUN apt-get install -y postgresql postgresql-contrib postgresql-client-common
RUN apt-get install -y git curl
RUN apt-get install -y nodejs npm build-essential coffeescript

RUN ln -s /etc/php5/fpm/mods-available/timezone.ini /etc/php5/fpm/conf.d/20-timezone.ini

EXPOSE 80
EXPOSE 81

# phpunit
RUN wget https://phar.phpunit.de/phpunit.phar
RUN chmod +x phpunit.phar
RUN mv phpunit.phar /usr/local/bin/phpunit

# set up env vars so connecting is easy
RUN echo "export PGHOST='wh-postgis'" >> /etc/bash.bashrc
RUN echo "export PGUSER='docker'" >> /etc/bash.bashrc
RUN echo "export PGDATABASE='whathood'" >> /etc/bash.bashrc
RUN echo "set -o vi" >>  /etc/bash.bashrc

# install grunt
RUN rm -f /usr/bin/node
RUN ln -s /usr/bin/nodejs /usr/bin/node
RUN npm install -g grunt-cli > /dev/null 2>&1
RUN npm install grunt --save-dev
RUN npm install grunt-contrib-coffee --save-dev
RUN npm install grunt-contrib-watch --save-dev
RUN npm install grunt-contrib-clean --save-dev

RUN cp /node_modules /var/www/whathood/ -r

# install ruby
RUN apt-get update
RUN apt-get install -y ruby2.2 ruby2.2-dev
RUN gem install \
    rerun \
    foreman \
    colorize

# OPCACHE
ADD build/opcache.ini   /etc/php5/fpm/mods-available/opcache.ini

# SET timezone
ADD build/timezone.ini   /etc/php5/fpm/mods-available/timezone.ini

# memcached
RUN apt-get install -y php5-memcached memcached

# clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
