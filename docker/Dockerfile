# syntax=docker/dockerfile:1
ARG PYTHON_VERSION=3.12
ARG AIRFLOW_VERSION=3.0.3
ARG ALPINE_VERSION=3.21

FROM corporate-python:${PYTHON_VERSION}-alpine${ALPINE_VERSION} AS builder
USER root
ARG AIRFLOW_VERSION
ARG PYTHON_VERSION
ARG AIRFLOW_UID=50000
ARG AIRFLOW_GID=50000

ENV AIRFLOW_HOME=/opt/airflow
ENV PIP_NO_CACHE_DIR=1
ENV PATH=${AIRFLOW_HOME}/.local/bin:$PATH

# Create the airflow user and home directory
RUN addgroup -S -g ${AIRFLOW_GID} airflow \
    && adduser -S -u ${AIRFLOW_UID} -G airflow -h ${AIRFLOW_HOME} airflow \
    && mkdir -p ${AIRFLOW_HOME} \
    && chown -R airflow:airflow ${AIRFLOW_HOME}

USER airflow
# hadolint ignore=DL3013
RUN pip install --upgrade --user pip \
    && pip install --user "apache-airflow==${AIRFLOW_VERSION}" \
         --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt" \
    && pip install --user --no-cache-dir \
         "Werkzeug==3.0.6" \
         "cryptography==44.0.1" \
         "starlette==0.47.2"

USER airflow

FROM corporate-python:${PYTHON_VERSION}-alpine${ALPINE_VERSION}
USER root
ARG AIRFLOW_VERSION
ARG PYTHON_VERSION
ARG AIRFLOW_UID=50000
ARG AIRFLOW_GID=50000
ENV AIRFLOW_HOME=/opt/airflow
ENV PATH=${AIRFLOW_HOME}/.local/bin:/usr/local/bin:$PATH

# Runtime dependencies and user setup
# hadolint ignore=DL3018
RUN addgroup -S -g ${AIRFLOW_GID} airflow \
    && adduser -S -u ${AIRFLOW_UID} -G airflow -h ${AIRFLOW_HOME} airflow \
    && mkdir -p ${AIRFLOW_HOME}/dags ${AIRFLOW_HOME}/logs ${AIRFLOW_HOME}/plugins \
    && chown -R airflow:airflow ${AIRFLOW_HOME}

COPY --from=builder ${AIRFLOW_HOME}/.local ${AIRFLOW_HOME}/.local
COPY docker/entrypoint.sh /entrypoint.sh
RUN chown -R airflow:airflow ${AIRFLOW_HOME} \
    && chmod +x /entrypoint.sh

USER airflow
WORKDIR ${AIRFLOW_HOME}

# Health check to ensure Airflow command responds
HEALTHCHECK CMD airflow info > /dev/null || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["airflow", "webserver"]
