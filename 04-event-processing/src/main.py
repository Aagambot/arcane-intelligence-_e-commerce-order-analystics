import boto3
import os
import json
from datetime import datetime

# Initialize Clients
dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')
ses = boto3.client('ses') # New SES client

def handler(event, context):
    table_name = os.environ['DYNAMODB_TABLE']
    bucket_name = os.environ['REPORTS_BUCKET']
    admin_email = os.environ.get('ADMIN_EMAIL', 'aagammehta373@gmail.com')
    
    table = dynamodb.Table(table_name)
    response = table.scan()
    items = response.get('Items', [])
    
    total_revenue = sum(float(item.get('amount', 0)) for item in items)
    order_count = len(items)
    
    report_text = f"Daily Report - {datetime.now().date()}\nTotal Orders: {order_count}\nTotal Revenue: ${total_revenue:.2f}"
    
    # 1. Save to S3
    s3.put_object(Bucket=bucket_name, Key=f"report_{datetime.now().date()}.json", Body=report_text)
    
    # 2. Send Email via SES
    ses.send_email(
        Source=admin_email,
        Destination={'ToAddresses': [admin_email]},
        Message={
            'Subject': {'Data': f'E-Commerce Daily Report: {datetime.now().date()}'},
            'Body': {'Text': {'Data': report_text}}
        }
    )
    
    return {'statusCode': 200, 'body': "Report generated and email sent!"}