## Lambda Function
## Layer Dependencies
## opencv-contrib-layer version 1 
## Deployed in Region Ohio

import boto3
import json
import cv2
import numpy as np

def lambda_handler(event, context):

    s3_resource = boto3.resource('s3')
    s3_client = boto3.client('s3')
    bucket = 'kirit-processed'
    
    with open('/tmp/event', 'w', encoding='utf-8') as f:
        json.dump(event, f, ensure_ascii=False, indent=4)
    
    s3_client.upload_file('/tmp/event', bucket, 'event.json')
    
    for record in event['Records']:
        source_bucket_name = record['s3']['bucket']['name']
        source_file_name = record['s3']['object']['key']
        
        ## Infer label from source file name
        source_file_name = source_file_name.replace('+', ' ')
        label = source_file_name.split('-label-')[-1].split('.npy')[0]
        label = int(float(label))
        
        tmp_filename = '/tmp/tmp_dcm_file.npy'
        s3_resource.Bucket(source_bucket_name).download_file(source_file_name, tmp_filename)
        
        pixels = np.load(tmp_filename)
        
        resized_pixels = cv2.resize(pixels, (512, 512), interpolation = cv2.INTER_AREA)
        
        image = ((resized_pixels / 65535) * 255).astype(np.int)
        
        # add numpy assertion check to make sure image was resized

        with open('/tmp/data', 'w', encoding='utf-8') as f:
            json.dump(image.tolist(), f, ensure_ascii=False, indent=4)
    
        s3_client.upload_file('/tmp/data', bucket, 'data.json')
        
        cv2.imwrite('/tmp/tmp.png', image)
        
        newname = source_file_name.replace('.npy', '.png')
        
        ## Add additional logs by dumping the event to S3
        
        # with open('/tmp/event', 'w', encoding='utf-8') as f:
        #     json.dump(event, f, ensure_ascii=False, indent=4)
        # s3_client.upload_file('/tmp/event', bucket, 'event.json')
        
        if 'Training' in newname:
            newname = 'train/' + str(label) + '/' + newname
            
        if 'Test' in newname:
            newname = 'test/' + str(label) + '/' + newname
        
        s3_client.upload_file('/tmp/tmp.png', bucket, newname)
        
        # Need to update role to LambdaS3RoleFull (No access to delete bucket in AWS Innovation Labs)
        # s3_client.delete_object(Bucket=source_bucket_name, Key=source_file_name)
        
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }
