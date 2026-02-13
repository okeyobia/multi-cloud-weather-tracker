# Frontend Deployment Guide

## Quick Start

```bash
# Install dependencies
npm install

# Configure environment
cp .env.example .env.local
# Edit .env.local with your backend API URL

# Start development
npm run dev
```

The application will be available at `http://localhost:3000`.

## Environment Configuration

### Development (Local)

```env
NEXT_PUBLIC_API_BASE_URL=http://localhost:8000
```

### Staging (Azure)

```env
NEXT_PUBLIC_API_BASE_URL=https://weather-api-staging.azurewebsites.net
```

### Production

```env
NEXT_PUBLIC_API_BASE_URL=https://api.weather-tracker.com
```

## Build for Production

```bash
# Create optimized production build
npm run build

# Test production build locally
npm start
```

## Deployment Options

### Option 1: Vercel (Recommended)

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel

# Set environment variables
vercel env add NEXT_PUBLIC_API_BASE_URL
```

### Option 2: Azure Static Web Apps

```bash
# Using Azure CLI
az staticwebapp create \
  --name weather-tracker-frontend \
  --resource-group weather-tracker-rg \
  --source /path/to/frontend \
  --branch main \
  --app-location /frontend

# Set environment variables
az staticwebapp appsettings set \
  --name weather-tracker-frontend \
  --setting-names NEXT_PUBLIC_API_BASE_URL=https://your-api.com
```

### Option 3: AWS Amplify

```bash
# Using AWS Amplify CLI
amplify init
amplify add hosting
amplify publish

# Configure API URL in Amplify Console
```

### Option 4: Docker

```bash
# Build Docker image
docker build -t weather-tracker-frontend:latest .

# Run container
docker run -p 3000:3000 \
  -e NEXT_PUBLIC_API_BASE_URL=http://backend:8000 \
  weather-tracker-frontend:latest
```

### Option 5: Kubernetes

```bash
# Apply Kubernetes manifest
kubectl apply -f k8s/frontend-deployment.yaml
```

## Health Checks

The frontend includes automatic health monitoring. Ensure your backend `/health` endpoint returns:

```json
{
  "status": "healthy|degraded|down",
  "message": "Status message",
  "primaryRegion": "us-east-1",
  "activeRegion": "us-east-1"
}
```

## Performance Monitoring

### Core Web Vitals

- **LCP** (Largest Contentful Paint): < 2.5s
- **FID** (First Input Delay): < 100ms
- **CLS** (Cumulative Layout Shift): < 0.1

### Optimization Tips

1. **Image Optimization**: Use Next.js Image component
2. **Code Splitting**: Components automatically split
3. **Caching**: Long TTL for static assets
4. **Compression**: Gzip enabled by default
5. **Minification**: Automatic in production

## Security Checklist

- [ ] API URL set in environment variables
- [ ] HTTPS enabled in production
- [ ] Security headers configured (see next.config.js)
- [ ] No sensitive data in code
- [ ] CORS properly configured on backend
- [ ] CSP headers set
- [ ] Cookies httpOnly flag set

## Monitoring & Logging

### Frontend Error Tracking

```typescript
// Optional: Add Sentry integration
import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
});
```

### Analytics

```typescript
// Optional: Add Google Analytics
import { Analytics } from '@vercel/analytics/react';

export default function App() {
  return (
    <>
      <YourApp />
      <Analytics />
    </>
  );
}
```

## Rollback Procedure

### Vercel
```bash
vercel rollback
```

### Azure Static Web Apps
```bash
az staticwebapp update -n weather-tracker-frontend --branch staging
```

### Docker
```bash
docker run -p 3000:3000 weather-tracker-frontend:previous-tag
```

## Troubleshooting

### CORS Errors

Ensure backend has CORS headers configured:

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type
```

### Blank Page

1. Check browser console for errors
2. Verify API URL in environment variables
3. Check network tab for failed requests

### Build Failures

```bash
# Clear cache
rm -rf .next node_modules
npm ci
npm run build
```

## Support

See main [README.md](./README.md) for full documentation.
