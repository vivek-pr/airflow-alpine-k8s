# syntax=docker/dockerfile:1
ARG PYTHON_VERSION=3.12
ARG AIRFLOW_VERSION=3.0.3
ARG ALPINE_VERSION=3.21

FROM python:${PYTHON_VERSION}-alpine${ALPINE_VERSION} AS builder
ARG AIRFLOW_VERSION
ARG PYTHON_VERSION

ENV PIP_NO_CACHE_DIR=1

# Install build dependencies and Airflow into a wheelhouse using custom constraints
# hadolint ignore=DL3018,DL3013
RUN apk add --no-cache --virtual .build-deps \
        gcc g++ musl-dev libc-dev libffi-dev openssl-dev cargo make postgresql-dev \
        py3-pybind11-dev re2-dev curl \
    && python -m pip install --upgrade pip wheel setuptools \
    && mkdir -p /wheelhouse

# Copy our deterministic constraints inside the build context
COPY constraints.custom.txt /opt/airflow/constraints.custom.txt
ENV PIP_CONSTRAINT=/opt/airflow/constraints.custom.txt

# Install Apache Airflow with extras using custom constraints
RUN pip install --no-cache-dir \
        "apache-airflow[celery,postgres,redis,ssh,kubernetes]==${AIRFLOW_VERSION}" \
    && apk del .build-deps

FROM python:${PYTHON_VERSION}-alpine${ALPINE_VERSION}
ARG AIRFLOW_VERSION
ARG PYTHON_VERSION
ARG AIRFLOW_UID=50000
ARG AIRFLOW_GID=50000
ENV AIRFLOW_HOME=/opt/airflow \
    PATH=/usr/local/bin:$PATH

# Runtime dependencies and user setup
# hadolint ignore=DL3018
RUN apk add --no-cache bash postgresql-client redis su-exec re2 wget \
    && addgroup -S -g ${AIRFLOW_GID} airflow \
    && adduser -S -u ${AIRFLOW_UID} -G airflow -h ${AIRFLOW_HOME} airflow \
    && mkdir -p ${AIRFLOW_HOME}/dags ${AIRFLOW_HOME}/logs ${AIRFLOW_HOME}/plugins \
    && chown -R airflow:airflow ${AIRFLOW_HOME}

COPY --from=builder /usr/local /usr/local
# Include constraints for reference/debugging in the runtime image
COPY constraints.custom.txt /opt/airflow/constraints.custom.txt
# Include helper scripts
COPY scripts/wait-for-airflow.sh /usr/local/bin/wait-for-airflow
RUN chmod +x /usr/local/bin/wait-for-airflow
COPY docker/entrypoint.sh /entrypoint.sh
COPY docker/healthcheck.sh /usr/local/bin/airflow-healthcheck
RUN chmod +x /entrypoint.sh /usr/local/bin/airflow-healthcheck

USER airflow
WORKDIR ${AIRFLOW_HOME}

# Health check that works for both API server and Webserver
# Tries /api/v1/health then /health then /api/v1/version on port 8080
HEALTHCHECK --interval=30s --timeout=10s --retries=5 CMD /usr/local/bin/airflow-healthcheck || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["airflow", "api-server"]
