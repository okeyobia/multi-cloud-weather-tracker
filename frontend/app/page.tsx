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
        'w-full transition-colors duration-300',
        isDarkMode ? 'dark' : ''
      )}
    >
      {/* Container */}
      <div className="mx-auto max-w-4xl px-4 py-8 lg:py-12">
        {/* Header */}
        <div className="mb-4 text-center">
          <div className="flex items-center justify-center gap-2 mb-4">
            <span className="text-4xl lg:text-5xl font-black bg-gradient-to-r from-blue-600 via-sky-600 to-cyan-600 dark:from-blue-400 dark:via-sky-400 dark:to-cyan-400 bg-clip-text text-transparent">
              🌍 Weather
            </span>
            <span className="text-4xl lg:text-5xl font-black bg-gradient-to-r from-orange-500 via-red-500 to-pink-500 dark:from-orange-400 dark:via-red-400 dark:to-pink-400 bg-clip-text text-transparent">
              Tracker
            </span>
          </div>
          <p className="text-lg text-gray-600 dark:text-gray-400 font-medium">
            Multi-Cloud Powered Weather Intelligence
          </p>
          <p className="text-sm text-gray-500 dark:text-gray-500 mt-2">
            Featuring automatic failover between AWS and Azure infrastructure
          </p>
        </div>

        {/* System Health Status */}
        <div className="mb-8">
          <HealthIndicator pollInterval={15000} />
        </div>

        {/* Main Search Section */}
        <div className="space-y-6">
          {/* Search Input */}
          <SearchBar
            onSearch={handleSearch}
            isLoading={state.isLoading}
            onRefresh={handleRefresh}
          />

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
          <div className="mt-12 grid grid-cols-1 md:grid-cols-3 gap-6">
            <FeatureCard
              icon="☁️"
              title="Multi-Cloud"
              description="Seamlessly switches between AWS and Azure"
            />
            <FeatureCard
              icon="🚀"
              title="Instant Failover"
              description="Automatic switchover when primary fails"
            />
            <FeatureCard
              icon="💾"
              title="Local History"
              description="Stores your recent searches"
            />
          </div>
        )}

        {/* Stats */}
        {state.weather && (
          <div className="mt-8 p-6 rounded-2xl bg-gradient-to-r from-blue-50 to-sky-50 dark:from-slate-800 dark:to-slate-700 border border-blue-200 dark:border-slate-600">
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
              <div>
                <p className="text-2xl font-bold text-blue-600 dark:text-blue-400">
                  {state.recentSearches.length}
                </p>
                <p className="text-xs text-gray-600 dark:text-gray-400 mt-1">Searches</p>
              </div>
              <div>
                <p className="text-2xl font-bold text-sky-600 dark:text-sky-400">
                  {state.weather.cloudProvider}
                </p>
                <p className="text-xs text-gray-600 dark:text-gray-400 mt-1">Active Region</p>
              </div>
              <div>
                <p className="text-2xl font-bold text-cyan-600 dark:text-cyan-400">
                  {state.weather.latency || 0}ms
                </p>
                <p className="text-xs text-gray-600 dark:text-gray-400 mt-1">Response Time</p>
              </div>
              <div>
                <p className="text-2xl font-bold text-emerald-600 dark:text-emerald-400">
                  {state.weather.isFailover ? '🔄' : '✅'}
                </p>
                <p className="text-xs text-gray-600 dark:text-gray-400 mt-1">Status</p>
              </div>
            </div>
          </div>
        )}
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
        'p-6 rounded-2xl text-center transition-all duration-300',
        'bg-gradient-to-br from-white to-gray-50',
        'dark:from-slate-800 dark:to-slate-700',
        'border border-gray-200 dark:border-slate-600',
        'hover:shadow-lg hover:shadow-blue-500/10',
        'hover:scale-105'
      )}
    >
      <div className="text-4xl mb-3">{icon}</div>
      <h3 className="font-semibold text-gray-900 dark:text-white mb-1">{title}</h3>
      <p className="text-sm text-gray-600 dark:text-gray-400">{description}</p>
    </div>
  )
}
