# App Review Notes (Template)

Use this in App Store Connect -> App Review Information.

## Demo Access

- Test account email: <provide>
- Test account password: <provide>
- If MFA/OTP is enabled, include exact reviewer steps and backup code path.

## Core Feature Paths

1. Launch app.
2. Sign in with test credentials.
3. Home tab: view pet companion status and settings.
4. Journal tab:
   - Create text journal.
   - Start voice journal (microphone permission appears only when needed).
5. Care tab:
   - Complete a breathing or meditation activity.
6. Community tab:
   - Create post.
   - Comment on post.
   - Report post from the overflow menu.

## Account Lifecycle

- In-app account deletion path:
   Home -> Settings -> Account -> Delete Account.
- App schedules deletion immediately and permanently removes the account after 14 days.
- App requests confirmation before starting the deletion grace period.

## Permissions

- Microphone: requested only when starting voice recording.
- Speech recognition: requested when starting voice-to-text journaling.
- Photos: requested only when selecting profile/post images.

## Service Clarification

- Active services:
  - Supabase Edge Function: pet-llm
  - Rewind pet talking websocket service
- Deprecated service not used in current production flow:
  - rewind-pet-microservice
