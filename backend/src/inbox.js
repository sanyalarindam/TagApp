import AWS from 'aws-sdk';
const doc = new AWS.DynamoDB.DocumentClient();
const INBOX = process.env.INBOX_TABLE;

export const get = async (event) => {
  const { userId } = event.pathParameters || {};
  const res = await doc.query({
    TableName: INBOX,
    KeyConditionExpression: 'userId = :uid',
    ExpressionAttributeValues: { ':uid': userId },
    ScanIndexForward: false,
  }).promise();
  return { statusCode: 200, body: JSON.stringify(res.Items || []) };
};
