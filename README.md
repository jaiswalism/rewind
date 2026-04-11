# Rewind iOS App

Rewind is an iOS mental wellness app that combines personal reflection, guided care activities, a community feed, and a companion pet experience.

## What The App Does

- Journals: write text journals and record voice journals
- Care Corner: breathing, meditation, and challenge-based routines
- Community: post, browse, like, and comment in a shared feed
- HomePets: track and interact with a virtual companion tied to your activity
- Pet Talking: real-time voice interaction with the companion

## Tech Stack

- Client: UIKit + SwiftUI
- Architecture: MVVM
- Backend: Supabase (Auth, Postgres, Storage, Edge Functions)
- iOS libraries/frameworks: supabase-swift, AVFoundation, Combine

## Project Structure

- Rewind/: main iOS target source code
- Rewind/Controllers: UIKit and hosting controllers
- Rewind/Views: SwiftUI views and feature UI
- Rewind/ViewModels: feature logic and state
- Rewind/Models: database and domain models
- Rewind/Services: service integrations (voice, onboarding, etc.)

## Backend Services

- Primary backend: Supabase
- Active voice backend: rewind-pet-talking-service (proxy for live pet voice)
- Legacy service: rewind-pet-microservice (kept in repo history, no longer relevant to current app flow)

## Local Setup

1. Open Rewind.xcodeproj in Xcode.
2. Ensure Supabase credentials are set in Rewind/Core/SupabaseSecrets.swift for your environment.
3. Resolve Swift packages.
4. Run on simulator or device.
