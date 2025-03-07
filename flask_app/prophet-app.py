from flask import Flask, request, jsonify
import pandas as pd
from prophet import Prophet 

# sample test curl: 
## curl -X POST -H "Content-Type: application/json" -d '{'data': [[0, ['2023-01-01', '2023-01-02'], [1, 2], 1]]}' http://127.0.0.1:5000/forecast

app = Flask(__name__)

# The function to convert Celsius to Fahrenheit
def build_model(df):
    data = df.sort_values('ds').reset_index(drop=True)

    m = Prophet() 
    m.fit(data)

    return m

def forecast_data(m, periods):
    future = m.make_future_dataframe(periods=periods)
     
    forecast = m.predict(future)

    # only return forecasted rows
    return forecast[-periods:] 

@app.route('/forecast', methods=['POST'])
def forecast():
    # Get JSON data from request
    data = request.get_json()

    #debug
    print("Received Input: %s" %str(data))
    app.logger.info("Received Input: %s" %str(data))

    # Check if the 'data' key exists in the received JSON
    if 'data' not in data:
        return jsonify({'error': 'Missing data key in request'}), 400

    # Extract the 'data' list from the received JSON
    data_list = data['data'][0]

    dates = data_list[1]
    values = data_list[2]
    periods = data_list[3]
    df = pd.DataFrame({'ds': dates, 'y':values})

    m = build_model(df)
    forecast = forecast_data(m, periods)

    return jsonify({'data': [[0, forecast.to_json(orient='records')]]})

if __name__ == '__main__':
    app.run(debug=True)