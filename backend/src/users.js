import AWS from 'aws-sdk';
const doc = new AWS.DynamoDB.DocumentClient();
const USERS = process.env.USERS_TABLE;

export const get = async (event) => {
  const { userId } = event.pathParameters || {};
  const res = await doc.get({ TableName: USERS, Key: { userId } }).promise();
  return { statusCode: 200, body: JSON.stringify(res.Item || {}) };
};

export const update = async (event) => {
  const { userId } = event.pathParameters || {};
  const body = JSON.parse(event.body || '{}');
  await doc.update({
    TableName: USERS,
    Key: { userId },
    UpdateExpression: 'SET username = :u, bio = :b',
    ExpressionAttributeValues: { ':u': body.username || '', ':b': body.bio || '' },
  }).promise();
  return { statusCode: 204, body: '' };
};
