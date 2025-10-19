import AWS from 'aws-sdk';

const s3 = new AWS.S3({ signatureVersion: 'v4' });
const BUCKET = process.env.S3_BUCKET;

export const handler = async (event) => {
  try {
    const { objectKey } = event.pathParameters || {};
    if (!objectKey) {
      return { statusCode: 400, body: 'Missing objectKey' };
    }

    const url = await s3.getSignedUrlPromise('getObject', {
      Bucket: BUCKET,
      Key: decodeURIComponent(objectKey),
      Expires: 3600, // 1 hour
    });

    return {
      statusCode: 200,
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ url }),
    };
  } catch (err) {
    console.error(err);
    return { statusCode: 500, body: 'Internal Server Error' };
  }
};
