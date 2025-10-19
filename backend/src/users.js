import AWS from 'aws-sdk';
const doc = new AWS.DynamoDB.DocumentClient();
const USERS = process.env.USERS_TABLE;
const POSTS = process.env.POSTS_TABLE;

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

// Compute user rank based on number of tags/posts created.
// Dense ranking: users with the same count share the same rank, next rank increments by 1.
export const rank = async (event) => {
  try {
    const { userId } = event.pathParameters || {};
    if (!userId) return { statusCode: 400, body: 'userId is required' };

    // Scan posts and count by userId (OK for small demo; use GSI in production)
    const postsScan = await doc.scan({ TableName: POSTS, ProjectionExpression: 'userId' }).promise();
    const counts = new Map();
    for (const p of postsScan.Items || []) {
      const uid = p.userId;
      if (!uid) continue;
      counts.set(uid, (counts.get(uid) || 0) + 1);
    }

    const totalUsers = counts.size;
    const userCount = counts.get(userId) || 0;
    // Build sorted unique counts desc for dense ranking
    const uniqueCountsDesc = Array.from(new Set(counts.values())).sort((a, b) => b - a);
    const rank = uniqueCountsDesc.length === 0
      ? 0
      : (uniqueCountsDesc.indexOf(userCount) + 1);

    return {
      statusCode: 200,
      body: JSON.stringify({ userId, tagCount: userCount, rank, totalUsers })
    };
  } catch (e) {
    console.error('rank error', e);
    return { statusCode: 500, body: 'Internal Server Error' };
  }
};
