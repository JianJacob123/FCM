import os
import json
import numpy as np
import pandas as pd
from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib

app = Flask(__name__)
CORS(app)

MODEL_PATH = os.environ.get("MODEL_PATH", "demand_forecast_model.pkl")
model = joblib.load(MODEL_PATH)


def to_serializable(obj):
    if isinstance(obj, (np.integer,)):
        return int(obj)
    if isinstance(obj, (np.floating,)):
        return float(obj)
    if isinstance(obj, np.ndarray):
        return obj.tolist()
    return obj


@app.get("/health")
def health():
    return jsonify({"status": "ok"})


@app.post("/forecast")
def forecast():
    try:
        payload = request.get_json(force=True)

        # Accept either: {"records": [{col:value,...}, ...]}
        # or: {"columns": [..], "features": [[..],[..]]}
        # or fallback: {"features": [[..]]} -> numpy array

        df = None
        if isinstance(payload, dict) and "records" in payload:
            df = pd.DataFrame(payload["records"])  # list[dict]
        elif isinstance(payload, dict) and "columns" in payload and "features" in payload:
            df = pd.DataFrame(payload["features"], columns=payload["columns"])  # list[list]
        elif isinstance(payload, dict) and "features" in payload:
            # Best-effort for pure numeric arrays
            arr = np.array(payload["features"], dtype=float)
            # Try to convert to DataFrame if model expects DataFrame-like input
            try:
                df = pd.DataFrame(arr)
            except Exception:
                df = None

        # Prophet models require a DataFrame with at least 'ds' column
        # Many sklearn pipelines also expect DataFrame with named columns.
        X = df if df is not None else np.array(payload["features"], dtype=float)

        preds = model.predict(X)

        # Ensure JSON-serializable output
        if isinstance(preds, pd.DataFrame):
            # Prefer common Prophet columns if present
            if set(["ds", "yhat"]).issubset(preds.columns):
                payload = preds[["ds", "yhat"]].astype({"ds": str}).to_dict(orient="records")
            else:
                # Fallback to full DataFrame
                payload = preds.to_dict(orient="records")
        elif isinstance(preds, (np.ndarray, list)):
            payload = to_serializable(np.asarray(preds))
        else:
            # Last resort: string representation
            payload = str(preds)

        return app.response_class(
            response=json.dumps({"predictions": payload}),
            mimetype="application/json",
        )
    except Exception as e:
        return jsonify({"error": str(e)}), 400


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5001))
    app.run(host="0.0.0.0", port=port)

from flask import Flask, render_template, request, jsonify
import pandas as pd
import joblib

app = Flask(__name__)

# Load the trained model
model = joblib.load("demand_forecast_model.pkl")

@app.route("/")
def home():
    return render_template("index.html")

# Forecast API endpoint
@app.route("/forecast", methods=["POST"])
def forecast():
    # Example: user sends a date range
    data = request.json
    future_dates = pd.date_range(start=data["start"], end=data["end"], freq="H")
    future = pd.DataFrame({"ds": future_dates})

    forecast = model.predict(future)
    results = forecast[["ds","yhat","yhat_lower","yhat_upper"]].to_dict(orient="records")

    return jsonify(results)

if __name__ == "__main__":
    app.run(debug=True)
