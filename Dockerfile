FROM debian:jessie
MAINTAINER Odoo S.A. <info@odoo.com>
USER root
# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN set -x; \
        apt-get update \
        && apt-get install -y --no-install-recommends \
            ca-certificates \
            curl \
            node-less \
            python-gevent \
            python-pip \
            python-renderpm \
            python-support \
            python-watchdog \
        && curl -o wkhtmltox.deb -SL http://nightly.odoo.com/extra/wkhtmltox-0.12.1.2_linux-jessie-amd64.deb \
        && echo '40e8b906de658a2221b15e4e8cd82565a47d7ee8 wkhtmltox.deb' | sha1sum -c - \
        && dpkg --force-depends -i wkhtmltox.deb \
        && apt-get -y install -f --no-install-recommends \
        && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false npm \
        && rm -rf /var/lib/apt/lists/* wkhtmltox.deb \

RUN set -x;\
		apt-get install -y --no-install-recommends build-essential libssl-dev libffi-dev python-dev \
		&& pip install -U pip \
        && pip install psycogreen==1.0 \
        && pip install cryptography \
        && pip install wechatpy \
        && pip install redis \
        && pip install rabbitmq

# Install Odoo
RUN set -x; \
        curl -o odoo.zip -SL https://github.com/tedi3231/odoo_lightly/archive/master.zip \
        && unzip odoo.zip \
        && python odoo_lightly-master/setup.py install \ 
        && rm -rf odoo.zip \
		&& rm -rf odoo_lightly-master

# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/
RUN chown odoo /etc/odoo/odoo.conf

# Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN mkdir -p /mnt/extra-addons \
        && chown -R odoo /mnt/extra-addons
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Expose Odoo services
EXPOSE 8069 8071

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

# Set default user when running the container
# USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
