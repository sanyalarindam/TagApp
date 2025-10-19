import boto3
import json
import base64
import sys
import os
from botocore.config import Config

# AWS configuration
AWS_REGION = "us-west-2"
MODEL_ID = "us.twelvelabs.pegasus-1-2-v1:0"  # Pegasus model for video understanding

def encode_video_to_base64(file_path):
    """Read a video file and return its base64-encoded string."""
    with open(file_path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")

def check_video_match(video_path, description):
    """
    Analyzes a video and description using TwelveLabs Pegasus via AWS Bedrock.
    Returns True if the video matches the description, False otherwise.
    Keeps print logs for runtime transparency and debugging.
    """
    # Create Bedrock runtime client
    print("Initializing AWS Bedrock client...")
    bedrock_client = boto3.client(
        "bedrock-runtime",
        region_name=AWS_REGION,
        config=Config(read_timeout=300, connect_timeout=60)
    )
    # Check file size
    size_mb = os.path.getsize(video_path) / (1024 * 1024)
    print(f"Video file size: {size_mb:.2f} MB")
    if size_mb > 15:
        print("Warning: file is large. Consider uploading to S3 and using a presigned URL instead.\n")
    # Encode video as base64
    print("Encoding video to base64...")
    video_b64 = encode_video_to_base64(video_path)
    print("Encoding complete.\n")
    # Construct the payload according to official Pegasus model documentation
    payload = {
        "inputPrompt": f"Does this video match the following description? "
                        f"Answer yes or no with explanation: {description}",
        "mediaSource": {
            "base64String": video_b64
        },
        "temperature": 0.0
    }
    print(f"Invoking TwelveLabs Pegasus model ({MODEL_ID}) in AWS region {AWS_REGION}...\n")
    # Invoke model
    try:
        response = bedrock_client.invoke_model(
            modelId=MODEL_ID,
            body=json.dumps(payload),
            contentType="application/json",
            accept="application/json"
        )
        # Read and parse response
        raw_body = response["body"].read()
        result_json = json.loads(raw_body.decode("utf-8"))
        print("--- Raw Response JSON ---")
        print(json.dumps(result_json, indent=2))
        # Extract possible output message text
        message = (
            result_json.get("message")
            or result_json.get("outputText")
            or result_json.get("text")
            or ""
        ).strip()
        print("\n--- Model Output ---")
        print(message)
        # Derive boolean result
        if "yes" in message.lower():
            print("\nResult: The video matches the description ✅")
            return True
        elif "no" in message.lower():
            print("\nResult: The video doesn't match the description ❌")
            return False
        # Fallback if unclear
        print("\nResult: The model’s answer was ambiguous — review message above.")
        return False
    except Exception as e:
        print(f"Error invoking model: {str(e)}")
        return False

# --- Terminal Entry Point ---
if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage:\n python3 check_video.py /path/to/video.mp4 \"description text\"")
        sys.exit(1)
    video_path = sys.argv[1]
    description = " ".join(sys.argv[2:]).strip()
    if not os.path.isfile(video_path):
        print(f"Error: file not found - {video_path}")
        sys.exit(1)
    result = check_video_match(video_path, description)
    print(f"\nFinal Boolean Result: {result}")
