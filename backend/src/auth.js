import AWS from 'aws-sdk';
import { v4 as uuid } from 'uuid';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

const doc = new AWS.DynamoDB.DocumentClient();
const USERS = process.env.USERS_TABLE;
const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-me';

export const register = async (event) => {
  try {
    const body = JSON.parse(event.body || '{}');
    const { username, password } = body;
    if (!username || !password) {
      return { statusCode: 400, body: 'username and password are required' };
    }

    // Check if username exists
    const existing = await doc
      .scan({
        TableName: USERS,
        FilterExpression: 'username = :u',
        ExpressionAttributeValues: { ':u': username },
        ProjectionExpression: 'userId, username',
      })
      .promise();

    if ((existing.Items || []).length > 0) {
      return { statusCode: 409, body: 'username already taken' };
    }

    const userId = uuid();
    const passwordHash = await bcrypt.hash(password, 10);

    const item = {
      userId,
      username,
      passwordHash,
      bio: '',
      uploads: [],
      createdAt: new Date().toISOString(),
    };

    await doc.put({ TableName: USERS, Item: item }).promise();

    const token = jwt.sign({ sub: userId, username }, JWT_SECRET, {
      expiresIn: '7d',
    });

    return {
      statusCode: 201,
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ userId, username, token }),
    };
  } catch (e) {
    console.error(e);
    return { statusCode: 500, body: 'Internal Server Error' };
  }
};

export const login = async (event) => {
  try {
    const body = JSON.parse(event.body || '{}');
    const { username, password } = body;
    if (!username || !password) {
      return { statusCode: 400, body: 'username and password are required' };
    }

    const data = await doc
      .scan({
        TableName: USERS,
        FilterExpression: 'username = :u',
        ExpressionAttributeValues: { ':u': username },
        Limit: 1,
      })
      .promise();

    const user = (data.Items || [])[0];
    if (!user) return { statusCode: 401, body: 'invalid credentials' };

    const ok = await bcrypt.compare(password, user.passwordHash || '');
    if (!ok) return { statusCode: 401, body: 'invalid credentials' };

    const token = jwt.sign({ sub: user.userId, username: user.username }, JWT_SECRET, {
      expiresIn: '7d',
    });

    return {
      statusCode: 200,
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ userId: user.userId, username: user.username, token }),
    };
  } catch (e) {
    console.error(e);
    return { statusCode: 500, body: 'Internal Server Error' };
  }
};
