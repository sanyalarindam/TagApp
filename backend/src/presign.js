import AWS from 'aws-sdk';
import { v4 as uuid } from 'uuid';

const s3 = new AWS.S3({ signatureVersion: 'v4' });
const BUCKET = process.env.S3_BUCKET;

export const handler = async (event) => {
  try {
    const body = JSON.parse(event.body || '{}');
    const contentType = body.contentType || 'video/mp4';
    const key = `videos/${uuid()}.mp4`;

    const url = await s3.getSignedUrlPromise('putObject', {
      Bucket: BUCKET,
      Key: key,
      ContentType: contentType,
      Expires: 3600,
    });

    return {
      statusCode: 200,
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ uploadUrl: url, objectKey: key }),
    };
  } catch (err) {
    console.error(err);
    return { statusCode: 500, body: 'Internal Server Error' };
  }
};
