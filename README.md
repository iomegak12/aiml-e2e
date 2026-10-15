# Northwind Finance — Maximum Loan Offer Prediction

An end-to-end ML application, built step by step in a live training session
(**Complete ML Application Development — E2E**).

**Business goal:** predict the **maximum loan amount (INR)** Northwind Finance can
offer an applicant (target column: `max_loan_offered`), serve it through a FastAPI
REST API in Docker, and monitor it with Prometheus and Grafana.

> ⚠️ **Disclaimer:** This is an **educational demonstration built on synthetic data**.
> Northwind Finance is fictional. This project and its model must **never be used
> for real credit decisions**.

## Project structure

```
aiml-e2e/
├── data/
│   ├── raw/                 # input data (read-only, never modified)
│   ├── sample/              # sample applicants (read-only, never modified)
│   └── processed/           # cleaned data (generated)
├── src/northwind_loans/     # Python package
│   ├── config.py            # all settings, paths and credit policy
│   ├── profiling.py         # raw-data profile (no cleaning)
│   ├── cleaning.py          # cleaning rules -> data/processed/*.parquet
│   ├── features.py          # credit-policy features + model column lists
│   ├── train.py             # engineered vs baseline pipelines, CV + test report, save
│   ├── business_rules.py    # raw prediction -> offer (clip, 5x income cap, round)
│   ├── reference_profile.py # training bins/shares (PSI) + fairness baseline
│   ├── registry.py          # versioned pickle + signed metadata (save/load/list)
│   ├── predict.py           # LoanOfferPredictor: clean -> model -> rules -> review
│   └── api/                 # FastAPI service: schemas, main, observability, __main__
├── tests/                   # pytest tests
├── scripts/                 # CLI scripts
├── models/                  # trained models (generated)
├── reports/                 # profiling / evaluation reports (generated)
├── logs/                    # application logs (generated)
├── monitoring/
│   ├── prometheus/
│   └── grafana/provisioning/{dashboards,datasources}/
├── pyproject.toml
├── Dockerfile               # multi-stage API image
├── docker-compose.yml       # api + prometheus + grafana
├── .dockerignore
├── Makefile
└── .env.example
```

## Quickstart

Requirements: Python 3.12, [uv](https://docs.astral.sh/uv/), GNU make.

```bash
cp .env.example .env      # optional - defaults work out of the box
make setup                # create .venv (Python 3.12) and install the package
make test                 # run tests
```

Without make: `uv venv --python 3.12 .venv` then `uv pip install -e ".[dev]"`
(or `pip install -e ".[dev]"` inside any Python 3.11/3.12 environment).

Check the configuration:

```bash
.venv/Scripts/python -c "from northwind_loans import config; print(config.TARGET)"   # Windows
.venv/bin/python     -c "from northwind_loans import config; print(config.TARGET)"   # macOS / Linux
```

## Configuration

- `src/northwind_loans/config.py` holds paths, `TARGET`, `CREDIT_POLICY`, `VALID_RANGES`
  and `INCOME_PAISE_THRESHOLD`.
- Paths, `LOG_LEVEL` and `RANDOM_STATE` (default `51`) can be overridden in `.env`
  (see `.env.example`). `.env` is not version controlled.

## REST API

```bash
make serve        # python -m northwind_loans.api  (API_HOST / API_PORT from .env, default 0.0.0.0:8000)
```

- Swagger UI: <http://127.0.0.1:8000/docs>
- `GET /health` (liveness), `GET /ready` (model loaded), `GET /model-info`
- `POST /predict` (one applicant), `POST /predict/batch` (1–1000 applicants)
- Invalid input → HTTP 422 with the failing field in `detail[].loc`; unknown fields are rejected.
- `gender` and `age` are accepted for fairness monitoring only — never used by the model.

### Observability
- `GET /metrics` — Prometheus metrics (`loan_api_*` traffic/latency/422s, `loan_model_*`
  predictions, offer and input histograms, reference means, model info). `/metrics` itself
  is not counted. Single uvicorn worker on purpose (in-process metrics).
- Console: one JSON log line per request (`request_id`, `method`, `path`, `status_code`,
  `duration_ms`, `model_version`); send `X-Request-ID` or one is generated and returned.
- `logs/predictions.jsonl` — audit log, one line per applicant (input + output);
  `age` and `gender` are never written.

## Docker

```bash
make docker-build   # iomega/northwind-loans-api:0.1.0 + :latest (latest model baked in)
make up             # API :8000, Prometheus :9090, Grafana :3000 (admin / GRAFANA_ADMIN_PASSWORD)
make logs           # follow API logs
make down
```

- Multi-stage image (`python:3.12-slim`, uv in the builder), runs as non-root `app`, no
  HEALTHCHECK (use `/health` and `/ready`).
- Only the **latest** model version is copied into the image; `.env`, data and tests are
  excluded by `.dockerignore`.
- The signing key is **not** in the image: run with `--env-file .env` (compose uses
  `env_file`), otherwise `/ready` returns 503.
- Volumes: `./logs` is bind-mounted (audit log on the host); Prometheus and Grafana keep
  data in the named volumes `prometheus-data` and `grafana-data`.

Single container:

```bash
docker run -d --name loan-api -p 8000:8000 --env-file .env -v ./logs:/app/logs iomega/northwind-loans-api:0.1.0
```

## Make targets

Run `make help`. Available now: `setup`, `test`, `profile` (writes
`reports/data_profile.json` and `reports/data_profile.md`), `clean-data` (writes
`data/processed/*.parquet` and `reports/data_quality_report.json`), `features` (previews
the credit-policy features and their correlation with the target), `train` (compares
pipelines, writes `reports/training_report.json` + `.md`, saves
`models/loan_offer_model_vN.pkl` + signed `.json`), `models` (lists saved versions), `predict-sample` (offers for `data/sample`, written to
`reports/sample_predictions.csv`).
⚠️ Pickle files execute code when loaded - only load models you created (see SECURITY.md).
`serve` (REST API, see above). `make test` treats warnings as errors.
`docker-build`, `up`, `down`, `logs` (see Docker above).
The others (`simulate-normal`, `simulate-drift`, `simulate-bad`, `monitor`) are filled in during
later steps.

## More

[CHANGELOG](CHANGELOG.md) · [TROUBLESHOOTING](TROUBLESHOOTING.md) ·
[CONTRIBUTING](CONTRIBUTING.md) · [SECURITY](SECURITY.md) ·
[CODE OF CONDUCT](CODE_OF_CONDUCT.md) · [LICENSE](LICENSE) (MIT)
