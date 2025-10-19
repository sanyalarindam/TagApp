import AWS from 'aws-sdk';

// Configuration - keep in sync with serverless.yml
const REGION = 'us-west-2';
const BUCKET = 'tagapp-videos';
const POSTS = 'Posts';
const USERS = 'Users';

AWS.config.update({ region: REGION });
const doc = new AWS.DynamoDB.DocumentClient();
const s3 = new AWS.S3();

function extractKey(videoUrl) {
  if (!videoUrl) return null;
  if (videoUrl.startsWith('https://')) {
    const m = videoUrl.match(/\.com\/(.+)$/);
    return m ? m[1] : null;
  }
  return videoUrl; // assume already an S3 key
}

async function scanAll(params) {
  const items = [];
  let lastKey = undefined;
  do {
    const res = await doc.scan({ ...params, ExclusiveStartKey: lastKey }).promise();
    items.push(...(res.Items || []));
    lastKey = res.LastEvaluatedKey;
  } while (lastKey);
  return items;
}

async function main() {
  console.log('Starting cleanup: deleting all posts and S3 video objects, and clearing user uploads...');
  // 1) Fetch all posts
  const posts = await scanAll({ TableName: POSTS });
  console.log(`Found ${posts.length} posts`);

  // 2) Delete S3 objects for each post
  let deletedObjects = 0;
  for (const p of posts) {
    const key = extractKey(p.videoUrl);
    if (!key) continue;
    try {
      await s3.deleteObject({ Bucket: BUCKET, Key: key }).promise();
      deletedObjects++;
    } catch (e) {
      console.warn('Failed to delete S3 object for', key, e.code || e.message);
    }
  }
  console.log(`Deleted ${deletedObjects} S3 objects`);

  // 3) Delete posts from DynamoDB (batch in chunks of 25)
  const chunk = (arr, size) => arr.reduce((acc, _, i) => (i % size ? acc : [...acc, arr.slice(i, i + size)]), []);
  const postChunks = chunk(posts, 25);
  let deletedPosts = 0;
  for (const group of postChunks) {
    const req = {
      RequestItems: {
        [POSTS]: group.map((p) => ({ DeleteRequest: { Key: { postId: p.postId } } })),
      },
    };
    const res = await doc.batchWrite(req).promise();
    const unprocessed = res.UnprocessedItems && res.UnprocessedItems[POSTS] ? res.UnprocessedItems[POSTS].length : 0;
    deletedPosts += group.length - unprocessed;
    if (unprocessed) {
      console.warn(`Warning: ${unprocessed} unprocessed post deletes`);
    }
  }
  console.log(`Deleted ${deletedPosts} post items`);

  // 4) Clear uploads for all users
  const users = await scanAll({ TableName: USERS });
  console.log(`Found ${users.length} users; clearing uploads arrays`);
  for (const u of users) {
    try {
      await doc
        .update({
          TableName: USERS,
          Key: { userId: u.userId },
          UpdateExpression: 'SET uploads = :empty',
          ExpressionAttributeValues: { ':empty': [] },
        })
        .promise();
    } catch (e) {
      console.warn('Failed to clear uploads for user', u.userId, e.code || e.message);
    }
  }

  console.log('Cleanup complete.');
}

main().catch((e) => {
  console.error('Cleanup failed', e);
  process.exit(1);
});
