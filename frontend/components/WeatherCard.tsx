'use client'

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
 * Skeleton Loader Component
 */
function SkeletonLoader() {
  return (
    <div className="space-y-4">
      <div className="h-12 bg-gray-200 dark:bg-slate-700 rounded-lg animate-pulse" />
      <div className="h-32 bg-gray-200 dark:bg-slate-700 rounded-2xl animate-pulse" />
      <div className="h-20 bg-gray-200 dark:bg-slate-700 rounded-lg animate-pulse" />
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
      <div className="mt-8 p-6 rounded-3xl bg-white dark:bg-slate-800 shadow-xl">
        <SkeletonLoader />
      </div>
    )
  }

  if (error) {
    return (
      <div className="mt-8 p-6 rounded-3xl bg-gradient-to-br from-red-50 to-rose-50 dark:from-red-900/20 dark:to-rose-900/20 border-2 border-red-200 dark:border-red-800 shadow-xl">
        <div className="flex items-start gap-4">
          <span className="text-4xl">⚠️</span>
          <div className="flex-1">
            <h3 className="text-lg font-semibold text-red-700 dark:text-red-300 mb-2">
              Unable to Fetch Weather
            </h3>
            <p className="text-red-600 dark:text-red-400 text-sm mb-4">{error}</p>
            {onRetry && (
              <button
                onClick={onRetry}
                className={cn(
                  'px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg',
                  'font-medium transition-colors duration-200',
                  'active:scale-95'
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
      <div className="mt-8 p-8 rounded-3xl bg-gradient-to-br from-blue-50 to-sky-50 dark:from-slate-800 dark:to-blue-900/20 border-2 border-blue-200 dark:border-blue-800/30 shadow-xl text-center">
        <span className="text-5xl mb-4 block">🌍</span>
        <p className="text-gray-600 dark:text-gray-300 font-medium">
          Search for a city to see weather data
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
        'mt-8 rounded-3xl shadow-2xl overflow-hidden transition-all duration-300',
        'bg-gradient-to-br from-white to-gray-50',
        'dark:from-slate-800 dark:to-slate-900',
        'border border-gray-200 dark:border-slate-700',
        'hover:shadow-2xl hover:shadow-blue-500/10'
      )}
    >
      {/* Failover Banner */}
      {weather.isFailover && (
        <div className="bg-gradient-to-r from-yellow-400 to-orange-400 px-6 py-3 text-sm font-semibold text-gray-900 flex items-center gap-2">
          <span>⚠️</span>
          <span>Failover Active: Secondary Cloud Region</span>
        </div>
      )}

      {/* Main Content */}
      <div className="p-8 lg:p-10">
        {/* Header Section */}
        <div className="flex items-start justify-between mb-8">
          <div>
            <h2 className="text-4xl lg:text-5xl font-bold text-gray-900 dark:text-white mb-2">
              {weather.city}
            </h2>
            <p className="text-sm text-gray-500 dark:text-gray-400">
              Last updated: {timeFormatted}
            </p>
          </div>
          <CloudBadge provider={weather.cloudProvider} isFailover={weather.isFailover} />
        </div>

        {/* Weather Info Section */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mb-8">
          {/* Temperature */}
          <div className="flex items-center gap-6">
            <div className="text-7xl">{weatherIcon}</div>
            <div>
              <p className="text-6xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-blue-600 to-sky-600">
                {tempFormatted}
              </p>
              <p className="text-lg text-gray-600 dark:text-gray-400 mt-2 capitalize">
                {weather.description}
              </p>
            </div>
          </div>

          {/* Metadata */}
          <div className="space-y-4">
            <div className="p-4 rounded-xl bg-gradient-to-r from-blue-50 to-sky-50 dark:from-slate-800 dark:to-slate-700 border border-blue-200 dark:border-slate-600">
              <p className="text-xs font-semibold text-gray-600 dark:text-gray-400 uppercase tracking-wide mb-1">
                Source
              </p>
              <p className="text-lg font-semibold text-gray-900 dark:text-white flex items-center gap-2">
                {weather.cloudProvider === 'AWS' ? '☁️' : '⛅'} {weather.cloudProvider} Cloud
              </p>
            </div>

            {weather.latency && (
              <div className="p-4 rounded-xl bg-gradient-to-r from-emerald-50 to-teal-50 dark:from-slate-800 dark:to-slate-700 border border-emerald-200 dark:border-slate-600">
                <p className="text-xs font-semibold text-gray-600 dark:text-gray-400 uppercase tracking-wide mb-1">
                  Response Time
                </p>
                <p className="text-lg font-semibold text-gray-900 dark:text-white flex items-center gap-2">
                  ⚡ {weather.latency}ms
                </p>
              </div>
            )}
          </div>
        </div>

        {/* Footer Info */}
        <div className="pt-6 border-t border-gray-200 dark:border-slate-700 flex items-center justify-between text-sm text-gray-500 dark:text-gray-400">
          <span>Multi-Cloud Weather Tracking</span>
          <span>💼 Powered by AWS & Azure</span>
        </div>
      </div>
    </div>
  )
}
