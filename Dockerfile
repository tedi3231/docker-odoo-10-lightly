FROM debian:jessie
MAINTAINER Odoo S.A. <info@odoo.com>

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN	apt-get update \
    && apt-get install -y --no-install-recommends \
            ca-certificates \
            curl \
			unzip \
            node-less \
            python-gevent \
            python-pip \
            python-renderpm \
            python-support \
            python-watchdog \
	&& apt-get install -y --no-install-recommends build-essential libsasl2-dev libldap2-dev libssl-dev libffi-dev python-dev \
	&& pip install psycogreen==1.0 \
	&& pip install -U pip \
	&& pip install --upgrade pip setuptools \
	&& pip install psycogreen==1.0 \
	&& pip install cryptography \
	&& pip install wechatpy \
	&& pip install redis \
	&& pip install rabbitmq \
    && curl -o wkhtmltox.deb -SL http://nightly.odoo.com/extra/wkhtmltox-0.12.1.2_linux-jessie-amd64.deb \
    && echo '40e8b906de658a2221b15e4e8cd82565a47d7ee8 wkhtmltox.deb' | sha1sum -c - \
    && dpkg --force-depends -i wkhtmltox.deb \
    && apt-get -y install -f --no-install-recommends \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false npm \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb 

# 安装中文字体
RUN apt-get install ttf-wqy-microhei \
    && apt-get install ttf-wqy-zenhei

# Install Odoo
# RUN curl -o odoo.zip -SL https://github.com/tedi3231/odoo_lightly/archive/master.zip \
#        && unzip -q odoo.zip 
RUN curl -o odoo.zip -SL https://gitee.com/tyibs/odoo_10_dev_lightly/repository/archive/master.zip \
        && unzip -q odoo.zip 

RUN pip install wdb  odoo_10_dev_lightly/  \
	&& rm -rf odoo.zip  

# 安装FDFS客户端驱动
RUN curl -o fdfs.zip -SL https://gitee.com/tyibs/fdfs_client/repository/archive/master.zip \
        && unzip -q fdfs.zip 
RUN python fdfs_client/setup.py install \
    && rm -rf fdfs_client \
    && rm -rf fdfs.zip
#	&& rm -rf odoo_lightly-master

# RUN apt-get install -y --no-install-recommends ttf-wqy-zenhei ttf-wqy-microhei

# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/

# create fdfs client config folder
RUN mkdir -p /etc/fdfs/client \
COPY ./client.conf /etc/fdfs/client/

RUN useradd -m -d /va/lib/odoo -s /bin/false -u 104 -g www-data odoo
RUN mkdir -p /var/odoo \
	&& chown -R odoo:www-data /var/odoo \ 
    && mv odoo_10_dev_lightly/addons /var/odoo/ \
	&& chown -R odoo:www-data /var/odoo \
	&& chmod 0750 /var/odoo \
	&& rm -rf odoo_10_dev_lightly

RUN chown odoo:www-data /etc/odoo/odoo.conf \
	&& chown 0640 /etc/odoo/odoo.conf
# set fdfs client config permision
RUN chown odoo:www-data /etc/fdfs/client.conf \
	&& chown 0640 /etc/fdfs/client.conf

# Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN mkdir -p /mnt/extra-addons \
        && chown -R odoo:www-data /mnt/extra-addons
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Expose Odoo services
EXPOSE 8069 8071

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
