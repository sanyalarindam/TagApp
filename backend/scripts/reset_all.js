import AWS from 'aws-sdk';

// Configuration - keep in sync with serverless.yml
const REGION = 'us-west-2';
const BUCKET = 'tagapp-videos';
const POSTS = 'Posts';
const USERS = 'Users';
const INBOX = 'Inbox';
const COMMUNITIES = 'Communities';

AWS.config.update({ region: REGION });
const doc = new AWS.DynamoDB.DocumentClient();
const s3 = new AWS.S3();

async function deleteAllS3Objects(bucket) {
  console.log(`Deleting ALL objects from s3://${bucket} ...`);
  let deleted = 0;
  let token = undefined;
  do {
    const list = await s3
      .listObjectsV2({ Bucket: bucket, ContinuationToken: token })
      .promise();
    const contents = list.Contents || [];
    if (contents.length > 0) {
      const delReq = {
        Bucket: bucket,
        Delete: { Objects: contents.map((o) => ({ Key: o.Key })) },
      };
      const res = await s3.deleteObjects(delReq).promise();
      deleted += (res.Deleted || []).length;
      const errors = res.Errors || [];
      if (errors.length) {
        console.warn(`S3 delete errors:`, errors.length);
      }
    }
    token = list.IsTruncated ? list.NextContinuationToken : undefined;
  } while (token);
  console.log(`Deleted ${deleted} S3 objects.`);
}

async function scanAll(params) {
  const items = [];
  let lastKey = undefined;
  do {
    const res = await doc
      .scan({ ...params, ExclusiveStartKey: lastKey })
      .promise();
    items.push(...(res.Items || []));
    lastKey = res.LastEvaluatedKey;
  } while (lastKey);
  return items;
}

function chunk(arr, size) {
  const out = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

async function deleteAllFromTable(tableName, keyAttr) {
  const items = await scanAll({ TableName: tableName });
  console.log(`Deleting ${items.length} items from ${tableName} ...`);
  let deleted = 0;
  for (const group of chunk(items, 25)) {
    const req = {
      RequestItems: {
        [tableName]: group.map((it) => ({
          DeleteRequest: { Key: { [keyAttr]: it[keyAttr] } },
        })),
      },
    };
    const res = await doc.batchWrite(req).promise();
    const unprocessed = res.UnprocessedItems?.[tableName]?.length || 0;
    deleted += group.length - unprocessed;
    if (unprocessed) {
      console.warn(`${unprocessed} unprocessed deletes for ${tableName}`);
    }
  }
  console.log(`Deleted ${deleted} items from ${tableName}.`);
}

async function main() {
  console.log('=== TagApp: Full backend reset (S3 + DynamoDB tables) ===');
  // 1) S3: delete ALL objects
  await deleteAllS3Objects(BUCKET);

  // 2) DynamoDB: delete all items from Posts, Inbox, Users, Communities
  await deleteAllFromTable(POSTS, 'postId');

  // Inbox may use a composite key, assume we have messageId as the key
  // If table uses a composite key (userId + messageId), this deletion
  // by messageId only will fail. In that case, switch to DeleteRequest with both keys.
  // For now, we'll fetch userId + messageId and delete with both.
  const inboxItems = await scanAll({ TableName: INBOX });
  console.log(`Deleting ${inboxItems.length} items from ${INBOX} ...`);
  for (const group of chunk(inboxItems, 25)) {
    const req = {
      RequestItems: {
        [INBOX]: group.map((it) => ({
          DeleteRequest: { Key: { userId: it.userId, messageId: it.messageId } },
        })),
      },
    };
    const res = await doc.batchWrite(req).promise();
    const unprocessed = res.UnprocessedItems?.[INBOX]?.length || 0;
    if (unprocessed) console.warn(`${unprocessed} unprocessed deletes for ${INBOX}`);
  }
  console.log(`Deleted all items from ${INBOX}.`);

  // Users: delete all users (usernames/password hashes etc.)
  const users = await scanAll({ TableName: USERS });
  console.log(`Deleting ${users.length} users from ${USERS} ...`);
  for (const group of chunk(users, 25)) {
    const req = {
      RequestItems: {
        [USERS]: group.map((u) => ({ DeleteRequest: { Key: { userId: u.userId } } })),
      },
    };
    const res = await doc.batchWrite(req).promise();
    const unprocessed = res.UnprocessedItems?.[USERS]?.length || 0;
    if (unprocessed) console.warn(`${unprocessed} unprocessed deletes for ${USERS}`);
  }
  console.log(`Deleted all users from ${USERS}.`);

  // Communities: optional, wipe for a true clean slate
  const comms = await scanAll({ TableName: COMMUNITIES });
  console.log(`Deleting ${comms.length} items from ${COMMUNITIES} ...`);
  // Try to detect primary key attribute name
  const commKey = comms.length > 0
    ? (('id' in comms[0]) ? 'id' : (('communityId' in comms[0]) ? 'communityId' : null))
    : 'id';
  if (!commKey) {
    console.warn(`Could not determine primary key for ${COMMUNITIES}; skipping deletion.`);
  } else {
    for (const group of chunk(comms, 25)) {
      const req = {
        RequestItems: {
          [COMMUNITIES]: group.map((c) => ({ DeleteRequest: { Key: { [commKey]: c[commKey] } } })),
        },
      };
      const res = await doc.batchWrite(req).promise();
      const unprocessed = res.UnprocessedItems?.[COMMUNITIES]?.length || 0;
      if (unprocessed) console.warn(`${unprocessed} unprocessed deletes for ${COMMUNITIES}`);
    }
    console.log(`Deleted all items from ${COMMUNITIES}.`);
  }

  console.log('=== Reset complete. ===');
}

main().catch((e) => {
  console.error('Reset failed', e);
  process.exit(1);
});
