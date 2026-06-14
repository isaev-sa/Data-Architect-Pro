FROM apache/superset:6.1.0rc1-dev

USER root

RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    ca-certificates \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*
COPY ./docker/superset/superset_config.py /app/pythonpath/superset_config.py

COPY ./docker/superset/translations/ru /app/superset/translations/ru

COPY ./docker/superset/superset-frontend/scripts/po2json.sh /app/superset-frontend/scripts/po2json.sh

RUN cd /app/superset-frontend && \
    npm install --legacy-peer-deps && \
    npm run build-translation

USER superset