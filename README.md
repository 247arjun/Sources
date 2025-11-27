# Sources
A modern macOS RSS Reader app built with SwiftUI

## Features

### Phase 1 - MVP ✅

✅ **Three-Panel Layout**
- Left panel: Feed list with unread counts
- Middle panel: Article list with sorting and filtering
- Right panel: Article viewer with integrated WebKit

✅ **Feed Management**
- Add feeds by URL with auto-discovery
- Refresh individual or all feeds
- Delete feeds with context menu
- Visual feed icons and unread badges
- Folder organization for feeds
- Multi-select for bulk operations (move, delete)

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
- Keyboard shortcuts (⌘N, ⌘R, ⌘O, j/k/u)
- Context menus for quick actions
- Sorting (newest/oldest/title)
- Filter by unread status
- Relative timestamps

### Phase 2 - Core Features ✅

✅ **Smart Folders**
- All Feeds - View all articles across feeds
- Unread - Quick access to unread articles
- Starred - Saved articles for later reference
- Recent - Articles from last 1 day, 7 days, or custom date range

✅ **Full-Text Search**
- Search across article titles, content, summaries, and authors
- Real-time filtering as you type
- Works with all views (feeds, smart folders)

✅ **Auto-Refresh**
- Configurable automatic refresh intervals
- Settings window with enable/disable toggle
- Choose refresh frequency (5, 15, 30, 60 minutes)
- Background timer-based refresh

✅ **Keyboard Shortcuts**
- `j` - Next article
- `k` - Previous article
- `u` - Toggle read/unread
- `s` - Toggle star/unstar
- `⌘N` - Add new feed
- `⇧⌘N` - Add new folder
- `⌘R` - Refresh all feeds
- `⌘O` - Import OPML

✅ **OPML Import/Export**
- Import feeds from other RSS readers
- Export your feed collection
- Preserves folder structure
- Non-blocking background import
- Security-scoped file access

## Project Structure

```
Sources/
├── SourcesApp.swift              # App entry point
├── Models/
│   ├── Feed.swift                # RSS feed model
│   ├── Article.swift             # Article model
│   ├── Folder.swift              # Feed folder organization
│   ├── AppSettings.swift         # User preferences
│   └── OPMLDocument.swift        # OPML file document
├── ViewModels/
│   ├── FeedListViewModel.swift   # Feed management, OPML, folders
│   └── ArticleListViewModel.swift # Article list, search, smart folders
├── Views/
│   ├── ContentView.swift         # Main 3-panel layout
│   ├── SidebarView.swift         # Feed list with smart folders
│   ├── ArticleListView.swift     # Article list with search
│   ├── ArticleDetailView.swift   # Article viewer (Panel 3)
│   └── SettingsView.swift        # App preferences window
└── Services/
    ├── FeedParser.swift          # RSS/Atom XML parsing
    ├── FeedFetcher.swift         # Network fetching
    ├── OPMLParser.swift          # OPML import parser
    └── OPMLExporter.swift        # OPML export generator
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

### Adding Feeds
1. Click the **+** button in the sidebar or press ⌘N
2. Enter a feed URL or website URL (auto-discovery will find the feed)
3. Click **Add**

Example feeds to try:
- `https://daringfireball.net/feeds/main`
- `https://blog.swift.org/feed.xml`
- `https://www.theverge.com/rss/index.xml`

### Managing Feeds & Folders
- **Add Folder**: Click **+** → Add Folder or press ⇧⌘N
- **Move to Folder**: Right-click feed → Move to Folder
- **Multi-Select**: Click **+** → Select Feeds, then ⌘-click to select multiple
- **Bulk Move/Delete**: Select multiple feeds, right-click for bulk actions
- **Refresh**: Right-click feed → Refresh, or ⌘R for all feeds
- **Delete**: Right-click → Delete

### Smart Folders
- **All Feeds**: View all articles from all feeds
- **Unread**: Quick access to unread articles
- **Starred**: View all starred/saved articles
- **Recent**: Filter by date range (1 day, 7 days, or custom)

### Starring Articles
- **Star/Unstar**: Click star button in toolbar or press `s`
- **Starred Folder**: Access all starred articles from smart folders
- **Star Badge**: Yellow star indicator on starred articles in list
- Starred status is independent of read/unread

### Searching
- Use the search bar at the top of the article list
- Searches across titles, content, summaries, and authors
- Works with feeds and smart folders

### Reading Articles
- Click on any article in the middle panel to view it
- Articles are automatically marked as read when viewed
- Use toolbar buttons to toggle read/unread, star, share, or open in browser
- Navigate with keyboard: `j` (next), `k` (previous), `u` (toggle read), `s` (toggle star)

### Filtering & Sorting
- Use the **•••** menu in the article list to:
  - Sort by newest first, oldest first, or title
  - Toggle "Unread Only" filter
- Click **Mark All Read** to mark all articles as read

### OPML Import/Export
- **Import**: Click **+** → Import OPML (⌘O)
- **Export**: Click **+** → Export OPML
- Preserves folder structure and organization

### Settings
- Access via Sources → Settings or ⌘,
- Enable auto-refresh and set interval (5-60 minutes)
- Settings persist across app launches

## Architecture

**SwiftUI + SwiftData**: Modern declarative UI with efficient data persistence

**MVVM Pattern**: Clear separation between views and business logic

**Async/Await**: Native Swift concurrency for network operations

**RSS/Atom Support**: Custom XML parser supporting both feed formats

## Roadmap

### Phase 3 - Polish & Enhancements
- [x] Starred/favorite articles
- [ ] Article cache management
- [ ] Feed update notifications
- [ ] Podcast support
- [ ] Performance optimizations for large feeds
- [ ] Custom themes and appearance options
- [ ] macOS integration (Spotlight, Handoff)
- [ ] iCloud sync

## Known Limitations

- No podcast/audio enclosure support yet
- No iCloud sync
- No article caching (requires network for images)
- Smart folder counts update on app restart

## License

See LICENSE file for details.
