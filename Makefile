# Northwind Finance - loan offer prediction (educational demo)
# Run "make help" to list targets.

# Pick the venv Python for the current OS
ifeq ($(OS),Windows_NT)
PY := .venv/Scripts/python.exe
else
PY := .venv/bin/python
endif

.DEFAULT_GOAL := help

# Docker image (only our API image is built; Prometheus/Grafana use official images)
IMAGE   := iomega/northwind-loans-api
VERSION := 0.1.0
# Latest saved model version - "=" (lazy) so it is only computed by docker-build
MODEL_VERSION = $(shell $(PY) -c "from northwind_loans.registry import list_versions; print(list_versions()[-1])")

# "logs" is also a folder name, so every target must be .PHONY
.PHONY: help setup profile clean-data features train models predict-sample test serve \
        docker-build up down logs simulate-normal simulate-drift simulate-bad monitor

help:
	@echo "Northwind Finance - make targets"
	@echo "  setup            create .venv (Python 3.12, uv) and install the package"
	@echo "  profile          profile the raw data"
	@echo "  clean-data       clean raw data into data/processed"
	@echo "  features         preview policy features on the processed data"
	@echo "  train            train, report and save the next model version"
	@echo "  models           list saved model versions"
	@echo "  predict-sample   predict on the sample applicants"
	@echo "  test             run the test suite"
	@echo "  serve            run the FastAPI app locally"
	@echo "  docker-build     build the API Docker image"
	@echo "  up / down        start / stop the Docker stack"
	@echo "  logs             follow the stack logs"
	@echo "  simulate-normal  send normal traffic to the API"
	@echo "  simulate-drift   send drifted traffic to the API"
	@echo "  simulate-bad     send invalid traffic to the API"
	@echo "  monitor          open Prometheus / Grafana"

# ---- Available now ---------------------------------------------------------
setup:
	uv venv --python 3.12 --allow-existing .venv
	uv pip install --python $(PY) -e ".[dev]"

test:
	$(PY) -m pytest -q

profile:
	$(PY) -m northwind_loans.profiling

clean-data:
	$(PY) -m northwind_loans.cleaning

features:
	$(PY) -m northwind_loans.features

train:
	$(PY) -m northwind_loans.train

models:
	$(PY) -m northwind_loans.registry

predict-sample:
	$(PY) -m northwind_loans.predict

serve:
	$(PY) -m northwind_loans.api

docker-build:
	docker build --build-arg MODEL_VERSION=$(MODEL_VERSION) -t $(IMAGE):$(VERSION) -t $(IMAGE):latest .

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f api

# ---- Placeholders: implemented in later steps --------------------------------
simulate-normal:
	@echo "simulate-normal: not implemented yet (coming in a later step)"

simulate-drift:
	@echo "simulate-drift: not implemented yet (coming in a later step)"

simulate-bad:
	@echo "simulate-bad: not implemented yet (coming in a later step)"

monitor:
	@echo "monitor: not implemented yet (coming in a later step)"
