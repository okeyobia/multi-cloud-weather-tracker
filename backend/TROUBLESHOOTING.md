# Troubleshooting Guide

## Common Errors and Solutions

### Error: "Weather data not found for city: New York" (404)

This error occurs when the API cannot fetch weather data for the requested city. Here are the most common causes and solutions:

## Diagnostics First

Check your API configuration and dependencies:

```bash
curl http://localhost:8000/diagnostics
```

This will show you:
- Whether your OpenWeatherMap API key is configured
- If Redis is connected
- If the weather API is accessible

## Solution 1: Verify OpenWeatherMap API Key

### Problem
API key is missing, invalid, or expired.

### Solution

1. **Get a valid API key:**
   - Visit https://openweathermap.org/api
   - Sign up for a free account
   - Go to "API keys" tab
   - Copy your API key

2. **Update .env file:**
   ```bash
   # Edit the .env file
   OPENWEATHER_API_KEY="your_actual_api_key_here"
   ```

3. **Restart the application:**
   ```bash
   # Stop the current process (Ctrl+C)
   # Then restart:
   uvicorn app.main:app --reload
   ```

4. **Test the API:**
   ```bash
   curl http://localhost:8000/diagnostics
   
   # Should show:
   # "openweather_api": {
   #   "key_status": "configured",
   #   "accessible": true
   # }
   ```

### How to verify your API key works:

```bash
# Replace YOUR_API_KEY and CITY_NAME
curl "https://api.openweathermap.org/data/2.5/weather?q=London&appid=YOUR_API_KEY&units=metric"
```

If you see weather data, your key is valid. If you get an error, fix the key.

## Solution 2: Check City Name Format

### Problem
City name is not recognized by OpenWeatherMap API.

### Solution

1. **Use proper city names:**
   - ✅ `London`
   - ✅ `New York`
   - ✅ `Tokyo`
   - ✅ `Paris`
   - ✅ `Sydney`

2. **City names with spaces (URL encoded):**
   ```bash
   # WRONG (browser auto-encodes spaces)
   curl "http://localhost:8000/weather?city=New York"
   
   # RIGHT (explicitly encoded)
   curl "http://localhost:8000/weather?city=New%20York"
   
   # Or using Swagger UI at /docs (handles encoding automatically)
   ```

3. **Countries with space-separated names:**
   - `United Kingdom` → `London`
   - `United States` → `New York`, `Los Angeles`, etc.
   - `South Africa` → `Johannesburg`, `Cape Town`, etc.

4. **Test with simple city names first:**
   ```bash
   curl "http://localhost:8000/weather?city=London"
   curl "http://localhost:8000/weather?city=Paris"
   curl "http://localhost:8000/weather?city=Tokyo"
   ```

## Solution 3: Verify Network Connectivity

### Problem
API cannot reach OpenWeatherMap servers.

### Solution

1. **Test OpenWeatherMap API directly:**
   ```bash
   curl "https://api.openweathermap.org/data/2.5/weather?q=London&appid=your_key"
   ```

2. **Check your network:**
   ```bash
   # Test internet connectivity
   ping api.openweathermap.org
   
   # Or check DNS resolution
   nslookup api.openweathermap.org
   ```

3. **Check firewall:**
   - Ensure port 443 (HTTPS) is not blocked
   - Check corporate firewall/proxy settings
   - Disable VPN if applicable

## Solution 4: Check if Redis is Running

