# Rewind iOS Architecture

## 1. Product Category and Purpose

Rewind is a personal reflection and lifestyle support iOS application built around five core experiences:

1. Structured journaling (text and voice)
2. Guided daily routines (breathing, meditation, challenge loops)
3. Community-based interaction (posts, comments, likes)
4. Companion pet progression and engagement
5. Real-time pet talking sessions

The architecture is designed to support fast feature iteration while preserving predictable user flows for onboarding, authentication, and daily usage.

## 2. Core Architectural Principles

### 2.1 Design Pattern

- Primary pattern: MVVM
- ViewModels own feature logic, orchestration, and async state
- Views and ViewControllers primarily render state and dispatch user intent

### 2.2 UI Composition Model

- Hybrid UIKit + SwiftUI
- UIKit is used for route-heavy flows, tab composition, and legacy screens
- SwiftUI is used for modern feature surfaces and reusable visual components

### 2.3 Backend Strategy

- Supabase-first model for data/auth/storage operations
- Edge Function integration for specific pet inference workflows
- Service proxy integration for live pet talking

### 2.4 Reliability Guidelines

- Deterministic launch and route selection
- Safe permission handling for audio/speech features
- Recoverable error paths over crash-only behavior
- Reviewer-visible flows should avoid dead ends and placeholder actions

## 3. Layered Architecture

## 3.1 Presentation Layer

Responsibilities:

- Screen rendering
- Interaction capture
- Navigation triggers
- Short-lived view state

Key elements:

- UIKit controllers under Controllers/
- SwiftUI feature views under Views/
- Hosting-controller bridges where SwiftUI screens are embedded into UIKit navigation stacks

### 3.2 Feature Application Layer

Responsibilities:

- Business workflow coordination
- Validation and action sequencing
- Async task lifecycle and loading/error state
- Bridging backend payloads into UI-ready structures

Key elements:

- Feature ViewModels under ViewModels/
- Shared flow managers/services under Services/

### 3.3 Domain and Model Layer

Responsibilities:

- Codable model definitions
- Backend schema mapping
- Feature-level domain structures (pet state, community entities, journal entities)

Key elements:

- Models under Models/

### 3.4 Platform and Infrastructure Layer

Responsibilities:

- Supabase client bootstrapping
- Shared constants
- Cross-cutting helpers
- App-wide configuration

Key elements:

- Core/ for configuration, constants, utilities

## 4. Feature Topology

### 4.1 Authentication and Onboarding

- Supports credential and OAuth-based sign-in flows
- Onboarding completion influences initial route selection
- Session checks determine whether to land on onboarding or main tabs

### 4.2 Journals

- Text journal creation and history retrieval
- Voice journal capture and transcription support
- Media handling backed by storage integrations

### 4.3 Care Corner

- Structured activity sessions for breathing and meditation
- Challenge progression and completion loops
- Feature-specific state transitions for active sessions

### 4.4 Community

- Feed retrieval and filter behavior
- Post creation/edit/delete flows
- Engagement actions: like/comment
- UGC safety actions should be implemented end-to-end (not visual placeholder only)

### 4.5 HomePets

- Companion state display and progression
- Interaction events mapped to pet-state updates
- Shared state influences messaging and engagement loops

### 4.6 Pet Talking

- Live audio interaction pipeline
- Permission-gated microphone and speech paths
- Proxy-backed session model for real-time pet responses

## 5. Runtime Execution Model

## 5.1 Launch and Route Resolution

1. App/scene initialization
2. Splash presentation and minimum display timing
3. Session and onboarding-completion checks
4. Route to onboarding/auth/main tabs

Expected properties:

- No route ambiguity
- Safe fallback behavior
- Stable first-run and returning-user behavior

### 5.2 Screen Interaction Loop

1. User triggers an action in UI
2. ViewModel validates and starts async work
3. Service/backend call executes
4. ViewModel publishes updated state
5. UI re-renders based on new state

### 5.3 Error Handling Path

- Prefer user-facing recoverable messages for network and validation errors
- Avoid termination-oriented patterns in runtime-critical flows
- Keep state consistent after partial failures

## 6. Data and Integration Architecture

### 6.1 Supabase Responsibilities

- Authentication and session state
- Postgres-backed feature data
- Storage for user media assets
- Edge Function for pet inference pipeline integration

### 6.2 Service Topology

- Core backend: Supabase
- Live pet voice: pet talking service proxy for real-time interactions
- Pet inference: Edge Function path consumed by pet-related logic

### 6.3 Integration Boundaries

- ViewModels should depend on service APIs, not raw UI state
- Controllers/views should not contain backend orchestration logic
- Shared constants/config should remain centralized in Core/

## 7. Navigation and Module Boundaries

Navigation design goals:

- Predictable tab-based daily loop
- Clear separation between onboarding/auth and main product surfaces
- Smooth bridges between UIKit and SwiftUI screens

Module boundary goals:

- Feature encapsulation by folder and ViewModel ownership
- Low coupling between unrelated feature modules
- Reusable shared UI without leaking feature logic

## 8. Permissions and Capability Model

High-sensitivity permissions:

- Microphone
- Speech recognition

Architecture expectations:

- Request only when feature use requires it
- Keep rationale and denied-state behavior explicit
- Ensure non-voice app areas remain usable when voice permissions are denied

## 9. App Review Readiness in Architecture Terms

Architecture-level readiness means:

- Critical flows are complete and discoverable
- Account lifecycle actions are accessible in-app
- Community safety actions are operational
- Permissions and capabilities match actual runtime behavior
- Reviewer can traverse core value paths without special setup friction

## 10. Repository Mapping

- Rewind/: app source root
- Rewind/Controllers: UIKit controllers
- Rewind/Views: SwiftUI views and shared UI
- Rewind/ViewModels: feature logic and async state orchestration
- Rewind/Models: domain and backend-mapped models
- Rewind/Services: feature integrations and orchestration helpers
- Rewind/Core: configuration, constants, extensions, utilities

## 11. Maintenance Guidance

When adding or modifying features:

1. Keep UI rendering and business logic separate.
2. Extend existing feature ViewModels before introducing cross-feature coupling.
3. Add explicit error and empty-state handling for reviewer-visible paths.
4. Confirm permission and capability implications early.
5. Update this architecture document when introducing new service boundaries or route behaviors.
