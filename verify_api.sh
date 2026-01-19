#!/bin/bash

BASE_URL="http://localhost:3000/api/v1"
EMAIL="verifier_$(date +%s)@test.com"
PASSWORD="password123"
NAME="Verifier"

echo "Waiting for backend to stabilize..."
sleep 5

echo "--- 1. Testing Auth & User ---"
# Register
echo "Registering $EMAIL..."
REGISTER_RES=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$EMAIL\", \"password\": \"$PASSWORD\", \"name\": \"$NAME\"}")
echo "Register Response: $REGISTER_RES"

sleep 2

# Login
echo "Logging in..."
LOGIN_RES=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$EMAIL\", \"password\": \"$PASSWORD\"}")

# Extract Token (Basic grep/sed parsing for simplicity, avoiding jq dependency if not present, though usually available)
TOKEN=$(echo $LOGIN_RES | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "❌ Login Failed. Response: $LOGIN_RES"
  exit 1
fi
echo "✅ Login Success. Token: ${TOKEN:0:10}..."

# Get Profile
echo "Fetching Profile..."
PROFILE_RES=$(curl -s -X GET "$BASE_URL/users/profile" -H "Authorization: Bearer $TOKEN")
if [[ $PROFILE_RES == *"id"* ]]; then echo "✅ Profile OK"; else echo "❌ Profile Failed: $PROFILE_RES"; fi

echo "--- 2. Testing Journals ---"
# Create Journal
echo "Creating Journal..."
JOURNAL_RES=$(curl -s -X POST "$BASE_URL/journals" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Test Entry", "content": "Verifying APIs", "entryType": "text", "moodTags": ["Happy"]}')
echo "Create Journal Response: $JOURNAL_RES"
if [[ $JOURNAL_RES == *"id"* ]] && [[ $JOURNAL_RES != *"error"* ]]; then echo "✅ Create Journal OK"; else echo "❌ Create Journal Failed"; fi

# List Journals
echo "Listing Journals..."
LIST_J_RES=$(curl -s -X GET "$BASE_URL/journals" -H "Authorization: Bearer $TOKEN")
echo "Journal List Response: $LIST_J_RES"
if [[ $LIST_J_RES == *"Test Entry"* ]]; then echo "✅ List Journals OK"; else echo "❌ List Journals Failed"; fi

echo "--- 3. Testing Care Corner ---"
# Record Breathing
echo "Recording Breathing Session..."
BREATH_RES=$(curl -s -X POST "$BASE_URL/care-corner/breathing" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"durationSeconds": 60}')
if [[ $BREATH_RES == *"pawsEarned"* ]] || [[ $BREATH_RES == *"success"* ]]; then echo "✅ Breathing OK"; else echo "❌ Breathing Failed: $BREATH_RES"; fi

echo "--- 4. Testing Community ---"
# Create Post
echo "Creating Community Post..."
POST_RES=$(curl -s -X POST "$BASE_URL/community/posts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content": "Hello World from Verifier!", "isAnonymous": false, "tags": ["TEST"]}')
if [[ $POST_RES == *"id"* ]]; then echo "✅ Create Post OK"; else echo "❌ Create Post Failed: $POST_RES"; fi

# List Posts
echo "Listing Community Posts..."
LIST_P_RES=$(curl -s -X GET "$BASE_URL/community/posts" -H "Authorization: Bearer $TOKEN")
if [[ $LIST_P_RES == *"Hello World"* ]]; then echo "✅ List Posts OK"; else echo "❌ List Posts Failed: $LIST_P_RES"; fi

echo "--- 5. Testing Notifications ---"
# Get Notifications
echo "Fetching Notifications..."
NOTIF_RES=$(curl -s -X GET "$BASE_URL/notifications" -H "Authorization: Bearer $TOKEN")
# Might be empty array, check for success structure or array
echo "Response: $NOTIF_RES"
if [[ $NOTIF_RES == *"data"* ]] || [[ $NOTIF_RES == *"[]"* ]]; then echo "✅ Notifications OK"; else echo "❌ Notifications Failed"; fi

echo "--- 6. Testing Pets ---"
# Get Pet
echo "Fetching Pet..."
PET_RES=$(curl -s -X GET "$BASE_URL/homepets/user-pet" -H "Authorization: Bearer $TOKEN")
echo "Pet Response: $PET_RES"
if [[ $PET_RES == *"id"* ]] || [[ $PET_RES == *"cat"* ]] || [[ $PET_RES == *"dog"* ]]; then echo "✅ Pet OK"; else echo "❌ Pet Failed"; fi

echo "--- Verification Complete ---"
