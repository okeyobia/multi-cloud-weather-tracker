'use client'

import React, { useState, useEffect, useCallback } from 'react'
import { fetchWeather, WeatherResponse } from '@/lib/api'
import SearchBar from '@/components/SearchBar'
import WeatherCard from '@/components/WeatherCard'
import RecentSearches from '@/components/RecentSearches'
import HealthIndicator from '@/components/HealthIndicator'
import { cn } from '@/lib/utils'

const RECENT_SEARCHES_KEY = 'recentWeatherSearches'
const MAX_RECENT_SEARCHES = 10

interface PageState {
  weather: WeatherResponse | null
  isLoading: boolean
  error: string | null
  recentSearches: string[]
}

export default function Home() {
  const [state, setState] = useState<PageState>({
    weather: null,
    isLoading: false,
    error: null,
    recentSearches: [],
  })

  const [isDarkMode, setIsDarkMode] = useState(false)

  // Load recent searches from localStorage
  useEffect(() => {
    try {
      const stored = localStorage.getItem(RECENT_SEARCHES_KEY)
      if (stored) {
        const searches = JSON.parse(stored)
        setState((prev) => ({ ...prev, recentSearches: searches }))
      }
    } catch (error) {
      console.error('Failed to load recent searches:', error)
    }

    // Check for dark mode preference
    const isDark = window.matchMedia('(prefers-color-scheme: dark)').matches
    setIsDarkMode(isDark)

    // Listen for theme changes
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
    const listener = (e: MediaQueryListEvent) => {
      setIsDarkMode(e.matches)
      document.documentElement.classList.toggle('dark', e.matches)
    }
    mediaQuery.addEventListener('change', listener)
    return () => mediaQuery.removeEventListener('change', listener)
  }, [])

  // Save recent searches to localStorage
  const addToRecentSearches = useCallback((city: string) => {
    setState((prev) => {
      const filtered = prev.recentSearches.filter(
        (s) => s.toLowerCase() !== city.toLowerCase()
      )
      const newSearches = [city, ...filtered].slice(0, MAX_RECENT_SEARCHES)

      try {
        localStorage.setItem(RECENT_SEARCHES_KEY, JSON.stringify(newSearches))
      } catch (error) {
        console.error('Failed to save recent searches:', error)
      }

      return { ...prev, recentSearches: newSearches }
    })
  }, [])

  // Fetch weather data
  const handleSearch = useCallback(
    async (city: string) => {
      if (!city.trim()) return

      setState((prev) => ({ ...prev, isLoading: true, error: null }))

      try {
        const data = await fetchWeather(city)
        setState((prev) => ({
          ...prev,
          weather: data,
          isLoading: false,
          error: null,
        }))
        addToRecentSearches(city)
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred'
        setState((prev) => ({
          ...prev,
          weather: null,
          isLoading: false,
          error: errorMessage,
        }))
      }
    },
    [addToRecentSearches]
  )

  // Retry current search
  const handleRetry = useCallback(() => {
    if (state.weather) {
      handleSearch(state.weather.city)
    }
  }, [state.weather, handleSearch])

  // Handle recent search selection
  const handleRecentSearch = useCallback(
    (city: string) => {
      handleSearch(city)
    },
    [handleSearch]
  )

  // Refresh current weather
  const handleRefresh = useCallback(() => {
    if (state.weather) {
      handleSearch(state.weather.city)
    }
  }, [state.weather, handleSearch])

  return (
    <div
      className={cn(
        'w-full min-h-screen transition-colors duration-300',
        'bg-gradient-to-br from-slate-50 via-blue-50 to-sky-50',
        'dark:from-slate-950 dark:via-slate-900 dark:to-slate-950',
        isDarkMode ? 'dark' : ''
      )}
    >
      {/* Decorative background elements */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden">
        <div className="absolute top-0 left-1/4 w-96 h-96 bg-blue-300 dark:bg-blue-900 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-float" />
        <div className="absolute top-1/3 right-1/4 w-96 h-96 bg-purple-300 dark:bg-purple-900 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-float" style={{ animationDelay: '2s' }} />
        <div className="absolute -bottom-1/4 left-1/2 w-96 h-96 bg-cyan-300 dark:bg-cyan-900 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-float" style={{ animationDelay: '4s' }} />
      </div>

      {/* Container */}
      <div className="relative mx-auto max-w-5xl px-4 py-8 lg:py-16">
        {/* Header with gradient */}
        <div className="mb-12 text-center">
          <div className="inline-flex items-center gap-3 mb-6 px-4 py-2 rounded-full bg-white/50 dark:bg-slate-900/50 backdrop-blur-sm border border-white/20 dark:border-slate-700/50">
            <span className="text-2xl">🌐</span>
            <span className="text-sm font-semibold text-gray-700 dark:text-gray-300">Multi-Cloud Infrastructure</span>
          </div>
          
          <h1 className="mb-4 text-5xl lg:text-6xl font-black bg-gradient-to-r from-blue-600 via-sky-600 to-cyan-600 dark:from-blue-400 dark:via-sky-400 dark:to-cyan-400 bg-clip-text text-transparent leading-tight">
            Weather Intelligence
          </h1>
          
          <p className="text-xl text-gray-600 dark:text-gray-400 font-medium mb-2">
            Real-time monitoring across AWS & Azure
          </p>
          <p className="text-sm text-gray-500 dark:text-gray-500">
            Automatic failover • Low-latency responses • Cloud-optimized infrastructure
          </p>
        </div>

        {/* System Health Status */}
        <div className="mb-10">
          <HealthIndicator pollInterval={15000} />
        </div>

        {/* Main Search Section */}
        <div className="space-y-8">
          {/* Search Card */}
          <div className="p-8 rounded-2xl backdrop-blur-lg bg-white/90 dark:bg-slate-900/50 border border-white/30 dark:border-slate-700/50 shadow-soft-lg">
            <SearchBar
              onSearch={handleSearch}
              isLoading={state.isLoading}
              onRefresh={handleRefresh}
            />
          </div>

          {/* Recent Searches */}
          {state.recentSearches.length > 0 && (
            <RecentSearches
              searches={state.recentSearches}
              onSelect={handleRecentSearch}
              isLoading={state.isLoading}
              maxItems={5}
            />
          )}

          {/* Weather Display */}
          <WeatherCard
            weather={state.weather}
            isLoading={state.isLoading}
            error={state.error}
            onRetry={handleRetry}
          />
        </div>

        {/* Features Section */}
        {!state.weather && (
          <div className="mt-16 grid grid-cols-1 md:grid-cols-3 gap-6">
            <FeatureCard
              icon="☁️"
              title="Multi-Cloud Intelligence"
              description="Seamlessly switches between AWS and Azure for optimal performance"
            />
            <FeatureCard
              icon="⚡"
              title="Instant Failover"
              description="Automatic switchover when primary infrastructure fails"
            />
            <FeatureCard
              icon="📊"
              title="Performance Tracking"
              description="Monitor latency and response times across cloud providers"
            />
          </div>
        )}

        {/* Stats Dashboard */}
        {state.weather && (
          <div className="mt-12 p-8 rounded-2xl backdrop-blur-lg bg-gradient-to-br from-white/90 via-blue-50/90 to-sky-50/90 dark:from-slate-900/50 dark:via-slate-800/50 dark:to-slate-900/50 border border-white/30 dark:border-slate-700/50 shadow-soft-lg">
            <h3 className="text-sm font-semibold text-gray-600 dark:text-gray-400 uppercase tracking-wider mb-6">
              📈 Infrastructure Metrics
            </h3>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
              <MetricCard
                label="Total Searches"
                value={state.recentSearches.length}
                icon="🔍"
                color="blue"
              />
              <MetricCard
                label="Active Region"
                value={state.weather.cloudProvider}
                icon="🌎"
                color="sky"
              />
              <MetricCard
                label="Response Time"
                value={`${state.weather.latency || 0}ms`}
                icon="⚡"
                color="cyan"
              />
              <MetricCard
                label="System Status"
                value={state.weather.isFailover ? 'Failover' : 'Healthy'}
                icon={state.weather.isFailover ? '🔄' : '✅'}
                color={state.weather.isFailover ? 'amber' : 'emerald'}
              />
            </div>
          </div>
        )}

        {/* Footer */}
        <div className="mt-16 text-center">
          <p className="text-sm text-gray-500 dark:text-gray-500">
            Built with Next.js • Terraform • Docker • Kubernetes
          </p>
        </div>
      </div>
    </div>
  )
}

/**
 * Feature Card Component
 */
function FeatureCard({
  icon,
  title,
  description,
}: {
  icon: string
  title: string
  description: string
}) {
  return (
    <div
      className={cn(
        'p-8 rounded-2xl transition-all duration-300 group',
        'bg-white/80 dark:bg-slate-900/40',
        'border border-white/40 dark:border-slate-700/40',
        'backdrop-blur-xl shadow-soft-lg',
        'hover:shadow-soft-xl hover:shadow-blue-500/10',
        'hover:scale-105 hover:bg-white/90 dark:hover:bg-slate-900/60'
      )}
    >
      <div className="text-5xl mb-4 transition-transform duration-300 group-hover:scale-110">{icon}</div>
      <h3 className="font-bold text-lg text-gray-900 dark:text-white mb-2">{title}</h3>
      <p className="text-sm text-gray-600 dark:text-gray-400 leading-relaxed">{description}</p>
    </div>
  )
}

/**
 * Metric Card Component
 */
function MetricCard({
  label,
  value,
  icon,
  color,
}: {
  label: string
  value: string | number
  icon: string
  color: 'blue' | 'sky' | 'cyan' | 'emerald' | 'amber'
}) {
  const colorClasses = {
    blue: 'text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/20',
    sky: 'text-sky-600 dark:text-sky-400 bg-sky-50 dark:bg-sky-900/20',
    cyan: 'text-cyan-600 dark:text-cyan-400 bg-cyan-50 dark:bg-cyan-900/20',
    emerald: 'text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-900/20',
    amber: 'text-amber-600 dark:text-amber-400 bg-amber-50 dark:bg-amber-900/20',
  }
  
  return (
    <div className="p-6 rounded-xl bg-white/50 dark:bg-slate-800/50 border border-white/30 dark:border-slate-700/30 backdrop-blur-sm">
      <div className={`text-3xl mb-3 p-3 w-12 h-12 flex items-center justify-center rounded-lg ${colorClasses[color]}`}>
        {icon}
      </div>
      <p className="text-3xl font-bold text-gray-900 dark:text-white mb-1">{value}</p>
      <p className="text-xs font-medium text-gray-600 dark:text-gray-400 uppercase tracking-wider">{label}</p>
    </div>
  )
}
