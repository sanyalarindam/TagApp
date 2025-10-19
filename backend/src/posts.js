import AWS from 'aws-sdk';
import { v4 as uuid } from 'uuid';

const doc = new AWS.DynamoDB.DocumentClient();
const s3 = new AWS.S3({ signatureVersion: 'v4' });
const POSTS = process.env.POSTS_TABLE;
const USERS = process.env.USERS_TABLE;
const INBOX = process.env.INBOX_TABLE;
const BUCKET = process.env.S3_BUCKET;

export const create = async (event) => {
  try {
    const body = JSON.parse(event.body || '{}');
    const postId = uuid();
    const now = new Date().toISOString();

    // Resolve tagged users by username, if provided
    const taggedUsernames = Array.isArray(body.taggedUsernames)
      ? body.taggedUsernames.filter(Boolean).map((s) => String(s).trim().toLowerCase())
      : [];
    let resolvedFriendIds = [];
    if (taggedUsernames.length > 0) {
      try {
        const usersScan = await doc.scan({
          TableName: USERS,
          ProjectionExpression: 'userId, username',
        }).promise();
        const wanted = new Set(taggedUsernames);
        for (const u of usersScan.Items || []) {
          const uname = (u.username || '').toString().trim().toLowerCase();
          if (wanted.has(uname)) {
            resolvedFriendIds.push(u.userId);
          }
        }
      } catch (e) {
        console.error('Failed resolving taggedUsernames:', e);
      }
    }

    const item = {
      postId,
      userId: body.userId,
      username: body.username,
      videoUrl: body.videoUrl, // Now expects full S3 URL from client
      description: body.description || '',
      hashtags: body.hashtags || [],
      // Store resolved friend IDs; fallback to provided IDs if any
      taggedFriends: (resolvedFriendIds.length ? resolvedFriendIds : (body.taggedFriends || [])),
      taggedCommunities: body.taggedCommunities || [],
      createdAt: now,
      likes: 0,
      saves: 0,
      likedBy: [],
      savedBy: [],
      comments: [],
      responseToPostId: body.responseToPostId || null,
    };

    await doc.put({ TableName: POSTS, Item: item }).promise();

    // Fan-out inbox messages
    const friendMessages = (item.taggedFriends || []).map((toUserId) => ({
      PutRequest: {
        Item: {
          userId: toUserId,
          messageId: uuid(),
          type: 'tag',
          fromUserId: item.userId,
          fromUsername: item.username,
          postId,
          createdAt: now,
          read: false,
        },
      },
    }));

    if (friendMessages.length) {
      await doc.batchWrite({ RequestItems: { [INBOX]: friendMessages } }).promise();
    }

    // If this is a response, notify the original uploader
    if (item.responseToPostId) {
      try {
        const original = await doc.get({ TableName: POSTS, Key: { postId: item.responseToPostId } }).promise();
        const originalItem = original.Item;
        if (originalItem && originalItem.userId && originalItem.userId !== item.userId) {
          await doc.put({
            TableName: INBOX,
            Item: {
              userId: originalItem.userId,
              messageId: uuid(),
              type: 'response',
              fromUserId: item.userId,
              fromUsername: item.username,
              postId,
              originalPostId: item.responseToPostId,
              createdAt: now,
              read: false,
            },
          }).promise();
        }
      } catch (e) {
        console.error('Failed to send response inbox message:', e);
      }
    }

    // Update uploader uploads list (simple append)
    await doc.update({
      TableName: USERS,
      Key: { userId: item.userId },
      UpdateExpression: 'SET uploads = list_append(if_not_exists(uploads, :empty), :pid)',
      ExpressionAttributeValues: { ':pid': [postId], ':empty': [] },
    }).promise();

    return { statusCode: 201, body: JSON.stringify(item) };
  } catch (e) {
    console.error(e);
    return { statusCode: 500, body: 'Internal Server Error' };
  }
};

export const getCommunityFeed = async (event) => {
  try {
    const { communityId } = event.pathParameters || {};
    console.log('Fetching community feed for:', communityId);
    // For demo: scan and filter (replace with GSI on taggedCommunities in prod)
    const data = await doc.scan({ TableName: POSTS }).promise();
    console.log('Total posts found:', data.Items?.length);
    console.log('All posts:', JSON.stringify(data.Items, null, 2));
    
    // Case-insensitive matching
    const items = (data.Items || []).filter((p) => {
      const communities = (p.taggedCommunities || []).map(c => c.toLowerCase());
      const match = communities.includes(communityId.toLowerCase());
      console.log(`Post ${p.postId} communities:`, p.taggedCommunities, 'match:', match);
      return match;
    });
    
    console.log('Filtered posts:', items.length);
    // Sort newest first
    items.sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1));
    
    // Generate presigned URLs for each video
    const itemsWithUrls = await Promise.all(items.map(async (item) => {
      // Extract S3 key from full URL or use as-is if it's already a key
      let key = item.videoUrl;
      if (key.startsWith('https://')) {
        // Extract key from URL like https://tagapp-videos.s3.us-west-2.amazonaws.com/videos/abc.mp4
        const match = key.match(/\.com\/(.+)$/);
        if (match) key = match[1];
      }
      
      const presignedUrl = await s3.getSignedUrlPromise('getObject', {
        Bucket: BUCKET,
        Key: key,
        Expires: 3600, // 1 hour
      });
      
      return { ...item, videoUrl: presignedUrl };
    }));
    
    return { statusCode: 200, body: JSON.stringify(itemsWithUrls) };
  } catch (e) {
    console.error(e);
    return { statusCode: 500, body: 'Internal Server Error' };
  }
};

export const getUserPosts = async (event) => {
  try {
    const { userId } = event.pathParameters || {};
    console.log('Fetching posts for user:', userId);
    
    // Scan and filter by userId (in production, use a GSI on userId)
    const data = await doc.scan({ TableName: POSTS }).promise();
    const items = (data.Items || []).filter((p) => p.userId === userId);
    console.log('Found posts for user:', items.length);
    
    // Sort newest first
    items.sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1));
    
    // Generate presigned URLs for each video
    const itemsWithUrls = await Promise.all(items.map(async (item) => {
      let key = item.videoUrl;
      if (key.startsWith('https://')) {
        const match = key.match(/\.com\/(.+)$/);
        if (match) key = match[1];
      }
      
      const presignedUrl = await s3.getSignedUrlPromise('getObject', {
        Bucket: BUCKET,
        Key: key,
        Expires: 3600,
      });
      
      return { ...item, videoUrl: presignedUrl };
    }));
    
    return { statusCode: 200, body: JSON.stringify(itemsWithUrls) };
  } catch (e) {
    console.error(e);
    return { statusCode: 500, body: 'Internal Server Error' };
  }
};

export const getAll = async () => {
  try {
    const data = await doc.scan({ TableName: POSTS }).promise();
    const items = data.Items || [];
    // Sort newest first
    items.sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1));

    const itemsWithUrls = await Promise.all(items.map(async (item) => {
      let key = item.videoUrl;
      if (key.startsWith('https://')) {
        const match = key.match(/\.com\/(.+)$/);
        if (match) key = match[1];
      }
      const presignedUrl = await s3.getSignedUrlPromise('getObject', {
        Bucket: BUCKET,
        Key: key,
        Expires: 3600,
      });
      return { ...item, videoUrl: presignedUrl };
    }));

    return { statusCode: 200, body: JSON.stringify(itemsWithUrls) };
  } catch (e) {
    console.error(e);
    return { statusCode: 500, body: 'Internal Server Error' };
  }
};
