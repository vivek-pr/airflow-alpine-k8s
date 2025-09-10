SHELL := /bin/bash

# Parse versions from docker/Dockerfile (no ripgrep dependency)
RAW_AIRFLOW_VERSION := $(shell grep -E "^ARG AIRFLOW_VERSION=" docker/Dockerfile | head -n1 | sed -E 's/.*=([A-Za-z0-9\._-]+)/\1/')
RAW_PYTHON_VERSION  := $(shell grep -E "^ARG PYTHON_VERSION=" docker/Dockerfile | head -n1 | sed -E 's/.*=([0-9]+\.[0-9]+)/\1/')

AIRFLOW_VERSION ?= $(if $(RAW_AIRFLOW_VERSION),$(RAW_AIRFLOW_VERSION),3.0.3)
PYTHON_VERSION  ?= $(if $(RAW_PYTHON_VERSION),$(RAW_PYTHON_VERSION),3.12)

IMAGE ?= airflow-custom:$(AIRFLOW_VERSION)-py$(PYTHON_VERSION)

.PHONY: deps build test run clean

## deps: Compile constraints.custom.txt using pip-tools with our overrides
deps:
	@echo "Generating constraints for Airflow $(AIRFLOW_VERSION) on Python $(PYTHON_VERSION)"
	python3 -m venv .venv-tools && \
	. .venv-tools/bin/activate && \
	pip install -q --upgrade pip pip-tools && \
	URL=https://raw.githubusercontent.com/apache/airflow/constraints-$(AIRFLOW_VERSION)/constraints-$(PYTHON_VERSION).txt && \
	curl -fsSL $$URL -o constraints.airflow.base.raw.txt && \
	grep -Evi "^(Werkzeug|Flask|Flask-AppBuilder|itsdangerous|Jinja2|click|blinker|Flask-Login|Flask-WTF|Flask-Babel)(==|\s|$)" constraints.airflow.base.raw.txt > constraints.airflow.base.txt && \
	AIRFLOW_VERSION=$(AIRFLOW_VERSION) PYTHON_VERSION=$(PYTHON_VERSION) envsubst < constraints.in > .constraints.rendered.in && \
	pip-compile --resolver=backtracking --upgrade -o constraints.custom.txt -c constraints.airflow.base.txt .constraints.rendered.in && \
	rm -f .constraints.rendered.in && \
	deactivate
	@echo "constraints.custom.txt generated."

## deps-fast: Fallback generator (no pip-tools), merges upstream constraints with overrides
deps-fast:
	AIRFLOW_VERSION=$(AIRFLOW_VERSION) PYTHON_VERSION=$(PYTHON_VERSION) python scripts/merge_constraints.py

## build: Build Docker image using constraints.custom.txt
build:
	docker build --build-arg PYTHON_VERSION=$(PYTHON_VERSION) \
	             --build-arg AIRFLOW_VERSION=$(AIRFLOW_VERSION) \
	             -t $(IMAGE) -f docker/Dockerfile .

## run: Start Airflow webserver quickly for local smoke
run:
	docker run --rm -it -p 8080:8080 \
	  -e AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=sqlite:////opt/airflow/airflow.db \
	  -e AIRFLOW__CORE__EXECUTOR=SequentialExecutor \
	  -e AIRFLOW__WEBSERVER__AUTHENTICATE=True \
	  -e AIRFLOW__WEBSERVER__SECRET_KEY=devsecret \
	  -e AIRFLOW__WEBSERVER__ENABLE_PROXY_FIX=True \
	  $(IMAGE)

## test: Run unit + integration tests with pytest
test:
	python3 -m venv .venv && \
	. .venv/bin/activate && \
	pip install -q --upgrade pip && \
	pip install -q -r tests/requirements-dev.txt && \
	pytest -q && \
	deactivate

clean:
	rm -rf .venv .venv-tools
	rm -f .constraints.rendered.in
