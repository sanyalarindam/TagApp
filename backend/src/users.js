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
  const { username, bio } = body;
  if (!username) {
    return { statusCode: 400, body: 'username is required' };
  }
  // Check if username is unique (excluding self)
  const existing = await doc
    .scan({
      TableName: USERS,
      FilterExpression: 'username = :u AND userId <> :id',
      ExpressionAttributeValues: { ':u': username, ':id': userId },
      ProjectionExpression: 'userId, username',
    })
    .promise();
  if ((existing.Items || []).length > 0) {
    return { statusCode: 409, body: 'username already taken' };
  }
  // Update user profile
  await doc
    .update({
      TableName: USERS,
      Key: { userId },
      UpdateExpression: 'SET username = :u, bio = :b',
      ExpressionAttributeValues: { ':u': username, ':b': bio || '' },
    })
    .promise();

  // Propagate username change to all posts and comments by this user
  // (scan all posts, update username in posts and in comments array)
  const POSTS = process.env.POSTS_TABLE;
  const posts = await doc.scan({ TableName: POSTS }).promise();
  for (const post of posts.Items || []) {
    let changed = false;
    // Update post username if this is the user's post
    if (post.userId === userId && post.username !== username) {
      await doc.update({
        TableName: POSTS,
        Key: { postId: post.postId },
        UpdateExpression: 'SET username = :u',
        ExpressionAttributeValues: { ':u': username },
      }).promise();
      changed = true;
    }
    // Update comments array
    if (Array.isArray(post.comments)) {
      let updated = false;
      const newComments = post.comments.map((c) => {
        if (c.userId === userId && c.username !== username) {
          updated = true;
          return { ...c, username };
        }
        return c;
      });
      if (updated) {
        await doc.update({
          TableName: POSTS,
          Key: { postId: post.postId },
          UpdateExpression: 'SET comments = :c',
          ExpressionAttributeValues: { ':c': newComments },
        }).promise();
        changed = true;
      }
    }
    // Optionally, update other fields (e.g., likedBy, savedBy) if you want username there
    if (changed) {
      // log or count
    }
  }
  return { statusCode: 204, body: '' };
};
