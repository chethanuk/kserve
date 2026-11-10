# Copyright 2026 The KServe Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os

import catboost as cb
import numpy as np
import pytest
from kserve.errors import InferenceError, ModelMissingError
from kserve.protocol.infer_type import InferInput, InferRequest

from catboostserver import CatBoostModel

# Real iris model trained by example_model/train_iris.py (not mocked).
EXAMPLE_MODEL_DIR = os.path.join(
    os.path.dirname(__file__), "..", "example_model", "model"
)
# Two real iris rows; the model predicts class 1 (versicolor) for both.
IRIS_ROWS = [[6.8, 2.8, 4.8, 1.4], [6.0, 3.4, 4.5, 1.6]]


@pytest.fixture
def iris_model():
    model = CatBoostModel("iris", EXAMPLE_MODEL_DIR)
    model.load()
    return model


@pytest.fixture
def regressor_dir(tmp_path):
    rng = np.random.default_rng(0)
    X = rng.random((50, 3))
    regressor = cb.CatBoostRegressor(
        iterations=5, verbose=0, allow_writing_files=False, thread_count=1
    )
    regressor.fit(X, X.sum(axis=1))
    regressor.save_model(str(tmp_path / "model.cbm"))
    return str(tmp_path), X[:2]


@pytest.mark.parametrize(
    "payload",
    [
        {"instances": IRIS_ROWS},
        {"inputs": IRIS_ROWS},
    ],
    ids=["v1-instances", "v1-inputs"],
)
def test_v1_classifier_returns_class_labels(iris_model, payload):
    # Raw CatBoost output would be three logits per row, not [1, 1].
    assert iris_model.predict(payload) == {"predictions": [1, 1]}


def test_v2_classifier_returns_flat_int64_class_labels(iris_model):
    request = InferRequest(
        model_name="iris",
        infer_inputs=[
            InferInput(name="input-0", shape=[2, 4], datatype="FP32", data=IRIS_ROWS)
        ],
    )

    output = iris_model.predict(request).outputs[0]

    assert output.datatype == "INT64"
    assert output.shape == [2]
    assert output.data == [1, 1]


def test_regressor_keeps_raw_values(regressor_dir):
    model_dir, rows = regressor_dir
    model = CatBoostModel("reg", model_dir)
    model.load()

    expected = cb.CatBoost().load_model(os.path.join(model_dir, "model.cbm"))

    response = model.predict({"instances": rows.tolist()})

    assert response == {"predictions": expected.predict(rows).tolist()}
    assert len(response["predictions"]) == 2


def _train_classifier(tmp_path, labels):
    """Trains a tiny real binary classifier whose class k is cluster k."""
    rng = np.random.default_rng(0)
    X = np.vstack([rng.normal(0, 0.1, (30, 3)), rng.normal(5, 0.1, (30, 3))])
    y = np.array([labels[0]] * 30 + [labels[1]] * 30)
    clf = cb.CatBoostClassifier(
        iterations=10, verbose=0, allow_writing_files=False, thread_count=1
    )
    clf.fit(X, y)
    clf.save_model(str(tmp_path / "model.cbm"))
    # One row from each cluster, ordered [class 1, class 0].
    return str(tmp_path), [[5.0, 5.0, 5.0], [0.0, 0.0, 0.0]]


@pytest.mark.parametrize(
    "labels, expected_v1, expected_v2_datatype, expected_v2_data",
    [
        ([0, 1], [1, 0], "INT64", [1, 0]),
        (["no", "yes"], ["yes", "no"], "BYTES", ["yes", "no"]),
    ],
    ids=["int-labels", "string-labels"],
)
def test_binary_classifier_returns_class_labels(
    tmp_path, labels, expected_v1, expected_v2_datatype, expected_v2_data
):
    model_dir, rows = _train_classifier(tmp_path, labels)
    model = CatBoostModel("clf", model_dir)
    model.load()

    assert model.predict({"instances": rows}) == {"predictions": expected_v1}

    request = InferRequest(
        model_name="clf",
        infer_inputs=[
            InferInput(name="input-0", shape=[2, 3], datatype="FP32", data=rows)
        ],
    )
    output = model.predict(request).outputs[0]
    assert output.datatype == expected_v2_datatype
    assert output.shape == [2]
    assert output.data == expected_v2_data


@pytest.mark.parametrize(
    "row", [IRIS_ROWS[0], [IRIS_ROWS[0]]], ids=["flat-1d", "nested-1xN"]
)
def test_single_row_returns_one_prediction(iris_model, row):
    assert iris_model.predict({"instances": row}) == {"predictions": [1]}


def test_load_without_model_file_raises(tmp_path):
    with pytest.raises(ModelMissingError):
        CatBoostModel("iris", str(tmp_path)).load()


def test_load_invalid_model_file_raises(tmp_path):
    (tmp_path / "model.cbm").write_bytes(b"not a catboost model")
    with pytest.raises(InferenceError, match="not be a valid CatBoost model"):
        CatBoostModel("iris", str(tmp_path)).load()


def test_predict_wrong_feature_count_raises(iris_model):
    with pytest.raises(InferenceError):
        iris_model.predict({"instances": [[1.0, 2.0]]})
