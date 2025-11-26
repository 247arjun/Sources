# Sources
A modern macOS RSS Reader app built with SwiftUI

## What's Working

1. ✅ **Add feeds** - Successfully adds RSS/Atom feeds with auto-discovery
2. ✅ **Refresh feeds** - Fetches new articles and updates the feed
3. ✅ **Display articles** - Shows all articles in the list view
4. ✅ **3-panel layout** - Sidebar, article list, and article detail all functional
5. ✅ **Read articles** - WebView displays article content
6. ✅ **Mark as read/unread** - Toggle read status on articles
7. ✅ **Sort & filter** - Sort by date/title, filter unread only
8. ✅ **SwiftData persistence** - All data saved locally

## Features (Phase 1 - MVP)

✅ **Three-Panel Layout**
- Left panel: Feed list with unread counts
- Middle panel: Article list with sorting and filtering
- Right panel: Article viewer with integrated WebKit

✅ **Feed Management**
- Add feeds by URL with auto-discovery
- Refresh individual or all feeds
- Delete feeds with context menu
- Visual feed icons and unread badges

✅ **Article Reading**
- Clean WebKit-based article rendering
- Automatic read status tracking
- Manual mark as read/unread
- Share and open in browser
- Dark mode support

✅ **Data Persistence**
- SwiftData for local storage
- Efficient relationship management
- Automatic cascading deletes

✅ **User Experience**
- Keyboard shortcuts (⌘N for new feed)
- Context menus for quick actions
- Sorting (newest/oldest/title)
- Filter by unread status
- Relative timestamps

## Project Structure

```
Sources/
├── SourcesApp.swift              # App entry point
├── Models/
│   ├── Feed.swift                # RSS feed model
│   └── Article.swift             # Article model
├── ViewModels/
│   ├── FeedListViewModel.swift   # Feed management logic
│   └── ArticleListViewModel.swift # Article list logic
├── Views/
│   ├── ContentView.swift         # Main 3-panel layout
│   ├── SidebarView.swift         # Feed list (Panel 1)
│   ├── ArticleListView.swift     # Article list (Panel 2)
│   └── ArticleDetailView.swift   # Article viewer (Panel 3)
└── Services/
    ├── FeedParser.swift          # RSS/Atom XML parsing
    └── FeedFetcher.swift         # Network fetching
```

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Getting Started

1. Open `Sources.xcodeproj` in Xcode
2. Select your development team in the project settings (if needed)
3. Build and run (⌘R)

## Usage

### Adding a Feed
1. Click the **+** button in the sidebar or press ⌘N
2. Enter a feed URL or website URL (auto-discovery will find the feed)
3. Click **Add**

Example feeds to try:
- `https://daringfireball.net/feeds/main`
- `https://blog.swift.org/feed.xml`
- `https://www.theverge.com/rss/index.xml`

### Managing Feeds
- **Refresh**: Right-click on a feed → Refresh
- **Refresh All**: Click the refresh button in the toolbar
- **Delete**: Right-click on a feed → Delete

### Reading Articles
- Click on any article in the middle panel to view it
- Articles are automatically marked as read when viewed
- Use the toolbar buttons to:
  - Toggle read/unread status
  - Share the article
  - Open in your default browser

### Filtering & Sorting
- Use the **•••** menu in the article list to:
  - Sort by newest first, oldest first, or title
  - Toggle "Unread Only" filter
- Click **Mark All Read** to mark all articles in the current feed as read

## Architecture

**SwiftUI + SwiftData**: Modern declarative UI with efficient data persistence

**MVVM Pattern**: Clear separation between views and business logic

**Async/Await**: Native Swift concurrency for network operations

**RSS/Atom Support**: Custom XML parser supporting both feed formats

## Known Limitations (Phase 1)

- No folder organization yet
- No OPML import/export
- No full-text search
- No podcast support
- No automatic background refresh
- No iCloud sync

## Roadmap

### Phase 2 - Core Features
- Folder organization
- Search functionality
- Automatic refresh intervals
- Advanced keyboard shortcuts
- OPML import/export

### Phase 3 - Enhancements
- Reader mode for clean article viewing
- Starred/favorite articles
- Performance optimizations
- Preferences window
- macOS integration (Spotlight, Handoff)

## License

See LICENSE file for details.
