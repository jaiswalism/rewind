# ⏪ Rewind - iOS Client

This repository contains the native iOS client for **Rewind**, a comprehensive mental health, wellness, and self-care application. The app offers habit tracking, journaling, community engagement, and a gamified virtual companion to promote daily mental wellbeing.

---

## 🏗️ Architecture & Stack
This project adheres to a strict coding standard outlined in `RULES.md`. All contributions **must** follow these principles.

*   **Design Pattern:** Strict **MVVM** (Model-View-ViewModel).
*   **UI Framework:** Hybrid approach utilizing **SwiftUI** for new components and **UIKit** for core routing and legacy views.
*   **Reactivity:** Deep integration of **Combine** for reactive data bindings between ViewModels (`@Published`) and Views (`AnyCancellable`).
*   **Backend:** Serverless architecture directly interfacing with **Supabase**. There is no traditional middleware API for core CRUD operations.

---

## 🛠️ Project Setup

### 1. Prerequisites
*   **macOS** (latest recommended)
*   **Xcode 15+**
*   An active **Supabase** project instance (for database, auth, and storage).

### 2. Environment Configuration
The app will crash on launch if it cannot connect to the backend. You must configure the Supabase client locally:

1. Open the project in Xcode (`Rewind.xcodeproj`).
2. Navigate to `Rewind/Core/` and create a new Swift file named `SupabaseSecrets.swift`.
3. Add the following code with your Supabase credentials:
   ```swift
   import Foundation

   public enum SupabaseSecrets {
       public static let supabaseURL = URL(string: "YOUR_SUPABASE_URL")!
       public static let supabaseKey = "YOUR_SUPABASE_ANON_KEY"
   }
   ```
4. *Note: Ensure this file is added to your `.gitignore` to prevent leaking secrets.*

### 3. Running the App
1. Open `Rewind.xcodeproj`.
2. Wait for **Swift Package Manager (SPM)** to finish resolving dependencies (primarily `supabase-swift`).
3. Select your target simulator or physical device and run (`Cmd + R`).

---

## 🚦 Core Dependencies
This project operates under a "zero unnecessary external libraries" policy. We rely on native Apple frameworks wherever possible.

*   `supabase-swift` - The official Supabase client for Swift (Auth, Database, Storage).
*   *Native Frameworks:* `Combine`, `SwiftUI`, `UIKit`, `AVFoundation` (for voice journals/meditation).

---

## 🚨 Development Rules (CRITICAL)
If you are developing or using an AI assistant on this repository, you are strictly bound by the `RULES.md` file. Highlights include:
1. **Max file size:** `300 lines`. Break views and logic down aggressively.
2. **Max function size:** `40 lines`.
3. **No logic in views:** UI files are for rendering **only**.
4. **No force unwraps:** `!` is strictly prohibited unless provably safe.
5. **No AI abstractions:** If an AI generates complex, abstracted code, remove it or rewrite it. Clarity > Cleverness.

If your code doesn't meet the Definition of Done (Zero warnings, zero force unwrap risks, highly readable), it will be rejected.

---

## 🗺️ Feature Map
*   **`/Controllers`**: UIKit ViewControllers and SwiftUI hosting controllers grouped by feature.
*   **`/ViewModels`**: Pure logic and state management handling network requests.
*   **`/Models`**: Codable Swift structs that mirror our Supabase PostgreSQL tables.
*   **`/Core`**: Singletons and configurations (e.g., `SupabaseConfig.swift`).
*   **`/Services`**: Interfacing logic for external microservices (like the `rewind-pet-microservice`).
