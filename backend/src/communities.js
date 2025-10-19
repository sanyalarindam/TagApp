import AWS from 'aws-sdk';

const doc = new AWS.DynamoDB.DocumentClient();
const COMMUNITIES = process.env.COMMUNITIES_TABLE;
const POSTS = process.env.POSTS_TABLE;

export const list = async () => {
  try {
    // First, try to read from Communities table
    const comms = await doc.scan({ TableName: COMMUNITIES }).promise();
    let names = [];
    if ((comms.Items || []).length > 0) {
      names = (comms.Items || [])
        .map((c) => (c.name || c.id || c.communityId || '').toString())
        .filter((s) => s && s.trim().length > 0);
    } else {
      // Fallback: derive from Posts
      const posts = await doc.scan({ TableName: POSTS }).promise();
      const set = new Set();
      for (const p of posts.Items || []) {
        for (const c of p.taggedCommunities || []) {
          const s = (c || '').toString().trim();
          if (s) set.add(s);
        }
      }
      names = Array.from(set);
    }
    names.sort((a, b) => a.localeCompare(b));
    return { statusCode: 200, body: JSON.stringify(names) };
  } catch (e) {
    console.error('communities.list failed', e);
    return { statusCode: 500, body: 'Internal Server Error' };
  }
};
