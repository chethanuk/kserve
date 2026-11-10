# CatBoost Server

[CatBoost](https://catboost.ai/) is a high-performance open source library for gradient boosting on decision trees.

To start the server locally for development needs, run the following command under this folder in your github repository.

```bash
uv venv
uv run --active python -m catboostserver --model_dir /path/to/model_dir --model_name catboost-model
```

## Predictions

Classifiers return the predicted class label for each row (`prediction_type="Class"`), not the raw
logits that `catboost.CatBoost.predict()` returns by default. Regressors return the raw predicted value (CatBoost's default `RawFormulaVal`). For Poisson and Tweedie losses this is log-space and differs from `CatBoostRegressor.predict()`, which applies the exponent.

The iris model in `example_model/model/model.cbm` is produced by `example_model/train_iris.py`.
Try it locally:

```bash
uv sync
uv run --active python -m catboostserver --model_dir example_model/model --model_name catboost-iris --http_port 8080
```

```bash
curl -H 'Content-Type: application/json' localhost:8080/v1/models/catboost-iris:predict \
  -d '{"instances":[[6.8,2.8,4.8,1.4],[6.0,3.4,4.5,1.6]]}'
```

```json
{"predictions":[1,1]}
```

```bash
curl -H 'Content-Type: application/json' localhost:8080/v2/models/catboost-iris/infer \
  -d '{"inputs":[{"name":"input-0","shape":[2,4],"datatype":"FP32","data":[[6.8,2.8,4.8,1.4],[6.0,3.4,4.5,1.6]]}]}'
```

```json
{"model_name":"catboost-iris","model_version":null,"id":"f2ea489e-d3ef-4d04-96a8-2263f2caf6b3","parameters":null,"outputs":[{"name":"output-0","shape":[2],"datatype":"INT64","parameters":null,"data":[1,1]}]}
```

## Development

Install the development dependencies with:

```bash
make dev_install
```

To run tests:

```bash
make test
```

To run static type checks:

```bash
mypy --ignore-missing-imports catboostserver
```

## Building your own CatBoost image

You can build and publish your own image for development needs. Please ensure that you modify the inferenceservice files for the `image` and add the `imagePullPolicy: Always`.

To build your own image, navigate up to the `python` directory and run:

```bash
docker build -t {username}/catboostserver -f catboost.Dockerfile .
```

To push your image:

```bash
docker push {username}/catboostserver
```