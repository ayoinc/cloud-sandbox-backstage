import json
import os

def handler(event, context):
    """
    Lambda handler function.
    """
    environment = os.environ.get('ENVIRONMENT', 'unknown')
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Hello from ${{ values.name }}',
            'environment': environment
        })
    }
