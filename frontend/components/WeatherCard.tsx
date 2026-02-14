import React from 'react'
import CloudBadge from './CloudBadge'
import { WeatherResponse, getWeatherIcon, formatTemperature, formatDate } from '@/lib/api'
import { cn } from '@/lib/utils'

export interface WeatherCardProps {
  weather: WeatherResponse | null
  isLoading?: boolean
  error?: string | null
  onRetry?: () => void
}

/**
 * Metric Badge Component - REMOVED: Not used in final version
 */

/**
 * Skeleton Loader Component
 */
function SkeletonLoader() {
  return (
    <div className="space-y-4">
      <div className="h-12 bg-gradient-to-r from-gray-200 to-gray-100 dark:from-slate-700 dark:to-slate-600 rounded-xl animate-pulse" />
      <div className="h-40 bg-gradient-to-r from-gray-200 to-gray-100 dark:from-slate-700 dark:to-slate-600 rounded-2xl animate-pulse" />
      <div className="grid grid-cols-2 gap-4">
        <div className="h-24 bg-gradient-to-r from-gray-200 to-gray-100 dark:from-slate-700 dark:to-slate-600 rounded-xl animate-pulse" />
        <div className="h-24 bg-gradient-to-r from-gray-200 to-gray-100 dark:from-slate-700 dark:to-slate-600 rounded-xl animate-pulse" />
      </div>
    </div>
  )
}

/**
 * WeatherCard component displays weather information
 * Shows temperature, description, and cloud provider source
 */
