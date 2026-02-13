# Frontend Architecture & Component Interaction

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     Browser & Device Layer                              │
│  (Chrome, Safari, Firefox, Mobile Browsers)                             │
└───────────────────────────┬─────────────────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────────────────┐
│                    Next.js 14 Frontend Application                      │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │                      app/layout.tsx                              │  │
│  │  - Theme setup (light/dark mode)                                │  │
│  │  - Background animations                                        │  │
│  │  - Metadata & SEO                                               │  │
│  │  - Global CSS (globals.css)                                     │  │
│  └──────────────────────────┬──────────────────────────────────────┘  │
│                             │                                           │
│  ┌──────────────────────────▼──────────────────────────────────────┐  │
│  │                      app/page.tsx                                │  │
│  │  Main Application Logic                                          │  │
│  │  - State management (useState)                                  │  │
│  │  - Search handling                                              │  │
│  │  - Recent searches (localStorage)                               │  │
│  │  - Dark mode detection                                          │  │
│  │                                                                 │  │
│  │  ┌─────────── Component Tree ──────────┐                       │  │
│  │  │                                     │                       │  │
│  │  ├─ HealthIndicator                   │                       │  │
│  │  │  (Polls /health every 15s)          │                       │  │
│  │  │  ├─ Status badge                    │                       │  │
│  │  │  ├─ Failover warning                │                       │  │
│  │  │  └─ Service down alert              │                       │  │
│  │  │                                     │                       │  │
│  │  ├─ SearchBar                          │                       │  │
│  │  │  (Debounced input with validation)  │                       │  │
│  │  │  ├─ Search icon                     │                       │  │
│  │  │  ├─ Input field                     │                       │  │
│  │  │  ├─ Clear button                    │                       │  │
│  │  │  └─ Refresh button                  │                       │  │
│  │  │                                     │                       │  │
│  │  ├─ RecentSearches                     │                       │  │
│  │  │  (Shows stored searches)            │                       │  │
│  │  │  ├─ Search history list             │                       │  │
│  │  │  ├─ Click to select                 │                       │  │
│  │  │  └─ Search stats                    │                       │  │
│  │  │                                     │                       │  │
│  │  ├─ WeatherCard                        │                       │  │
│  │  │  (Displays weather data)            │                       │  │
│  │  │  ├─ Skeleton loader (loading)       │                       │  │
│  │  │  ├─ City name & timestamp           │                       │  │
│  │  │  ├─ CloudBadge (AWS/Azure)          │                       │  │
│  │  │  ├─ Weather icon & temp             │                       │  │
│  │  │  ├─ Cloud provider source           │                       │  │
│  │  │  ├─ Response latency                │                       │  │
│  │  │  ├─ Failover banner (if active)     │                       │  │
│  │  │  └─ Error state with retry          │                       │  │
│  │  │                                     │                       │  │
│  │  └─ FeatureCard (when no data)         │                       │  │
│  │     ├─ Multi-Cloud feature             │                       │  │
│  │     ├─ Instant Failover feature        │                       │  │
│  │     └─ Local History feature           │                       │  │
│  │                                     │                       │  │
│  │  Stats Display (when weather loaded) │                       │  │
│  │  ├─ Total searches count               │                       │  │
│  │  ├─ Active region                      │                       │  │
│  │  ├─ Response time                      │                       │  │
│  │  └─ System status                      │                       │  │
│  │                                     │                       │  │
│  └─────────────────────────────────────┘                       │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │         lib/ - Shared Logic & API Layer                     │  │
│  │                                                             │  │
│  │  lib/api.ts:                                               │  │
│  │  ├─ fetchWeather(city) → WeatherResponse                  │  │
│  │  ├─ fetchHealthStatus() → HealthStatus                    │  │
│  │  ├─ getWeatherIcon(desc) → emoji                          │  │
│  │  ├─ formatTemperature(temp) → string                      │  │
│  │  └─ formatDate(dateString) → string                       │  │
│  │                                                             │  │
│  │  lib/utils.ts:                                             │  │
│  │  ├─ cn() - class name utility                             │  │
│  │  ├─ debounce() - input debouncing                         │  │
│  │  ├─ isDarkMode() - theme detection                        │  │
│  │  ├─ isValidCity() - input validation                      │  │
│  │  └─ getContrastingText() - color utility                  │  │
│  │                                                             │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │        app/globals.css - Styling Layer                     │  │
│  │                                                             │  │
│  │  ├─ Tailwind Base (HTML defaults)                         │  │
│  │  ├─ Tailwind Components (custom classes)                  │  │
│  │  ├─ Tailwind Utilities (single-purpose classes)           │  │
│  │  ├─ Custom animations (blob, pulse-ring)                  │  │
│  │  ├─ Glassmorphism effects                                 │  │
│  │  ├─ Dark mode support                                     │  │
│  │  ├─ Accessibility (focus, contrast)                       │  │
│  │  └─ Print styles                                          │  │
│  │                                                             │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┴────────────────────┐
        │                                         │
