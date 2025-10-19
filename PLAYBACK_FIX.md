# Video Playback 403 Error - Fixed

## Problem
Video player was getting HTTP 403 (Forbidden) errors when trying to play videos from S3 because:
- S3 objects are private by default
- The bucket has "Block Public Access" enabled
- Videos were stored as plain S3 URLs without authorization

## Solution
Implemented presigned GET URLs for video playback:

### Backend Changes (backend/src/posts.js)
- Added S3 client initialization
- Modified `getCommunityFeed` to generate presigned GET URLs (valid for 1 hour) for each video before returning
- Extracts S3 key from stored URL and creates temporary authorized access URL

### Flutter Changes (app_flutter/lib/screens/camera_screen.dart)
- Now stores S3 key (e.g., `videos/abc123.mp4`) instead of full URL in the database
- Backend generates presigned URLs on-demand when fetching posts
- Local optimistic update uses local file path for immediate playback

### How It Works
1. **Upload Flow:**
   - Get presigned PUT URL from `/presign`
   - Upload video to S3
   - Store S3 **key** (not URL) in DynamoDB via `/posts`

2. **Playback Flow:**
   - Client requests community feed
   - Backend fetches posts from DynamoDB
   - Backend generates presigned GET URLs for each video (1 hour expiry)
   - Client receives posts with authorized URLs
   - Video player can stream the content

### Key Benefits
- ✅ S3 bucket remains private and secure
- ✅ Videos accessible only through backend API
- ✅ Temporary URLs expire after 1 hour
- ✅ No bucket policy changes needed
- ✅ Works with Block Public Access enabled

## Testing
After hot reload, you should be able to:
1. Upload a video via Record tab
2. Navigate to Communities and select the community
3. Videos should play without 403 errors
4. Pull to refresh works

## Note
Presigned URLs expire after 1 hour. If a user keeps the app open longer, they may need to refresh to get new URLs. Consider implementing:
- Client-side URL refresh logic
- Longer expiry times (up to 7 days)
- Caching strategy in the app
