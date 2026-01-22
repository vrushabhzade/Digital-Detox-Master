 # Digital Detox Master
 
 A modern, cross‑platform focus and wellbeing app built with Flutter. Stay in flow, train your brain, build better habits, and track progress — all powered by Supabase and optional AI voice coaching.
 
 ## Highlights
 - Focus timer with sessions (Pomodoro/Deep Work) and distraction tracking
 - Habit builder and streaks
 - Brain training mini‑exercises and Math trainer
 - Learn hub with curated content
 - Profile & settings synced via Supabase
 - Auth (email/password, magic link) using Supabase Auth
 - Clean go_router navigation and modular widgets
 - Optional OpenAI integration for coaching and tips
 
 ## Tech Stack
 - Flutter (Android, iOS, Web)
 - go_router for navigation
 - Supabase (Auth + Postgres + Realtime)
 - Optional OpenAI client (config via environment variables)
 
 ## App Structure (key files)
 ```
 lib/
   main.dart
   nav.dart                     // go_router routes & tabs
   theme.dart                   // design system & theme
   pages/
     dashboard_page.dart
     focus_timer_page.dart
     habits_page.dart
     learn_page.dart
     brain_training_page.dart
     math_trainer_page.dart
     profile_page.dart
     sign_in_page.dart
   widgets/
     scaffold_with_nav_bar.dart
     focus_timer.dart
   auth/
     auth_manager.dart
     supabase_auth_manager.dart
     demo_credentials.dart
   supabase/
     supabase_config.dart       // Supabase URL & anon key
     models.dart                // Profile/UserSettings/FocusSession
     profile_service.dart
     focus_service.dart
     demo_service.dart
   openai/
     openai_config.dart         // Reads OPENAI_* from env
   voice/
     elevenlabs_service.dart
 ```
 
 ## Routing
 go_router paths used by the app:
 - `/` Dashboard
 - `/focus` Focus Timer
 - `/habits` Habits
 - `/learn` Learn
 - `/learn/brain` Brain Training
 - `/learn/math` Math Trainer
 - `/profile` Profile
 - `/signin` Sign In (redirects when unauthenticated)
 
 ## Setup
 
 ### 1) Prerequisites
 - Flutter (latest stable)
 - A Supabase project (URL and anon key)
 - Optional: OpenAI proxy endpoint + API key
 
 ### 2) Configure Supabase
 By default, the project reads the Supabase URL and anon key from `lib/supabase/supabase_config.dart`.
 - For production, avoid committing secrets to public repos. Prefer environment‑based config.
 - If you use the existing approach, edit:
   - `SupabaseConfig.supabaseUrl`
   - `SupabaseConfig.anonKey`
 
 Then initialize tables to match the included client models in `lib/supabase/models.dart` (examples):
 - profiles (id, username, full_name, avatar_url, timezone, language, preferred_voice_id, voice_personality, notification_enabled, dark_mode, subscription_tier)
 - user_settings (id, user_id, daily_scroll_limit_minutes, daily_productive_goal_hours, default_focus_duration, break_duration, long_break_duration, morning_reminder_time, evening_reminder_time, focus_mode_auto_enable, voice_speed, voice_volume)
 - focus_sessions (id, user_id, session_type, planned_duration_minutes, actual_duration_minutes, task_description, task_category, start_time, end_time, completed, distraction_count, quality_rating)
 
 Adjust names/columns if your schema differs.
 
 ### 3) Configure OpenAI (optional)
 The OpenAI client reads configuration at runtime from environment variables via `String.fromEnvironment`:
 - `OPENAI_PROXY_API_KEY`
 - `OPENAI_PROXY_ENDPOINT` (do NOT append `v1/chat/completions`; use the base endpoint)
 
 Example run command (local):
 ```
 flutter run \
   --dart-define=OPENAI_PROXY_API_KEY=sk-xxx \
   --dart-define=OPENAI_PROXY_ENDPOINT=https://your-proxy.example.com
 ```
 
 ### 4) Install dependencies and run
 ```
 flutter pub get
 flutter run
 ```
 
 ## Using Dreamflow
 This project is built and previewed in Dreamflow (browser‑based Flutter IDE).
 - Preview: click “Preview” to run the app live
 - Inspect Mode: visually select widgets and tweak properties
 - Hot Reload/Restart: buttons in the preview toolbar
 - Publish: top‑right “Publish” to deploy (Web, iOS, Android)
 
 ### Connect and Push to GitHub from Dreamflow
 1. Open the Source Control panel in the left sidebar.
 2. If not connected yet, click “Connect Repository”. Provide:
    - Repository URL (must be blank or contain only README/LICENSE)
    - Personal Access Token (GitHub: grant Content Read/Write)
 3. Once connected, you’ll see the Changes list.
 4. Stage `README.md`, write a message like `docs: add GitHub README`, then click Commit.
 5. Click Push to send commits to GitHub.
 
 Docs: https://docs.dreamflow.com/integrations/git#connect-project-to-git
 
 ### Push via local Git (alternative)
 If you downloaded the code and prefer CLI:
 ```
 # inside the project root
 git init
 git add .
 git commit -m "chore: add README"
 git branch -M main
 # replace with your repo
 git remote add origin https://github.com/<you>/digital-detox-master.git
 git push -u origin main
 ```
 
 ## Security Notes
 - Never expose private keys in a public repository. Consider moving Supabase credentials to runtime configuration for production.
 - The OpenAI client already expects runtime env variables via `--dart-define`.
 
 ## License
 Add a LICENSE file (e.g., MIT) or specify your chosen license here.
 
 ---
 Built with Flutter, Supabase, and love for deep work.