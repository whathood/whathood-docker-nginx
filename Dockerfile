FROM phusion/baseimage:0.9.15

# Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8
ENV TERM       vt100
ENV HOME /root

RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

CMD ["/sbin/my_init"]

RUN apt-get update && apt-get install -y vim git

# Nginx-PHP Installation
RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y vim curl wget build-essential python-software-properties
RUN add-apt-repository -y ppa:ondrej/php5
RUN add-apt-repository -y ppa:nginx/stable

# for ruby 2.2
RUN apt-add-repository --yes ppa:brightbox/ruby-ng

RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y --force-yes php5-cli php5-fpm php5-mysql php5-pgsql php5-sqlite php5-curl\
		       php5-gd php5-mcrypt php5-intl php5-imap php5-tidy

# to run phpunit
RUN wget https://phar.phpunit.de/phpunit.phar
RUN chmod +x phpunit.phar
RUN sudo mv phpunit.phar /usr/local/bin/phpunit

RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php5/fpm/php.ini
RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php5/cli/php.ini

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
RUN apt-get install -y ruby2.2 ruby2.2-dev
RUN gem install rerun
RUN gem install foreman

# OPCACHE
ADD build/opcache.ini   /etc/php5/fpm/mods-available/opcache.ini
# OpCache
#RUN echo "opcache.enable=1" >> /etc/php5/fpm/php.ini
#RUN echo "opcache.memory_consumption=256" >> /etc/php5/fpm/php.ini
#RUN echo "opcache.max_accelerated_files=4000" >> /etc/php5/fpm/php.ini
#RUN echo "opcache.revalidate_freq=60" >> /etc/php5/fpm/php.ini

#RUN echo "opcache.revalidate_freq=0" >> /etc/php5/fpm/php.ini

# install xdebug and webgrind
RUN apt-get install -y unzip php5-dev php-pear php5-json
RUN pecl install xdebug
RUN echo 'zend_extension="/usr/lib/php5/20121212/xdebug.so"' >> /etc/php5/fpm/php.ini
RUN echo 'xdebug.profiler_enable = 1' >> /etc/php5/fpm/php.ini
RUN wget https://webgrind.googlecode.com/files/webgrind-release-1.0.zip
RUN unzip webgrind-release-1.0.zip
RUN mv webgrind /var/www


# clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
