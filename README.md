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

✅ **Enhanced Menu Bar & Keyboard Shortcuts**
- **File Menu**: ⌘N (Add Feed), ⇧⌘N (Add Folder), ⌥⌘I (Import OPML), ⌥⌘E (Export OPML)
- **Edit Menu**: ⌘A (Select All), ⌘D (Deselect All)
- **View Menu**: ⌘1-4 (Smart Folders), ⌘F (Focus Search)
- **Article Menu**: ⌘U (Toggle Read), ⌘S (Toggle Star), ⇧⌘M (Mark All Read), ⌘O (Open in Browser), ⇧⌘C (Copy Link), ⇧⌘S (Share)
- **Feed Menu**: ⌘R (Refresh All), ⇧⌘R (Refresh Selected), ⌘E (Edit Feed), ⌘⌫ (Delete Feed)
- Full native macOS menu bar with keyboard-driven navigation
- Arrow keys for article navigation

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
│   ├── Article.swift             # Article model with starred status
│   ├── Folder.swift              # Feed folder organization
│   ├── AppSettings.swift         # User preferences & cache settings
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
    ├── OPMLExporter.swift        # OPML export generator
    └── CacheManager.swift        # Article cache with LRU eviction
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
- **Collapse Folders**: Click disclosure triangle to collapse/expand folders (reduces scrolling)
- **Multi-Select**: Click **+** → Select Feeds, then ⌘-click to select multiple
- **Bulk Move/Delete**: Select multiple feeds, right-click for bulk actions
- **Mark All as Read**: Right-click on folders, feeds, or smart folders for bulk mark as read
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
- Debounced search (300ms) for optimal performance

### Reading Articles
- Click on any article in the middle panel to view it
- Articles are automatically marked as read when viewed
- Use toolbar buttons to toggle read/unread, star, share, or open in browser
- Navigate with arrow keys or use keyboard shortcuts: ⌘U (toggle read), ⌘S (toggle star)

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
- **Auto-Refresh**: Enable auto-refresh and set interval (5-60 minutes)
- **Cache Management**: 
  - Set cache size limits (50MB - 1GB or unlimited)
  - Set cache age limits (7-90 days or never expire)
  - View cache statistics (size, article count, last cleanup)
  - Clear cache manually with confirmation
  - Automatic cache cleanup on app startup and settings changes
- Settings persist across app launches

## Architecture

**SwiftUI + SwiftData**: Modern declarative UI with efficient data persistence

**MVVM Pattern**: Clear separation between views and business logic

**Async/Await**: Native Swift concurrency for network operations

**RSS/Atom Support**: Custom XML parser supporting both feed formats

**Performance Optimizations**: Database-level predicates, search debouncing, query limits, optimized image loading

## Roadmap

### Phase 3 - Polish & Enhancements
- [x] Starred/favorite articles
- [x] Article cache management
- [x] Enhanced macOS Menu Bar support
- [x] Performance optimizations for large feeds
- [x] Collapsible folders and Mark All as Read
- [ ] Feed update notifications
- [ ] Custom themes and appearance options
- [ ] macOS integration (Spotlight, Handoff)
- [ ] iCloud sync

## Performance

- Database-level predicate filtering for efficient queries
- 300ms search debouncing to reduce query load while typing
- Fetch limit of 1000 articles per view for optimal memory usage
- Optimized image loading with proper phase handling and fallbacks
- Unique constraint on Article IDs to prevent duplicates

## Known Limitations

- No podcast/audio enclosure support yet
- No iCloud sync
- Article images still require network (only HTML content is cached)
- Smart folder counts update on app restart
- Text search uses in-memory filtering (database can't efficiently do case-insensitive contains)

## License

See LICENSE file for details.
