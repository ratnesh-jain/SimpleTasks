#  Simple Tasks
This project demonstrates the tasks lists with ToDo, In-Progress and Done Section.
### Technical Decisions
- Architecture: ComposableArchitecture
- Offline Database: SQLiteData (a database with Swift structured-queries language on top of GRDB, Alternative to SwiftData)
- UIFramework: SwiftUI
- Minimum Deployment Target: iOS27+ (Due to SwiftUI's List does not fully support re-ordering between sections, so using new iOS27+ `reorderable`, `reorderContainer` and `dragContainer` APIs.
- Remote Database: Firestore (NOTE: Please add your Firebase config plist)
- Time Spent: 12 hours
- AI Tools used: Google Antigravity + OpenCode (Big Pickle)
- Xcode version: Version 27.0 beta 6 (27A5252f)
- Swift Language: 6.4
- Logging: OSLog
- Conflict Resolution Strategy: Last Edit wins

### Available Features
- For DEBUG/Testing, added Seed button for initial Data
- Drag and drop task items between sections
- Re-order task items in section and between sections
- Search tasks
- Add, Edit and Delete task.
- Offline support for any re-order, add, edit and delete operation.

### Project Structure
- Uses local SPM modules. (SimpleTasksPackage)
- Module name ending with `Utilities` contains common extensions
- `CoreModels` contains all the Data types including database migration, seed data, protocol conformance etc.
- `FirebaseService` declares the light-weight dependency APIs to communicate with Firestore server.
- `FirebaseServiceLive` only links the real firestore dependencies to the main app target. Since linking to individual target breaks Xcode previews.
- `SyncService` contains logic for syncing between the local database and firestore.
- Module name ending with `Feature` contains the Business logic and UI for feature screen. (Unit testable)
- `NetworkStatusService` handles the network path monitoring service for offline/online sync trigger.

### Offline Strategy
- All user facing CRUD operations are done only in the local database.
- Temperary triggers are installed on Database CRUD operations, which triggers the remote server sync.
- Change listeners are installed on the remote server and saved in the database resolving the sync/merge conflict.
- UI/Screen Features will only read and write from local database.
- When network condition recovers, it syncs pending items to remote.

### Limitations
- iOS 27+ due to SwiftUI Re-order and Drag-Drop APIs
- Currently network status will fire immediately on network condition change, should have implemented throttle for timed sync.

### Features for future
- Optimize layout for iPad.
- Widgets (Interactive) support.
- App Intents
- More Unit tests
- Launch screen/Onboarding screen
- Undo, Re-do


