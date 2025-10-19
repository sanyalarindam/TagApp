import AWS from 'aws-sdk';
import { v4 as uuid } from 'uuid';

const doc = new AWS.DynamoDB.DocumentClient();
const POSTS = process.env.POSTS_TABLE;

// Like a post
export const likePost = async (event) => {
  try {
    const { postId } = event.pathParameters || {};
    const body = JSON.parse(event.body || '{}');
    const { userId } = body;

    if (!userId) {
      return { statusCode: 400, body: JSON.stringify({ error: 'userId required' }) };
    }
    try {
      // Only like if userId not already in likedBy
      await doc.update({
        TableName: POSTS,
        Key: { postId },
        UpdateExpression:
          'SET likes = if_not_exists(likes, :zero) + :inc, likedBy = list_append(if_not_exists(likedBy, :empty), :user)',
        ConditionExpression: 'attribute_not_exists(likedBy) OR NOT contains(likedBy, :userId)',
        ExpressionAttributeValues: {
          ':inc': 1,
          ':zero': 0,
          ':user': [userId],
          ':empty': [],
          ':userId': userId,
        },
      }).promise();
    } catch (err) {
      // If already liked, just return the current item (idempotent)
      if (err.code !== 'ConditionalCheckFailedException') throw err;
    }

    const result = await doc.get({ TableName: POSTS, Key: { postId } }).promise();
    return { statusCode: 200, body: JSON.stringify(result.Item) };
  } catch (e) {
    console.error(e);
    return { statusCode: 500, body: JSON.stringify({ error: 'Internal Server Error' }) };
  }
};

// Unlike a post
export const unlikePost = async (event) => {
  try {
    const { postId } = event.pathParameters || {};
    const body = JSON.parse(event.body || '{}');
    const { userId } = body;

    if (!userId) {
      return { statusCode: 400, body: JSON.stringify({ error: 'userId required' }) };
    }

    // Get current post to find userId index
    const current = await doc.get({ TableName: POSTS, Key: { postId } }).promise();
    const likedBy = current.Item?.likedBy || [];
    const idx = likedBy.indexOf(userId);
    
    if (idx === -1) {
      // User hasn't liked this post
      return { statusCode: 200, body: JSON.stringify(current.Item) };
    }

    // Remove userId from likedBy array and decrement likes count (only if currently liked)
    await doc
      .update({
        TableName: POSTS,
        Key: { postId },
        UpdateExpression: `REMOVE likedBy[${idx}] SET likes = if_not_exists(likes, :zero) - :dec`,
        ConditionExpression: 'contains(likedBy, :userId)',
        ExpressionAttributeValues: {
          ':dec': 1,
          ':zero': 0,
          ':userId': userId,
        },
      })
      .promise();

    const result = await doc.get({ TableName: POSTS, Key: { postId } }).promise();
    return { statusCode: 200, body: JSON.stringify(result.Item) };
  } catch (e) {
    console.error(e);
    return { statusCode: 500, body: JSON.stringify({ error: 'Internal Server Error' }) };
  }
};

// Save a post
export const savePost = async (event) => {
  try {
    const { postId } = event.pathParameters || {};
    const body = JSON.parse(event.body || '{}');
    const { userId } = body;

    if (!userId) {
      return { statusCode: 400, body: JSON.stringify({ error: 'userId required' }) };
    }

    try {
      await doc.update({
        TableName: POSTS,
        Key: { postId },
        UpdateExpression:
          'SET saves = if_not_exists(saves, :zero) + :inc, savedBy = list_append(if_not_exists(savedBy, :empty), :user)',
        ConditionExpression: 'attribute_not_exists(savedBy) OR NOT contains(savedBy, :userId)',
        ExpressionAttributeValues: {
          ':inc': 1,
          ':zero': 0,
          ':user': [userId],
          ':empty': [],
          ':userId': userId,
        },
      }).promise();
    } catch (err) {
      if (err.code !== 'ConditionalCheckFailedException') throw err;
    }

    const result = await doc.get({ TableName: POSTS, Key: { postId } }).promise();
    return { statusCode: 200, body: JSON.stringify(result.Item) };
  } catch (e) {
    console.error(e);
    return { statusCode: 500, body: JSON.stringify({ error: 'Internal Server Error' }) };
  }
};

// Unsave a post
export const unsavePost = async (event) => {
  try {
    const { postId } = event.pathParameters || {};
    const body = JSON.parse(event.body || '{}');
    const { userId } = body;

    if (!userId) {
      return { statusCode: 400, body: JSON.stringify({ error: 'userId required' }) };
    }

    const current = await doc.get({ TableName: POSTS, Key: { postId } }).promise();
    const savedBy = current.Item?.savedBy || [];
    const idx = savedBy.indexOf(userId);
    
    if (idx === -1) {
      return { statusCode: 200, body: JSON.stringify(current.Item) };
    }

    await doc
      .update({
        TableName: POSTS,
        Key: { postId },
        UpdateExpression: `REMOVE savedBy[${idx}] SET saves = if_not_exists(saves, :zero) - :dec`,
        ConditionExpression: 'contains(savedBy, :userId)',
        ExpressionAttributeValues: {
          ':dec': 1,
          ':zero': 0,
          ':userId': userId,
        },
      })
      .promise();

    const result = await doc.get({ TableName: POSTS, Key: { postId } }).promise();
    return { statusCode: 200, body: JSON.stringify(result.Item) };
  } catch (e) {
    console.error(e);
    return { statusCode: 500, body: JSON.stringify({ error: 'Internal Server Error' }) };
  }
};

// Add a comment
export const addComment = async (event) => {
  try {
    const { postId } = event.pathParameters || {};
    const body = JSON.parse(event.body || '{}');
    const { userId, username, text } = body;

    if (!userId || !text) {
      return { statusCode: 400, body: JSON.stringify({ error: 'userId and text required' }) };
    }

    const comment = {
      commentId: uuid(),
      userId,
      username: username || 'Anonymous',
      text,
      createdAt: new Date().toISOString(),
    };

    await doc.update({
      TableName: POSTS,
      Key: { postId },
      UpdateExpression: 'SET comments = list_append(if_not_exists(comments, :empty), :comment)',
      ExpressionAttributeValues: {
        ':comment': [comment],
        ':empty': [],
      },
    }).promise();

    const result = await doc.get({ TableName: POSTS, Key: { postId } }).promise();
    return { statusCode: 200, body: JSON.stringify(result.Item) };
  } catch (e) {
    console.error(e);
    return { statusCode: 500, body: JSON.stringify({ error: 'Internal Server Error' }) };
  }
};
