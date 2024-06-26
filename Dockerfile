# syntax=docker/dockerfile:1
FROM ruby:3.1.2
RUN apt-get update -qq && apt-get install -y postgresql-client libpq-dev wget curl firefox-esr

# Cria um novo usuário e grupo com UID 1000
RUN groupadd -g 1000 myuser \
    && useradd -r -u 1000 -g myuser myuser \
    && mkdir -p /home/myuser \
    && chown -R myuser:myuser /home/myuser

# include root user on appuser group
RUN usermod -aG root myuser

# Baixar o geckodriver para arquitetura de sistema da máquina
# Define a versão do geckodriver
ENV GECKODRIVER_VERSION 0.34.0

# Cria um script para baixar o geckodriver adequado
RUN echo '#!/bin/bash' > /usr/bin/install_geckodriver.sh \
    && echo 'ARCH=$(uname -m)' >> /usr/bin/install_geckodriver.sh \
    && echo 'if [ "$ARCH" = "x86_64" ]; then' >> /usr/bin/install_geckodriver.sh \
    && echo '  GECKODRIVER_URL="https://github.com/mozilla/geckodriver/releases/download/v$GECKODRIVER_VERSION/geckodriver-v$GECKODRIVER_VERSION-linux64.tar.gz"' >> /usr/bin/install_geckodriver.sh \
    && echo 'elif [ "$ARCH" = "aarch64" ]; then' >> /usr/bin/install_geckodriver.sh \
    && echo '  GECKODRIVER_URL="https://github.com/mozilla/geckodriver/releases/download/v$GECKODRIVER_VERSION/geckodriver-v$GECKODRIVER_VERSION-linux-aarch64.tar.gz"' >> /usr/bin/install_geckodriver.sh \
    && echo 'else' >> /usr/bin/install_geckodriver.sh \
    && echo '  echo "Arquitetura não suportada: $ARCH"' >> /usr/bin/install_geckodriver.sh \
    && echo '  exit 1' >> /usr/bin/install_geckodriver.sh \
    && echo 'fi' >> /usr/bin/install_geckodriver.sh \
    && echo 'wget -q $GECKODRIVER_URL -O /tmp/geckodriver.tar.gz' >> /usr/bin/install_geckodriver.sh \
    && echo 'tar -xzf /tmp/geckodriver.tar.gz -C /usr/bin' >> /usr/bin/install_geckodriver.sh \
    && echo 'chmod +x /usr/bin/geckodriver' >> /usr/bin/install_geckodriver.sh \
    && echo 'rm /tmp/geckodriver.tar.gz' >> /usr/bin/install_geckodriver.sh \
    && chmod +x /usr/bin/install_geckodriver.sh

# Executa o script para instalar o geckodriver
RUN /usr/bin/install_geckodriver.sh


# Ajusta permissões para o novo usuário
RUN mkdir -p /usr/local/bundle /usr/local/lib/ruby/gems/3.1.0 /usr/local/bin /myapp \
    && chown -R myuser:myuser /usr/local/bundle /usr/local/lib/ruby/gems/3.1.0 /usr/local/bin /myapp

# Alterna para o novo usuário
USER myuser

WORKDIR /myapp
COPY Gemfile /myapp/Gemfile
COPY Gemfile.lock /myapp/Gemfile.lock
RUN bundle install
RUN gem install pg

# Configure the main process to run when running the image
CMD ["ruby", "main.rb"]
