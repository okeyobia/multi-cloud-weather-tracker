# Multi-Cloud Weather Tracker Frontend

Production-ready Next.js 14 application for the Multi-Cloud Weather Tracker project.

## Features

- 🌍 **Multi-Cloud Support**: Seamlessly switches between AWS and Azure
- 🚀 **Instant Failover**: Automatic switchover with visual indicators
- 📱 **Fully Responsive**: Mobile-first design with TailwindCSS
- 🎨 **Modern UI**: Cloud-inspired gradients, glassmorphism, and smooth animations
- 💾 **Local Storage**: Recent searches persist across sessions
- ⚡ **Performance**: Debounced search, optimized rendering, fast load times
- 🌙 **Dark Mode**: Automatic dark mode based on system preferences
- 📊 **Health Monitoring**: Real-time system status with 15-second polling
- ♿ **Accessible**: WCAG 2.1 compliant with keyboard navigation
- 🔒 **Secure**: No exposed API keys, environment-based configuration

## Tech Stack

- **Framework**: Next.js 14 (App Router)
- **Language**: TypeScript
- **Styling**: TailwindCSS with custom configurations
- **State Management**: React Hooks (useState, useEffect)
- **HTTP Client**: Fetch API with timeout handling
- **Icons**: Unicode/Emoji (no external icon library)

## Getting Started

### Prerequisites

- Node.js 18+ 
- npm 9+ or yarn 4+

### Installation

```bash
# Install dependencies
npm install

# Configure environment
cp .env.example .env.local
# Edit .env.local with your API base URL
```

### Development

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

### Production Build

```bash
npm run build
npm start
```

## Project Structure

```
frontend/
├── app/
│   ├── page.tsx                 # Main application page
│   ├── layout.tsx               # Root layout with theme setup
│   └── globals.css              # Global styles and animations
├── components/
│   ├── SearchBar.tsx            # City search input with debounce
│   ├── WeatherCard.tsx          # Weather display card
│   ├── CloudBadge.tsx           # Cloud provider indicator
│   ├── RecentSearches.tsx       # Recent searches list
│   └── HealthIndicator.tsx      # System health status
├── lib/
│   ├── api.ts                   # API client and utilities
│   └── utils.ts                 # Helper functions
├── public/                      # Static assets
├── tailwind.config.ts           # TailwindCSS configuration
├── tsconfig.json                # TypeScript configuration
├── next.config.js               # Next.js configuration
├── package.json                 # Dependencies
├── .env.local                   # Local environment (NEVER COMMIT)
├── .env.example                 # Environment template
└── .gitignore                   # Git ignore rules
```

## Environment Variables

### Required

