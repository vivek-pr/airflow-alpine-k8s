# syntax=docker/dockerfile:1
ARG PYTHON_VERSION=3.11
ARG AIRFLOW_VERSION=2.8.1
ARG ALPINE_VERSION=3.19

FROM python:${PYTHON_VERSION}-alpine${ALPINE_VERSION} AS builder
ARG AIRFLOW_VERSION
ARG PYTHON_VERSION

ENV PIP_NO_CACHE_DIR=1

# Install build dependencies
RUN apk add --no-cache --virtual .build-deps \
        gcc musl-dev libc-dev libffi-dev openssl-dev cargo make postgresql-dev \
    && pip install --upgrade pip \
    && pip install "apache-airflow==${AIRFLOW_VERSION}" \
         --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt" \
    && apk del .build-deps

FROM python:${PYTHON_VERSION}-alpine${ALPINE_VERSION}
ARG AIRFLOW_VERSION
ARG PYTHON_VERSION
ENV AIRFLOW_HOME=/opt/airflow \
    PATH=/usr/local/bin:$PATH

# Runtime dependencies and user setup
RUN apk add --no-cache bash postgresql-client redis su-exec \
    && addgroup -S airflow && adduser -S -G airflow airflow \
    && mkdir -p ${AIRFLOW_HOME} \
    && chown airflow:airflow ${AIRFLOW_HOME}

COPY --from=builder /usr/local /usr/local
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER airflow
WORKDIR ${AIRFLOW_HOME}

ENTRYPOINT ["/entrypoint.sh"]
CMD ["airflow", "webserver"]
