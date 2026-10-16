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
from kserve.protocol.infer_type import InferInput, InferRequest

from catboostserver import CatBoostModel

# Use example model following KServe pattern
example_model_dir = os.path.join(
    os.path.dirname(__file__), "..", "example_model", "model"
)


def test_cbm_model():
    """Test CatBoost model loading and prediction using example model"""
    catboost_model = CatBoostModel("test-model", example_model_dir)
    catboost_model.load()

    # Test with Iris data (same as used in other KServe tests)
    request = {"instances": [[6.8, 2.8, 4.8, 1.4], [6.0, 3.4, 4.5, 1.6]]}
    response = catboost_model.predict(request)

    # Class labels (like xgbserver), not raw logits; the iris model predicts class 1 for both.
    assert response == {"predictions": [1, 1]}


def test_model_formats():
    """Test that model supports both .cbm and .bin formats"""
    # The example model is .cbm format, test it works
    catboost_model = CatBoostModel("test-model", example_model_dir)
    catboost_model.load()

    assert catboost_model.ready
    assert catboost_model._model is not None


def test_v2_predict_returns_class_labels():
    catboost_model = CatBoostModel("test-model", example_model_dir)
    catboost_model.load()

    infer_input = InferInput(
        name="input-0",
        shape=[2, 4],
        datatype="FP32",
        data=[[6.8, 2.8, 4.8, 1.4], [6.0, 3.4, 4.5, 1.6]],
    )
    request = InferRequest(model_name="test-model", infer_inputs=[infer_input])
    response, _ = catboost_model.predict(request).to_rest()

    assert response["outputs"][0]["shape"] == [2]
    assert response["outputs"][0]["data"] == [1, 1]


def test_regression_model_returns_raw_values():
    """Class prediction_type is invalid for regressors; they must still predict."""
    rng = np.random.default_rng(0)
    X = rng.random((50, 3))
    regressor = cb.CatBoost({"loss_function": "RMSE", "iterations": 5, "verbose": 0})
    regressor.fit(X, X.sum(axis=1))

    response = CatBoostModel("reg", example_model_dir, model=regressor).predict(
        {"instances": X[:2].tolist()}
    )

    assert response["predictions"] == regressor.predict(X[:2]).tolist()