- `NEXT_PUBLIC_API_BASE_URL` - Backend API URL (e.g., http://localhost:8000)

### Optional

- `NEXT_PUBLIC_HEALTH_CHECK_INTERVAL` - Health check polling interval (default: 15000ms)
- `NEXT_PUBLIC_ENABLE_HEALTH_INDICATOR` - Show health status (default: true)
- `NEXT_PUBLIC_ENABLE_DARK_MODE` - Enable dark mode support (default: true)
- `NEXT_PUBLIC_MAX_RECENT_SEARCHES` - Maximum recent searches to store (default: 10)
- `NEXT_PUBLIC_REQUEST_TIMEOUT` - API request timeout (default: 10000ms)

## Component Documentation

### SearchBar

Location: `components/SearchBar.tsx`

Handles city search with debounced input (500ms delay).

**Props:**
- `onSearch: (city: string) => void` - Called when search is submitted
- `isLoading?: boolean` - Show loading state
- `onRefresh?: () => void` - Refresh button callback

**Features:**
- Debounced search input
- Clear button
- Refresh button
- Input validation
- Loading indicator

### WeatherCard

Location: `components/WeatherCard.tsx`

Displays weather information with cloud provider details.

**Props:**
- `weather: WeatherResponse | null` - Weather data
- `isLoading?: boolean` - Show skeleton loader
- `error?: string | null` - Error message
- `onRetry?: () => void` - Retry callback

**Features:**
- Skeleton loader during fetch
- Error state with retry button
- Cloud provider badge
- Response latency display
- Formatted temperature
- Weather description
- Empty state message

### CloudBadge

Location: `components/CloudBadge.tsx`

Shows which cloud provider is currently active.

**Props:**
- `provider: 'AWS' | 'Azure'` - Active cloud provider
- `isFailover?: boolean` - Indicate if failover is active

**Features:**
- Color-coded badges (AWS: orange, Azure: blue)
- Failover indicator
- Visual distinction for secondary regions

### RecentSearches

Location: `components/RecentSearches.tsx`

Displays recently searched cities with quick access.

**Props:**
- `searches: string[]` - List of recent searches
- `onSelect: (city: string) => void` - Called when item is clicked
- `isLoading?: boolean` - Disable while loading
- `maxItems?: number` - Max items to display (default: 5)

**Features:**
- Clickable search history
- Limits to recent N searches
- Shows total search count
- Disabled state during loading

### HealthIndicator

Location: `components/HealthIndicator.tsx`

Polls backend health status and displays system status.

**Props:**
- `pollInterval?: number` - Polling interval in ms (default: 15000)

**Features:**
- Automatic polling every 15 seconds
- Green/yellow/red status indicator
- Failover warning banner
- Service down alert
- Graceful fallback on API failure

## API Integration

### Weather Endpoint

```bash
GET /weather?city=London
```

**Response:**
```json
{
  "city": "London",
  "temperature": 15.2,
  "description": "Partly cloudy",
  "cloudProvider": "AWS",
  "isFailover": false,
  "lastUpdated": "2024-02-12T10:30:00Z",
  "weatherIcon": "⛅",
  "latency": 125
}
```

### Health Endpoint

```bash
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "message": "All systems operational",
  "primaryRegion": "us-east-1",
  "activeRegion": "us-east-1",
  "lastChecked": "2024-02-12T10:30:15Z"
}
```

## Styling Guide

### Color Scheme

- **Primary**: Blue gradient (AWS-inspired)
- **Secondary**: Sky/Cyan accents
- **Accent**: Orange (AWS) and Blue (Azure)
- **Neutral**: Gray scale for text and borders

### Typography

- **Display**: Bold, large (5xl-4xl)
- **Heading**: Semibold (lg-xl)
- **Body**: Regular (base)
- **Small**: xs-sm for metadata

### Spacing

Follows TailwindCSS default spacing scale:
- Small: 2-4 units (8px-16px)
- Medium: 6-8 units (24px-32px)
- Large: 10-12 units (40px-48px)

### Animations

- **Fade In**: 0.5s ease-in-out
- **Slide Up**: 0.5s ease-out
- **Blob**: 7s infinite (background)
- **Pulse**: Smooth transitions on all interactive elements

## Performance Optimizations

1. **Debounced Search**: 500ms delay to reduce API calls
2. **Lazy Component Loading**: Components load on demand
3. **Image Optimization**: Next.js Image component ready
4. **CSS-in-JS**: TailwindCSS JIT compilation
5. **API Caching**: No-store by default (configurable)
6. **Minified Production Build**: Automatic via Next.js

## Production Deployment

### Build Optimization

```bash
npm run build
npm run type-check
npm run lint
```

### Environment Setup

Create `.env.production` with production URLs:

```env
NEXT_PUBLIC_API_BASE_URL=https://api.production.com
```

### Deployment Platforms

- **Vercel**: `vercel deploy`
- **AWS Amplify**: `amplify deploy`
- **Azure Static Web Apps**: Azure Portal integration

### Docker Deployment

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]
```

## Security Considerations

- ✅ No API keys in client code
- ✅ All secrets in environment variables
- ✅ HTTPS enforcement in production
- ✅ CSP headers configured
- ✅ XSS protection enabled
- ✅ CSRF protection ready
- ✅ Input validation on search

## Accessibility

- ✅ Semantic HTML
- ✅ ARIA labels for interactive elements
- ✅ Keyboard navigation support
- ✅ Focus indicators
- ✅ Color contrast compliance (WCAG AA)
- ✅ Reduced motion support

## Browser Support

- Chrome/Edge: Latest 2 versions
- Firefox: Latest 2 versions
- Safari: Latest 2 versions
- Mobile: iOS Safari 12+, Chrome for Android

## Troubleshooting

### API Connection Issues

```bash
# Verify API URL in .env.local
NEXT_PUBLIC_API_BASE_URL=http://localhost:8000

# Test endpoint manually
curl http://localhost:8000/health
```

### Build Errors

```bash
# Clear cache and rebuild
rm -rf .next
npm run build
```

### Dark Mode Not Working

Check browser settings:
- System: Settings > Display > Dark mode
- Browser: Chrome DevTools > Rendering > Emulate CSS media feature prefers-color-scheme

## Contributing

1. Follow TypeScript strict mode
2. Use functional components with hooks
3. Maintain responsive design
4. Test on mobile devices
5. Ensure accessibility compliance

## License

MIT

## Support

For issues and questions:
- Check [API Documentation](../README.md)
- Review [Terraform Infrastructure](../../terraform/)
- Check browser console for errors

---

**Built with ❤️ for multi-cloud deployments**
