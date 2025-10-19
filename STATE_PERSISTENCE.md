# State Persistence Implementation

## Overview
Implemented full state hydration so videos persist across app restarts. Now all tabs (Home, Communities, Profile, Inbox) load data from the backend.

## Changes Made

### Backend
**New Endpoint: GET /users/{userId}/posts**
- File: `backend/src/posts.js` → Added `getUserPosts` function
- Fetches all posts for a specific user from DynamoDB
- Generates presigned URLs for video playback (1 hour expiry)
- Sorts posts by creation date (newest first)

**Configuration:**
- File: `backend/serverless.yml` → Added route mapping

### Flutter App

**1. Backend API Client** (`app_flutter/lib/services/backend_api.dart`)
- Added `getUserPosts(userId)` method
- Returns list of post data with presigned video URLs

**2. State Management** (`app_flutter/lib/providers/video_provider.dart`)
- Added `loadFromBackend(userId)` method
- Fetches posts from backend and populates local state
- Gracefully handles errors (app works even if backend fails)
- Clears existing state before loading to avoid duplicates

**3. Home Screen** (`app_flutter/lib/screens/home_screen.dart`)
- Calls `loadFromBackend()` in `initState`
- Shows loading spinner while fetching
- Automatically hydrates state on app start

## How It Works

### App Startup Flow:
1. App launches → `HomeScreen` initializes
2. `_loadUserPosts()` called in `initState`
3. Shows `CircularProgressIndicator` during fetch
4. `VideoProvider.loadFromBackend()` fetches from API
5. Posts mapped to `VideoItem` objects
6. State updated → UI refreshes automatically
7. Videos appear in Home/Explore and Profile tabs

### After Restart:
✅ **Home/Explore tab** → Shows all user's videos from backend  
✅ **Communities tab** → Loads community-specific videos from backend  
✅ **Profile tab** → Shows user's uploads from backend  
✅ **Inbox tab** → Loads messages from backend  

## Data Flow

```
Upload Video
    ↓
Upload to S3 (presigned PUT)
    ↓
Store metadata in DynamoDB
    ↓
Optimistic UI update (local state)

---

App Restart
    ↓
HomeScreen.initState()
    ↓
VideoProvider.loadFromBackend()
    ↓
BackendApi.getUserPosts()
    ↓
GET /users/{userId}/posts
    ↓
Posts with presigned URLs
    ↓
Map to VideoItem
    ↓
Update VideoProvider state
    ↓
UI renders videos
```

## Testing

**To verify persistence:**

1. **Upload videos** (if you haven't already):
   - Tap Record → Pick Video
   - Add description, hashtag, community
   - Upload

2. **Close and restart the app** (hot restart or full restart)

3. **Check all tabs:**
   - **Home/Explore** → Should show your uploaded videos ✅
   - **Communities** → Should show videos in each community ✅
   - **Profile** → Should show your uploads ✅
   - **Inbox** → Should show your messages ✅

## Current User

Hardcoded as `u1` (BackendApi.currentUserId). In production, this will come from authentication (Cognito).

## Presigned URL Expiry

- Video URLs expire after **1 hour**
- If a user keeps app open longer, they may need to pull-to-refresh or restart
- Consider:
  - Implementing client-side URL refresh
  - Longer expiry times (up to 7 days max)
  - Caching strategy with TTL

## Performance Notes

- Backend uses DynamoDB `scan` (slow for large datasets)
- **Recommend adding GSI** on `userId` for efficient queries in production
- Current approach works fine for MVP/demo

## Next Steps (Optional)

1. **Add pull-to-refresh** in HomeScreen to reload posts
2. **Cache presigned URLs** with TTL to reduce backend calls
3. **Add loading states** for individual videos in feed
4. **Implement authentication** to get real user IDs
5. **Add GSI on Posts table** for userId queries
