## Lambda Function
## Layer Dependencies
## pydicom-layer version 2
## numpy-layer version 1
## Deployed in Region Ohio

import boto3
import json
import pydicom
import numpy as np

# Bucket where raw image files are dropped
destination_bucket_name = 'kirit-processed'
s3_resource = boto3.resource('s3')
s3_client = boto3.client('s3')

def lambda_handler(event, context):
    
    with open('/tmp/event', 'w', encoding='utf-8') as f:
        json.dump(event, f, ensure_ascii=False, indent=4)
    
    s3_client.upload_file('/tmp/event', destination_bucket_name, 'event.json')
    
    for record in event['Records']:
        source_bucket_name = record['s3']['bucket']['name']
        source_file_name = record['s3']['object']['key']
        
        source_file_name = source_file_name.replace('+', ' ')
        
        tmp_filename = '/tmp/tmp_dcm_file.dcm'
        s3_resource.Bucket(source_bucket_name).download_file(source_file_name, tmp_filename)
        
        ds = pydicom.read_file(str(tmp_filename)) 
        img = ds.pixel_array.astype(np.float32)
        
        with open('/tmp/tmp.npy', 'wb') as f:
            np.save(f, img)
        
        newname = source_file_name.replace('.dcm', '')
        
        # Infer label from the file, add label to name of file
        # Label will be infered from filename in "opencv_processing" lambda func
        # Rename the file to newname + '-label-' + label.npy
        
        # Random label for testing
        label = str(img[0][0] % 2)
        newname = newname + '-label-' + str(label) + '.npy'
        
        s3_client.upload_file('/tmp/tmp.npy', destination_bucket_name, newname)
    
    return {
        'statusCode': 200,
        'body': json.dumps(event)
    }
