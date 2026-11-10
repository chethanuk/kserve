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

"""Regenerates model/model.cbm, the iris model used by the tests and samples.

Run from this directory (scikit-learn is only needed here, not by the server):

    uv run --no-project --with scikit-learn --with "catboost~=1.2.7" python train_iris.py

The seed is fixed and training is single threaded, so predictions are
identical on every run. The .cbm bytes still differ between runs because
CatBoost embeds a random model GUID and the training time in the file, so
compare predictions, never file hashes. The checked-in model.cbm was generated
with catboost 1.2.10 (the version in uv.lock); the "~=1.2.7" range above only
needs to produce the same predictions, which the tests assert.
"""

import os

from catboost import CatBoostClassifier
from sklearn.datasets import load_iris

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "model", "model.cbm")

X, y = load_iris(return_X_y=True)
model = CatBoostClassifier(
    iterations=50,
    depth=3,
    learning_rate=0.1,
    loss_function="MultiClass",
    random_seed=0,
    thread_count=1,
    verbose=0,
    allow_writing_files=False,
)
model.fit(X, y)
model.save_model(OUT, format="cbm")
print(f"saved {OUT}; train accuracy {(model.predict(X).ravel() == y).mean():.4f}")
