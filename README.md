# rewind

iOS Xcode workspace for the Rewind app — personal journaling, guided care, community, and a virtual companion that evolves with your wellness journey.

> Personal project. Not intended for external contributors.

## Features

- **Journal** — Text and voice entries with emotion tags and streaks
- **Care Corner** — Breathing exercises, meditation, and daily challenges
- **Community** — Anonymous social feed for sharing and support
- **HomePets** — Virtual companion with dynamic states tied to your activity
- **Pet Talking** — Real-time voice sessions with the companion via Gemini Live

## Stack

- SwiftUI + UIKit, MVVM, Combine
- Supabase (Auth, Postgres + RLS, Storage)
- `rewind-voice-relay` — WebSocket proxy for Gemini Live voice sessions

## Structure

```
Rewind/Controllers/   → UIKit and hosting controllers
Rewind/Views/         → SwiftUI views
Rewind/ViewModels/    → Feature logic and state
Rewind/Models/        → Database and domain models
Rewind/Services/      → Voice, onboarding, and other integrations
```

## Key files

- `RULES.md` — Enforced coding standards (MVVM, no external dependencies, file size limits)
- `ARCHITECTURE.md` — How ViewModels talk to Supabase and how UI is composed

## License & Copyright

**Proprietary and Confidential.**
All rights reserved. This project, including all source code, assets, and concepts, is the exclusive property of Rewind. It is not open-source. You may not copy, distribute, reproduce, or use any part of this repository without explicit written permission.

---

© 2026 Rewind · [rewind@shyamjaiswal.in](mailto:rewind@shyamjaiswal.in)