┌───────▼───────────────────┐      ┌──────────────▼──────────┐
│  Backend API Endpoints    │      │  Browser Local Storage  │
│                           │      │                         │
│  GET /weather?city=       │      │  localStorage:          │
│  └─ Returns:              │      │  ├─ recentSearches     │
│    {                      │      │  │  (JSON array)       │
│    city,                  │      │  └─ [Limited to 10]    │
│    temperature,           │      │                         │
│    description,           │      │  Persists across:      │
│    cloudProvider,         │      │  ├─ Page reloads       │
│    isFailover,            │      │  ├─ Browser restarts   │
│    lastUpdated,           │      │  └─ Tab closures       │
│    latency                │      │                         │
│    }                      │      │                         │
│                           │      │                         │
│  GET /health              │      │  System Preferences:   │
│  └─ Returns:              │      │  ├─ Dark mode          │
│    {                      │      │  │  (prefers-color-   │
│    status,                │      │  │   scheme)          │
│    message,               │      │  └─ Reduced motion     │
│    primaryRegion,         │      │     (prefers-reduced-  │
│    activeRegion           │      │     motion)            │
│    }                      │      │                         │
│                           │      │                         │
└───────────────────────────┘      └──────────────────────────┘
```

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         User Interaction                             │
└────────┬────────────────────────────────────────────────────────────┘
         │
         ├─ [Types city name]
         │  └─ SearchBar.tsx: onChange
         │     └─ page.tsx: setInput()
         │        └─ debounce(500ms)
         │           └─ handleSearch()
         │
         ├─ [Clicks city in recent searches]
         │  └─ RecentSearches.tsx: onClick
         │     └─ page.tsx: handleRecentSearch()
         │        └─ handleSearch(city)
         │
         └─ [Clicks refresh button]
            └─ SearchBar.tsx: onRefresh
               └─ page.tsx: handleRefresh()
                  └─ handleSearch(previousCity)

                           │
                           ▼

┌─────────────────────────────────────────────────────────────────────┐
│                    API Request Flow                                  │
│                                                                     │
│  1. lib/api.ts: fetchWeather(city)                                 │
│     ├─ Start performance timer                                      │
│     ├─ Set 10s abort timeout                                       │
│     ├─ Encode city name for URL                                    │
│     ├─ Make GET /weather?city=London                               │
│     ├─ Handle response status:                                      │
│     │  ├─ 200: Parse to WeatherResponse                            │
│     │  ├─ 404: Throw "City not found"                              │
│     │  ├─ 503: Throw "Service unavailable"                         │
│     │  └─ Other: Throw error message                               │
│     ├─ Calculate latency (performance timer end)                    │
│     └─ Return { ...data, latency }                                 │
│                                                                     │
└────────────────┬────────────────────────────────────────────────────┘
                 │
                 ▼

┌─────────────────────────────────────────────────────────────────────┐
│                    State Update                                      │
│                                                                     │
│  2. page.tsx in try/catch:                                          │
│     ├─ On success:                                                  │
│     │  ├─ setState({ weather: data, error: null })                │
│     │  ├─ addToRecentSearches(city)                                │
│     │  │  └─ localStorage.setItem()                                │
│     │  └─ UI re-renders with new data                              │
│     │                                                               │
│     └─ On error:                                                    │
│        ├─ setState({ error: message })                             │
│        └─ UI shows error state with retry button                   │
│                                                                     │
└────────────────┬────────────────────────────────────────────────────┘
                 │
                 ▼

┌─────────────────────────────────────────────────────────────────────┐
│                    UI Rendering                                      │
│                                                                     │
│  3. Components render with new state:                               │
│     ├─ WeatherCard                                                  │
│     │  ├─ If loading: Show skeleton loader                         │
│     │  ├─ If error: Show error message + retry button              │
│     │  ├─ If data: Show weather card with:                         │
│     │  │  ├─ City name                                             │
│     │  │  ├─ Temperature & icon                                    │
│     │  │  ├─ CloudBadge (AWS/Azure)                                │
│     │  │  ├─ Failover warning (if applicable)                      │
│     │  │  ├─ Response latency                                      │
│     │  │  └─ Last updated timestamp                                │
│     │  └─ If empty: Show "Search for a city" message               │
│     │                                                               │
│     ├─ RecentSearches                                               │
│     │  └─ Show up to 5 recent searches as clickable buttons        │
│     │                                                               │
│     ├─ HealthIndicator (runs independently)                        │
│     │  ├─ Poll /health every 15s                                   │
│     │  ├─ Update status badge (🟢 🟡 🔴)                           │
│     │  ├─ Show failover alert if degraded                          │
│     │  └─ Show down alert if offline                               │
│     │                                                               │
│     └─ Stats Card                                                  │
│        ├─ Show total searches                                      │
│        ├─ Show active region                                       │
│        ├─ Show response latency                                    │
│        └─ Show system status                                       │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Component Dependency Tree

```
page.tsx (Main Component)
│
├── Props/Context: state, handlers
│
├─ HealthIndicator
│  ├─ Props: pollInterval
│  ├─ Internal: health, isChecking
│  ├─ Effects: 
│  │  └─ fetchHealthStatus() every 15s
│  └─ Renders: Status badge, warnings, alerts
│
├─ SearchBar
│  ├─ Props: onSearch, isLoading, onRefresh
│  ├─ Internal: input, isFocused
│  ├─ Callbacks:
│  │  ├─ handleClear()
│  │  ├─ handleKeyDown()
│  │  └─ debouncedSearch()
│  └─ Renders: Input field, buttons, loading indicator
│
├─ RecentSearches
│  ├─ Props: searches[], onSelect, isLoading, maxItems
│  ├─ Logic: Filter to maxItems, show count
│  └─ Renders: Clickable search buttons
│
├─ WeatherCard
│  ├─ Props: weather, isLoading, error, onRetry
│  ├─ Exports: SkeletonLoader subcomponent
│  ├─ Logic:
│  │  ├─ Format temperature
│  │  ├─ Get weather icon
│  │  └─ Format date
│  └─ Renders: 
│     ├─ Skeleton (loading)
│     ├─ Error state (if error)
│     ├─ Weather card (if data)
│     └─ Empty state (if no data)
│
├─ CloudBadge
│  ├─ Props: provider ('AWS'|'Azure'), isFailover
│  └─ Renders: Color-coded badge with icon
│
└─ FeatureCard (inline in page.tsx)
   ├─ Props: icon, title, description
   └─ Renders: Feature display card

