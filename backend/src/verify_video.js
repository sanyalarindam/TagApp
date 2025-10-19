
import AWS from 'aws-sdk';

export async function verifyVideoWithTag(s3Bucket, s3Key, description) {
  const lambda = new AWS.Lambda();
  const payload = {
    video_s3_bucket: s3Bucket,
    video_s3_key: s3Key,
    description: description,
  };
  const params = {
    FunctionName: 'tagapp-backend-dev-verifyVideo', // Update if your stage is not 'dev'
    Payload: JSON.stringify(payload),
  };
  const response = await lambda.invoke(params).promise();
  const result = JSON.parse(response.Payload);
  if (result.statusCode !== 200) {
    let detail = '';
    try {
      const body = JSON.parse(result.body || '{}');
      detail = body.error || JSON.stringify(body);
    } catch (_) {
      detail = String(result.body || '');
    }
    throw new Error(`Verification Lambda failed: ${detail}`);
  }
  const body = JSON.parse(result.body);
  return body.verified;
}
