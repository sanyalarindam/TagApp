# TagApp Backend (Serverless on AWS)

This backend provides:
- Pre-signed S3 uploads for videos
- Post creation (metadata in DynamoDB + fan-out to inbox)
- Community feed
- User profile get/update
- Inbox fetch

## Prerequisites
- Node.js 18+
- AWS CLI configured with your IAM user (Access Key + Secret)
- Serverless Framework: `npm i -g serverless`

## Configure
- Ensure your AWS region and resource names match `serverless.yml`.
- S3 bucket: `tagapp-videos` (already created)
- DynamoDB tables: `Users`, `Posts`, `Communities`, `Inbox`

## Deploy

```powershell
cd backend
npm install
npm run deploy
```

Serverless will print an `httpApi` base URL like `https://xxxx.execute-api.us-west-2.amazonaws.com`.

## Test Endpoints (PowerShell)

- Presign upload URL
```powershell
$BASE="https://xxxx.execute-api.us-west-2.amazonaws.com"
Invoke-RestMethod -Method Post -Uri "$BASE/presign" -Body (@{ contentType = 'video/mp4' } | ConvertTo-Json) -ContentType 'application/json'
```
Response:
```json
{ "uploadUrl": "https://s3...", "objectKey": "videos/uuid.mp4" }
```

- Create post (after uploading to S3 using the presigned URL)
```powershell
$body = @{ userId='u1'; username='User'; videoUrl='https://tagapp-videos.s3.us-west-2.amazonaws.com/videos/uuid.mp4'; description='desc'; hashtags=@('parkour'); taggedFriends=@('u2'); taggedCommunities=@('Parkour') } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri "$BASE/posts" -Body $body -ContentType 'application/json'
```

- Community feed
```powershell
Invoke-RestMethod -Method Get -Uri "$BASE/communities/Parkour/posts"
```

- Get user
```powershell
Invoke-RestMethod -Method Get -Uri "$BASE/users/u1"
```

- Update user
```powershell
$body = @{ username='NewName'; bio='Hello' } | ConvertTo-Json
Invoke-RestMethod -Method Put -Uri "$BASE/users/u1" -Body $body -ContentType 'application/json'
```

- Inbox
```powershell
Invoke-RestMethod -Method Get -Uri "$BASE/users/u2/inbox"
```

## Notes
- For production, add GSIs to `Posts` for efficient community/user queries.
- Lock down IAM permissions and add auth (Cognito/JWT) before going live.
- Replace `scan` in `getCommunityFeed` with a proper `Query` using a GSI.
