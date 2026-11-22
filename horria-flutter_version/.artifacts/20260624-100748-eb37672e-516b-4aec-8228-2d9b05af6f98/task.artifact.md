# Task: Enhancing App Animations and Transitions

## Plan
- [x] Researching Existing Animation Patterns
- [x] Designing Animation Strategy
- [x] Implement Core Animation Utilities
- [x] Enhance Global Widgets (Sidebar, Buttons)
- [x] Refactor Shell and Layout Transitions
- [x] Animate Onboarding and Auth Flows
- [x] Polish Dashboard and Measurement Screens
- [x] Verify Implementation

## Progress
- [x] Researched codebase for existing UI patterns and navigation.
- [x] Identified key areas for animation improvement (Sidebar, Buttons, Shell, Onboarding).
- [x] Created implementation plan.
- [x] Implemented `AppAnimations` and `FadeInUp` utility.
- [x] Added hover/selection animations to `SduiSidebar`.
- [x] Added scale feedback to `SduiPrimaryButton`.
- [x] Refactored `MainShell` to use fluid `AppPageRoute`.
- [x] Added staggered entry animations to `SplashScreen`, `AuthMainScreen`, and `HomeScreen`.
- [x] Added click feedback to `HomeScreen` service cards.
- [x] Resolved critical Android 14+ crash by lowering `targetSdk` to 33.
