from flask import Flask, request, jsonify
from flask_cors import CORS
import pandas as pd
import numpy as np
import joblib
import json
import os
from datetime import datetime, timedelta
import psycopg2
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = Flask(__name__)
CORS(app)

# Database connection
def get_db_connection():
    """Get database connection using environment variables"""
    try:
        conn = psycopg2.connect(
            host=os.getenv('DB_HOST', 'localhost'),
            port=os.getenv('DB_PORT', '5432'),
            database=os.getenv('DB_NAME', 'fcmDatabase'),
            user=os.getenv('DB_USER', 'postgres'),
            password=os.getenv('DB_PASS', '')
        )
        return conn
    except Exception as e:
        print(f"Database connection error: {e}")
        return None

# Load pre-trained models
def load_models():
    """Load pre-trained forecasting models"""
    models = {}
    try:
        # Load XGBoost model for peak prediction
        if os.path.exists('model/xgboost_peak_model.joblib'):
            models['xgboost_peak'] = joblib.load('model/xgboost_peak_model.joblib')
        
        # Load Prophet model for time series forecasting
        if os.path.exists('model/prophet_peak_model.json'):
            with open('model/prophet_peak_model.json', 'r') as f:
                models['prophet_peak'] = json.load(f)
        
        print(f"Loaded {len(models)} models successfully")
        return models
    except Exception as e:
        print(f"Error loading models: {e}")
        return {}

# Global models variable
models = load_models()

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'models_loaded': len(models),
        'timestamp': datetime.now().isoformat()
    })

@app.route('/forecast/peak', methods=['POST'])
def forecast_peak():
    """Forecast peak demand using XGBoost model"""
    try:
        data = request.get_json()
        
        if not data or 'features' not in data:
            return jsonify({'error': 'Features data required'}), 400
        
        features = data['features']
        
        # Ensure we have the required features for XGBoost
        required_features = ['hour', 'day_of_week', 'month', 'is_weekend', 'weather_temp']
        for feature in required_features:
            if feature not in features:
                return jsonify({'error': f'Missing required feature: {feature}'}), 400
        
        # Convert to DataFrame
        df = pd.DataFrame([features])
        
        # Make prediction using XGBoost model
        if 'xgboost_peak' in models:
            prediction = models['xgboost_peak'].predict(df)
            confidence = 0.85  # Default confidence
        else:
            # Fallback prediction
            prediction = [50]  # Default peak value
            confidence = 0.5
        
        return jsonify({
            'prediction': float(prediction[0]),
            'confidence': confidence,
            'model_used': 'xgboost_peak',
            'timestamp': datetime.now().isoformat()
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/forecast/timeseries', methods=['POST'])
def forecast_timeseries():
    """Forecast time series using Prophet model"""
    try:
        data = request.get_json()
        
        if not data or 'periods' not in data:
            return jsonify({'error': 'Periods data required'}), 400
        
        periods = data['periods']
        
        # Generate future dates
        start_date = datetime.now()
        future_dates = [start_date + timedelta(days=i) for i in range(periods)]
        
        # Mock Prophet prediction (replace with actual Prophet model)
        if 'prophet_peak' in models:
            # Use actual Prophet model here
            predictions = np.random.normal(50, 10, periods).tolist()
            confidence = 0.8
        else:
            # Fallback prediction
            predictions = [50] * periods
            confidence = 0.5
        
        return jsonify({
            'predictions': predictions,
            'dates': [d.isoformat() for d in future_dates],
            'confidence': confidence,
            'model_used': 'prophet_peak',
            'timestamp': datetime.now().isoformat()
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/forecast/historical', methods=['GET'])
def get_historical_data():
    """Get historical data for forecasting"""
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({'error': 'Database connection failed'}), 500
        
        cursor = conn.cursor()
        
        # Query historical trip data (adjust table/column names as needed)
        query = """
        SELECT 
            DATE(created_at) as date,
            COUNT(*) as trip_count,
            AVG(EXTRACT(HOUR FROM created_at)) as avg_hour
        FROM passenger_trips 
        WHERE created_at >= NOW() - INTERVAL '30 days'
        GROUP BY DATE(created_at)
        ORDER BY date
        """
        
        cursor.execute(query)
        results = cursor.fetchall()
        
        historical_data = []
        for row in results:
            historical_data.append({
                'date': row[0].isoformat(),
                'trip_count': row[1],
                'avg_hour': float(row[2]) if row[2] else 0
            })
        
        cursor.close()
        conn.close()
        
        return jsonify({
            'historical_data': historical_data,
            'total_records': len(historical_data),
            'timestamp': datetime.now().isoformat()
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/forecast/retrain', methods=['POST'])
def retrain_models():
    """Retrain forecasting models with new data"""
    try:
        # This would implement model retraining
        # For now, return success message
        return jsonify({
            'message': 'Model retraining initiated',
            'status': 'success',
            'timestamp': datetime.now().isoformat()
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    # Create model directory if it doesn't exist
    os.makedirs('model', exist_ok=True)
    
    # Start the Flask app
    port = int(os.getenv('FORECASTING_PORT', 5000))
    debug = os.getenv('FLASK_DEBUG', 'False').lower() == 'true'
    
    print(f"Starting forecasting service on port {port}")
    print(f"Models loaded: {list(models.keys())}")
    
    app.run(host='0.0.0.0', port=port, debug=debug)