────────────────────────────────────────────

lib/api.ts (Service Layer)
├─ fetchWeather(city, timeout)
│  └─ Returns: WeatherResponse | throws Error
│
├─ fetchHealthStatus()
│  └─ Returns: HealthStatus
│
├─ getWeatherIcon(description)
│  └─ Returns: emoji string
│
├─ formatTemperature(temp, unit)
│  └─ Returns: formatted string
│
└─ formatDate(dateString)
   └─ Returns: formatted time string

lib/utils.ts (Utility Layer)
├─ cn(...classes)
│  └─ Returns: concatenated className
│
├─ debounce(func, delay)
│  └─ Returns: debounced function
│
├─ isDarkMode()
│  └─ Returns: boolean
│
├─ isValidCity(name)
│  └─ Returns: boolean
│
└─ getContrastingText(bg)
   └─ Returns: color class name

────────────────────────────────────────────

app/layout.tsx
├─ Metadata & SEO
├─ Theme setup
├─ Background animation divs
└─ Footer

app/globals.css
├─ @tailwind directives
├─ Custom animations
├─ Glassmorphism effects
├─ Dark mode colors
├─ Accessibility features
└─ Print styles
```

## State Management Flow

```
└─ page.tsx STATE
   │
   ├─ weather: WeatherResponse | null
   │  └─ City, temperature, description, cloud provider
   │
   ├─ isLoading: boolean
   │  └─ True while fetching, triggers skeleton loader
   │
   ├─ error: string | null
   │  └─ Error message, shows error state
   │
   ├─ recentSearches: string[]
   │  └─ Stored in localStorage, persists rebuild
   │
   ├─ isDarkMode: boolean
   │  └─ Detected from system preference
   │
   └─ EFFECTS
      │
      ├─ useEffect (on mount)
      │  ├─ Load recent searches from localStorage
      │  ├─ Detect system dark mode
      │  └─ Set up media query listener
      │
      └─ useCallback (memoized functions)
         ├─ handleSearch(city)
         ├─ handleRetry()
         ├─ handleRecentSearch(city)
         ├─ handleRefresh()
         └─ addToRecentSearches(city)
```

## Network Request Lifecycle

```
1. User Input
   └─ Debounce 500ms
      
2. API Request (lib/api.ts)
   ├─ Start: performance.now()
   ├─ Create AbortController (10s timeout)
   ├─ Headers: Content-Type, Accept
   ├─ URL: /weather?city=...
   └─ Options: cache='no-store'
      
3. Response Handling
   ├─ Check status
   ├─ Parse JSON
   ├─ Calculate latency (end - start)
   ├─ Return WeatherResponse + latency
   └─ Or: throw Error
      
4. State Update (page.tsx)
   ├─ Success: setState({ weather, error: null })
   ├─ Error: setState({ error, weather: null })
   ├─ Save to localStorage
   └─ Finally: setIsLoading(false)
      
5. Re-render
   ├─ WeatherCard receives new props
   ├─ Displays weather or error
   └─ Animation/transition plays
      
6. Health Poll (HealthIndicator)
   ├─ Every 15 seconds
   ├─ Fetch /health endpoint
   ├─ Update status badge
   ├─ Show warnings if needed
   └─ No state interaction with weather
```

---

**This architecture ensures:**
- ✅ Clean separation of concerns
- ✅ Reusable components
- ✅ Easy to test
- ✅ Scalable structure
- ✅ Maintainable code
