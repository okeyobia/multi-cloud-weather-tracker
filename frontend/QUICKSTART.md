# Frontend Quick Start Guide

## 🚀 Get Running in 5 Minutes

### Step 1: Install Dependencies (1 minute)

```bash
cd frontend
npm install
```

What happens: Installs Next.js, React, TailwindCSS, and dependencies (~500MB).

### Step 2: Configure Environment (1 minute)

```bash
cp .env.example .env.local
```

Edit `.env.local` and set your API URL:

```env
# Backend API endpoint
NEXT_PUBLIC_API_BASE_URL=http://localhost:8000
```

For Azure backend:
```env
NEXT_PUBLIC_API_BASE_URL=https://your-backend.azurewebsites.net
```

For AWS backend:
```env
NEXT_PUBLIC_API_BASE_URL=https://your-api-gateway.execute-api.us-east-1.amazonaws.com
```

### Step 3: Start Development Server (1 minute)

```bash
npm run dev
```

Output should show:
```
  ▲ Next.js 14.0.0
  - ready started server on 0.0.0.0:3000, url: http://localhost:3000
```

### Step 4: Open in Browser (1 minute)

Visit: http://localhost:3000

### Step 5: Test It Out (1 minute)

1. Click in the search box
2. Type a city name (e.g., "London")
3. Wait for results to appear
4. See the weather card with cloud provider badge
5. Check recent searches below the input

**Done!** ✅

---

## 📁 Project Structure at a Glance

```
frontend/
├── app/
│   ├── page.tsx          ← Main app page
│   ├── layout.tsx        ← HTML wrapper & theme
│   └── globals.css       ← Global styles
│
├── components/           ← React components
│   ├── SearchBar.tsx
│   ├── WeatherCard.tsx
│   ├── CloudBadge.tsx
│   ├── RecentSearches.tsx
│   └── HealthIndicator.tsx
│
├── lib/
│   ├── api.ts            ← API client
│   └── utils.ts          ← Helper functions
│
├── public/               ← Static assets
├── package.json          ← Dependencies
├── .env.local            ← Your secrets (never commit!)
└── README.md             ← Full documentation
```

---

## 🎯 Key Features to Try

### 1. Search Weather

Type a city name to see weather data appear with:
- 📍 Current temperature
- ☁️ Weather description
- 🌐 Which cloud provider (AWS or Azure)
- ⚡ Response time in milliseconds

### 2. View Recent Searches

Click any city in the "Recent Searches" section to search again instantly.

### 3. Check System Health

Red/Yellow/Green status indicator at top shows if system is:
- 🟢 **Healthy**: Everything's working
- 🟡 **Degraded**: Failover is active
- 🔴 **Down**: Backend unavailable

### 4. Dark Mode

System automatically detects your OS dark mode preference and switches theme.

### 5. Refresh Weather

Click the 🔄 refresh button to re-fetch latest data for current city.

---

## ⚙️ Common Commands

```bash
# Development (with hot reload)
npm run dev

# Production build
npm run build

# Run production build locally
npm start

# Type checking
npm run type-check

# Code formatting
npm run format

# Format validation
npm run format:check

# Linting
npm run lint
```

---

## 🧪 Testing the API

### Verify Backend is Responding

```bash
# Test if API is up
curl http://localhost:8000/health

# Test weather endpoint
curl "http://localhost:8000/weather?city=London"
```

### Expected Health Response

```json
{
  "status": "healthy",
  "message": "All systems operational",
  "primaryRegion": "us-east-1",
  "activeRegion": "us-east-1"
}
```

### Expected Weather Response

```json
{
  "city": "London",
  "temperature": 15.2,
  "description": "Partly cloudy",
  "cloudProvider": "AWS",
  "isFailover": false,
  "lastUpdated": "2024-02-12T10:30:00Z",
  "latency": 125
}
```

If these work, your frontend will too!

---

## 🐛 Troubleshooting

### Issue: "Cannot GET /"

**Solution**: Frontend likely didn't build. Try:
```bash
rm -rf .next
npm run build
npm start
```

### Issue: "Failed to fetch" errors

**Solution**: Check if backend is running at the URL in `.env.local`:
```bash
curl $NEXT_PUBLIC_API_BASE_URL/health
```

### Issue: Nothing appears when searching

**Solution**: 
1. Check browser DevTools Console (F12) for errors
2. Verify API URL in DevTools Network tab
3. Confirm backend returns correct JSON

### Issue: Dark mode not working

**Solution**: 
1. Check system dark mode setting
2. Or use browser DevTools: Rendering > prefers-color-scheme > dark

### Issue: Port 3000 already in use

**Solution**: Run on different port:
```bash
npm run dev -- -p 3001
```

---

## 📱 Browser Support

Works on:
- ✅ Chrome/Edge (latest 2 versions)
- ✅ Firefox (latest 2 versions)
- ✅ Safari (latest 2 versions)
- ✅ Mobile browsers (iOS 12+, Android 5+)

---

## 🚀 Next Steps

### For Development

1. **Add more weather details**: Expand `WeatherCard` with humidity, wind speed, etc.
2. **Add weather icons**: Use real weather icon library instead of emoji
3. **Add city autocomplete**: Suggest cities as user types
4. **Add favorites**: Save favorite cities
5. **Add charts**: Show temperature trends over time

### For Production

1. **Set up CI/CD**: GitHub Actions or Azure DevOps
2. **Configure monitoring**: Add error tracking (Sentry)
3. **Add analytics**: Track user behavior
4. **Set up logging**: Centralized log aggregation
5. **Configure CDN**: Cache static assets globally

### For DevOps

1. **Docker**: Build container image
2. **Kubernetes**: Deploy to k8s cluster
3. **Infrastructure**: Terraform configuration ready
4. **Monitoring**: Add APM integration
5. **Security**: WAF rules configured

---

## 📚 Full Documentation

For complete docs, see:
- [README.md](./README.md) - Full feature list
- [FEATURES.md](./FEATURES.md) - Detailed feature breakdown
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Deployment to production
- [../README.md](../README.md) - Project overview

---

## 💡 Tips for Success

✅ **Keep API URL handy**: You'll reference it often
✅ **Test both cloud providers**: See the failover work
✅ **Check recent searches**: Data persists across reloads
✅ **Monitor error states**: Try invalid city names
✅ **View page source**: See the clean component architecture
✅ **Inspect Network tab**: Watch API calls with latency
✅ **Test on mobile**: See responsive design in action

---

## 🎓 Learning Resources

Inside this project you'll find examples of:

1. **Next.js 14 App Router**: Modern routing with server/client components
2. **React Hooks**: useState, useEffect, useCallback patterns
3. **TypeScript**: Type-safe components and API calls
4. **TailwindCSS**: Utility-first CSS and custom components
5. **API Integration**: Fetching with error handling and timeouts
6. **State Management**: Local component state with localStorage
7. **Responsive Design**: Mobile-first with grid/flex
8. **Accessibility**: ARIA labels, keyboard nav, focus management
9. **Performance**: Debouncing, lazy loading, code splitting
10. **Dark Mode**: System preference detection and theming

---

## 🤝 Getting Help

1. **Frontend issues?** Check browser DevTools Console
2. **Backend not responding?** Verify `.env.local` URL
3. **Build errors?** Try `npm ci && npm run build`
4. **Styling questions?** See [Tailwind docs](https://tailwindcss.com/)
5. **Next.js questions?** See [Next.js docs](https://nextjs.org/docs)

---

**Ready to code? Run `npm run dev` and start building! 🚀**
