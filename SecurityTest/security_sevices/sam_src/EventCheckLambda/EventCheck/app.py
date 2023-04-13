import json
          
def lambda_handler(event, context):
    # Function Logsとして出力
    print(event) 

    # Function Responseとして出力
    response = {
        'statusCode': 200,
        'body': json.dumps(event)
    }

    return response