export default function WeatherCard({
  weather,
  isLoading = false,
  error = null,
  onRetry,
}: WeatherCardProps) {
  if (isLoading) {
    return (
      <div className="mt-8 p-8 rounded-2xl bg-white/90 dark:bg-slate-900/40 backdrop-blur-lg border border-white/30 dark:border-slate-700/30 shadow-soft-lg">
        <SkeletonLoader />
      </div>
    )
  }

  if (error) {
    return (
      <div className="mt-8 p-8 rounded-2xl bg-gradient-to-br from-red-50/90 to-rose-50/90 dark:from-red-900/20 dark:to-rose-900/20 border border-red-200/50 dark:border-red-800/50 backdrop-blur-lg shadow-soft-lg hover:shadow-soft-xl">
        <div className="flex items-start gap-4">
          <span className="text-5xl flex-shrink-0">⚠️</span>
          <div className="flex-1">
            <h3 className="text-lg font-bold text-red-700 dark:text-red-300 mb-2">
              Unable to Fetch Weather
            </h3>
            <p className="text-red-600 dark:text-red-400 text-sm mb-4 leading-relaxed">{error}</p>
            {onRetry && (
              <button
                onClick={onRetry}
                className={cn(
                  'px-5 py-2.5 bg-gradient-to-r from-red-600 to-rose-600 hover:from-red-700 hover:to-rose-700',
                  'text-white rounded-lg font-semibold transition-all duration-200',
                  'shadow-soft-md hover:shadow-soft-lg active:scale-95'
                )}
              >
                Try Again
              </button>
            )}
          </div>
        </div>
      </div>
    )
  }

  if (!weather) {
    return (
      <div className="mt-8 p-12 rounded-2xl bg-gradient-to-br from-blue-50/90 to-sky-50/90 dark:from-slate-900/40 dark:to-blue-900/20 border border-blue-200/50 dark:border-blue-800/30 backdrop-blur-lg shadow-soft-lg text-center">
        <span className="text-6xl mb-4 block">🌍</span>
        <p className="text-lg text-gray-600 dark:text-gray-300 font-semibold">
          Search for a city to see weather data
        </p>
        <p className="text-sm text-gray-500 dark:text-gray-400 mt-2">
          Try searching for London, Tokyo, or New York
        </p>
      </div>
    )
  }

  const weatherIcon = getWeatherIcon(weather.description)
  const tempFormatted = formatTemperature(weather.temperature)
  const timeFormatted = formatDate(weather.lastUpdated)

  return (
    <div
      className={cn(
        'mt-8 rounded-2xl overflow-hidden transition-all duration-300 group',
        'bg-gradient-to-br from-white/90 via-blue-50/50 to-sky-50/50',
        'dark:from-slate-900/50 dark:via-slate-800/50 dark:to-slate-900/50',
        'border border-white/40 dark:border-slate-700/40',
        'backdrop-blur-lg shadow-soft-lg hover:shadow-soft-xl',
        'hover:shadow-blue-500/15 hover:border-blue-200/60'
      )}
    >
      {/* Failover Banner */}
      {weather.isFailover && (
        <div className="bg-gradient-to-r from-amber-400 via-orange-400 to-red-400 dark:from-amber-600 dark:via-orange-600 dark:to-red-600 px-6 py-3 text-sm font-bold text-white flex items-center gap-2 shadow-soft-md">
          <span>⚠️</span>
          <span>Failover Active: Secondary Cloud Region</span>
        </div>
      )}

      {/* Main Content */}
      <div className="p-8 lg:p-10">
        {/* Header Section */}
        <div className="flex items-start justify-between mb-10">
          <div>
            <h2 className="text-5xl lg:text-6xl font-bold bg-gradient-to-r from-gray-900 via-blue-900 to-sky-900 dark:from-white dark:via-blue-200 dark:to-sky-200 bg-clip-text text-transparent mb-3">
              {weather.city}
            </h2>
            <p className="text-sm text-gray-500 dark:text-gray-400 font-medium">
              📍 Last updated: {timeFormatted}
            </p>
          </div>
          <CloudBadge provider={weather.cloudProvider} isFailover={weather.isFailover} />
        </div>

        {/* Weather Info Section */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-10 mb-10">
          {/* Temperature Display */}
          <div className="flex items-center gap-8">
            <div className="text-8xl animate-float">{weatherIcon}</div>
            <div>
              <p className="text-7xl lg:text-8xl font-black bg-gradient-to-br from-blue-600 via-sky-600 to-cyan-600 dark:from-blue-300 dark:via-sky-300 dark:to-cyan-300 bg-clip-text text-transparent leading-none">
                {tempFormatted}
              </p>
              <p className="text-lg text-gray-600 dark:text-gray-300 mt-4 capitalize font-semibold">
                {weather.description}
              </p>
            </div>
          </div>

          {/* Metadata Cards */}
          <div className="space-y-4">
            {/* Cloud Provider Card */}
            <div className="p-5 rounded-xl bg-gradient-to-br from-blue-50/80 to-sky-50/80 dark:from-slate-800/60 dark:to-slate-700/60 border border-blue-200/40 dark:border-slate-600/40 backdrop-blur-sm hover:shadow-soft-md transition-all duration-300">
              <p className="text-xs font-bold text-gray-600 dark:text-gray-400 uppercase tracking-widest mb-2">
                ☁️ Cloud Provider
              </p>
              <p className="text-xl font-bold text-gray-900 dark:text-white flex items-center gap-2">
                {weather.cloudProvider === 'AWS' ? '🟠' : '🔷'} {weather.cloudProvider} Cloud
              </p>
            </div>

            {/* Response Latency Card */}
            {weather.latency && (
              <div className="p-5 rounded-xl bg-gradient-to-br from-emerald-50/80 to-teal-50/80 dark:from-slate-800/60 dark:to-slate-700/60 border border-emerald-200/40 dark:border-slate-600/40 backdrop-blur-sm hover:shadow-soft-md transition-all duration-300">
                <p className="text-xs font-bold text-gray-600 dark:text-gray-400 uppercase tracking-widest mb-2">
                  ⚡ Response Time
                </p>
                <p className="text-xl font-bold text-gray-900 dark:text-white flex items-center gap-2">
                  {weather.latency < 100 ? '🚀' : weather.latency < 300 ? '✅' : '⚠️'} {weather.latency}ms
                </p>
              </div>
            )}
          </div>
        </div>

        {/* Footer Info */}
        <div className="mt-6 flex items-center justify-between text-xs text-gray-500 dark:text-gray-400">
          <span className="font-medium">🌐 Multi-Cloud Weather Tracking</span>
          <span>AWS · Azure · Automatic Failover</span>
        </div>
      </div>
    </div>
  )
}
