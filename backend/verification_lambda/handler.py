import json
import boto3
import base64
import os
from botocore.config import Config

def encode_video_to_base64(file_path):
    with open(file_path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")

def _region_from_arn(arn: str) -> str:
    try:
        return arn.split(":")[3]
    except Exception:
        return os.environ.get("BEDROCK_REGION", "us-west-2")


def check_video_match(video_path, description):
    # Prefer invoking via an Inference Profile (required for Pegasus). If not provided, fallback to foundation model ID.
    inference_profile_arn = os.environ.get("BEDROCK_INFERENCE_PROFILE_ARN", "").strip()
    foundation_model_id = os.environ.get("BEDROCK_FOUNDATION_MODEL_ID", "twelvelabs.pegasus-1-2-v1:0").strip()

    if inference_profile_arn:
        aws_region = _region_from_arn(inference_profile_arn)
        model_identifier = inference_profile_arn  # Bedrock accepts Inference Profile ARN/ID here
    else:
        # Foundation model ID path (Pegasus generally requires an inference profile; this may fail with ValidationException)
        aws_region = os.environ.get("BEDROCK_REGION", "us-east-1")
        model_identifier = foundation_model_id

    bedrock_client = boto3.client(
        "bedrock-runtime",
        region_name=aws_region,
        config=Config(read_timeout=300, connect_timeout=60)
    )
    size_mb = os.path.getsize(video_path) / (1024 * 1024)
    if size_mb > 15:
        print("Warning: file is large. Consider uploading to S3 and using a presigned URL instead.")
    video_b64 = encode_video_to_base64(video_path)
    payload = {
        "inputPrompt": f"Does this video match the following description? Answer yes or no with explanation: {description}",
        "mediaSource": {"base64String": video_b64},
        "temperature": 0.0
    }
    response = bedrock_client.invoke_model(
        modelId=model_identifier,
        body=json.dumps(payload),
        contentType="application/json",
        accept="application/json"
    )
    raw_body = response["body"].read()
    result_json = json.loads(raw_body.decode("utf-8"))
    message = (
        result_json.get("message")
        or result_json.get("outputText")
        or result_json.get("text")
        or ""
    ).strip()
    if "yes" in message.lower():
        return True, message
    elif "no" in message.lower():
        return False, message
    return False, message

def lambda_handler(event, context):
    # Expect event to have 'video_s3_bucket', 'video_s3_key', 'description'
    bucket = event.get('video_s3_bucket')
    key = event.get('video_s3_key')
    description = event.get('description', '')

    tmp_file = f"/tmp/{os.path.basename(key)}"
    s3 = boto3.client('s3')
    try:
        s3.download_file(bucket, key, tmp_file)
        result, message = check_video_match(tmp_file, description)
        return {
            'statusCode': 200,
            'body': json.dumps({'verified': result, 'message': message})
        }
    except Exception as e:
        # Return detailed error for easier debugging upstream
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
    finally:
        try:
            if os.path.exists(tmp_file):
                os.remove(tmp_file)
        except Exception:
            pass
