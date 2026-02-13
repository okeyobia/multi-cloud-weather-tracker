/**
 * Weather Tracker API Client
 * Handles all communication with the backend weather service
 */

export interface WeatherResponse {
  city: string
  temperature: number
  description: string
  cloudProvider: 'AWS' | 'Azure'
  isFailover: boolean
  lastUpdated: string
  weatherIcon?: string
  latency?: number
}

export interface HealthStatus {
  status: 'healthy' | 'degraded' | 'down'
  message: string
  primaryRegion: string
  activeRegion: string
  lastChecked: string
}

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8000'

/**
 * Fetch weather data for a specific city
 * @param city - City name to fetch weather for
 * @param timeout - Request timeout in milliseconds (default 10s)
 * @returns Weather data response
 */
export async function fetchWeather(
  city: string,
  timeout = 10000
): Promise<WeatherResponse> {
  const controller = new AbortController()
  const timeoutId = setTimeout(() => controller.abort(), timeout)

  try {
    const startTime = performance.now()

    const response = await fetch(`${API_BASE_URL}/weather?city=${encodeURIComponent(city)}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      signal: controller.signal,
      cache: 'no-store',
    })

    const endTime = performance.now()
    const latency = Math.round(endTime - startTime)

    if (!response.ok) {
      if (response.status === 404) {
        throw new Error(`City not found: ${city}`)
      }
      if (response.status === 503) {
        throw new Error('Backend service temporarily unavailable. Attempting failover...')
      }
      throw new Error(`API error: ${response.status} ${response.statusText}`)
    }

    const data: WeatherResponse = await response.json()
    return {
      ...data,
      latency,
    }
  } catch (error) {
    if (error instanceof Error) {
      if (error.name === 'AbortError') {
        throw new Error(`Request timeout after ${timeout}ms`)
      }
      throw error
    }
    throw new Error('Unknown error occurred')
  } finally {
    clearTimeout(timeoutId)
  }
}

/**
 * Check backend health status
 * @returns Health status information
 */
export async function fetchHealthStatus(): Promise<HealthStatus> {
  try {
    const response = await fetch(`${API_BASE_URL}/health`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
      cache: 'no-store',
    })

    if (!response.ok) {
      return {
        status: 'down',
        message: 'Backend service is down',
        primaryRegion: 'us-east-1',
        activeRegion: 'unknown',
        lastChecked: new Date().toISOString(),
      }
    }

    const data = await response.json()
    return {
      status: data.status || 'healthy',
      message: data.message || 'All systems operational',
      primaryRegion: data.primaryRegion || 'us-east-1',
      activeRegion: data.activeRegion || 'unknown',
      lastChecked: new Date().toISOString(),
    }
  } catch (error) {
    return {
      status: 'down',
      message: 'Could not reach backend service',
      primaryRegion: 'us-east-1',
      activeRegion: 'unknown',
      lastChecked: new Date().toISOString(),
    }
  }
}

/**
 * Get weather icon emoji based on weather description
 */
export function getWeatherIcon(description: string): string {
  const desc = description.toLowerCase()

  if (desc.includes('sunny') || desc.includes('clear')) return '☀️'
  if (desc.includes('cloudy') || desc.includes('overcast')) return '☁️'
  if (desc.includes('rain') || desc.includes('wet')) return '🌧️'
  if (desc.includes('thunder') || desc.includes('storm')) return '⛈️'
  if (desc.includes('snow')) return '❄️'
  if (desc.includes('wind')) return '💨'
  if (desc.includes('fog') || desc.includes('mist')) return '🌫️'
  if (desc.includes('hail')) return '🧊'
  if (desc.includes('night') || desc.includes('moon')) return '🌙'

  return '🌡️'
}

/**
 * Format temperature with unit
 */
export function formatTemperature(temp: number, unit: 'C' | 'F' = 'C'): string {
  return `${Math.round(temp)}°${unit}`
}

/**
 * Format date to readable string
 */
export function formatDate(dateString: string): string {
  const date = new Date(dateString)
  return date.toLocaleTimeString('en-US', {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  })
}