### Problem
Redis connection issues (won't prevent API from working but logging might show warnings).

### Solution

```bash
# Check if Redis is running
redis-cli ping
# Should output: PONG

# If not running, start it:
# Using Docker (recommended)
docker run -d -p 6379:6379 redis:7-alpine

# Or using Homebrew on macOS
redis-server

# Or using apt on Ubuntu/Debian
sudo systemctl start redis-server
```

## Solution 5: API Response Examples

### Successful Request
```bash
curl "http://localhost:8000/weather?city=London"

# Response (200 OK):
{
  "city": "London",
  "temperature": 10.5,
  "feels_like": 9.2,
  "humidity": 72,
  "pressure": 1013,
  "weather": "Cloudy",
  "wind_speed": 3.5,
  "cloudiness": 85,
  "timestamp": "2024-01-15T10:30:00"
}
```

### Invalid API Key
```bash
# Response (404 error):
{
  "error": "Weather data not found for city: NewYork",
  "code": "HTTP_404"
}
```

**Why:** API key is invalid, so request to OpenWeatherMap fails.

### City Not Found
```bash
# Request with invalid city
curl "http://localhost:8000/weather?city=XYZNowhereCity"

# Response (404 error):
{
  "error": "City 'XYZNowhereCity' not found. Please check the city name and try again. Use format like 'London', 'New York', 'Tokyo', etc.",
  "code": "HTTP_404"
}
```

### Missing City Parameter
```bash
# Request without city parameter
curl "http://localhost:8000/weather"

# Response (422 Unprocessable Entity):
{
  "detail": [
    {
      "type": "missing",
      "loc": ["query", "city"],
      "msg": "Field required"
    }
  ]
}
```

## Debug Workflow

### Step 1: Check Diagnostics
```bash
curl http://localhost:8000/diagnostics
```

### Step 2: Verify Health Check
```bash
curl http://localhost:8000/health
```

### Step 3: Check Logs
```bash
# If using docker-compose
docker-compose logs api

# If running locally, check console output for JSON logs
```

### Step 4: Test with curl
```bash
# Test simple city first
curl "http://localhost:8000/weather?city=London"

# Then test with spaces (URL encoded)
curl "http://localhost:8000/weather?city=New%20York"
```

### Step 5: Use Swagger UI
Visit http://localhost:8000/docs - No need to worry about URL encoding!

## OpenWeatherMap API Limits

### Free Tier
- **Calls per minute:** 60
- **Calls per hour:** 1,000
- **Data retention:** Current weather only
- **Response time:** May vary during peak hours

### Common HTTP Status Codes

| Code | Meaning | Solution |
|------|---------|----------|
| 200 | Success | API working correctly |
| 400 | Bad request | Check city name format |
| 401 | Unauthorized | Check/regenerate API key |
| 403 | Forbidden | Check API plan/quota |
| 404 | Not found | City doesn't exist or API key invalid |
| 429 | Too many requests | Hit rate limit - use caching |
| 500 | Server error | OpenWeatherMap having issues |

## Advanced Debugging

### Enable Debug Mode

Edit `.env`:
```env
DEBUG=true
LOG_LEVEL="DEBUG"
```

Restart application and check logs for detailed information.

### Check OpenWeatherMap Server Status

Visit https://status.openweathermap.org to check for outages.

### Test API Rate Limiting

```bash
# Make multiple rapid requests to see rate limit in action
for i in {1..70}; do
  curl -s "http://localhost:8000/weather?city=London" > /dev/null
  echo "Request $i"
done
```

## Still Having Issues?

1. **Check the logs:**
   ```bash
   # View application logs
   curl http://localhost:8000/diagnostics
   
   # Check Docker logs
   docker-compose logs -f
   ```

2. **Verify OpenWeatherMap API directly:**
   ```bash
   curl "https://api.openweathermap.org/data/2.5/weather?q=London&appid=YOUR_API_KEY"
   ```

3. **Test with Interactive Docs:**
   - Open http://localhost:8000/docs
   - Use the Swagger UI to test endpoints
   - No URL encoding issues!

4. **Check your API key:**
   - Log into https://openweathermap.org
   - Verify API key is active
   - Check API subscription status
   - Generate a new key if needed

5. **Network troubleshooting:**
   - Disable VPN
   - Check firewall settings
   - Check DNS resolution
   - Try a different network

## Performance Tips

- **Use caching:** First request takes longer, subsequent calls within 1 hour use cache
- **Monitor metrics:** Check `/metrics` for request patterns
- **Use health checks:** `/health` endpoint for monitoring
- **Check diagnostics:** `/diagnostics` for quick status

## Support Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [OpenWeatherMap API Docs](https://openweathermap.org/api)
- [OpenWeatherMap FAQ](https://openweathermap.org/faq)
- [Redis Documentation](https://redis.io/docs/)

---

**Last updated:** February 2024
