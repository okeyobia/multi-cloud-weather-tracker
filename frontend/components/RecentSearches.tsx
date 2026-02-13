'use client'

import React from 'react'
import { cn } from '@/lib/utils'

export interface RecentSearchesProps {
  searches: string[]
  onSelect: (city: string) => void
  isLoading?: boolean
  maxItems?: number
}

/**
 * RecentSearches component displays recent city searches
 * Allows quick access to previously searched locations
 */
export default function RecentSearches({
  searches,
  onSelect,
  isLoading = false,
  maxItems = 5,
}: RecentSearchesProps) {
  if (searches.length === 0) {
    return null
  }

  const displayedSearches = searches.slice(0, maxItems)

  return (
    <div className="mt-6 space-y-2">
      <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300 px-2">
        Recent Searches
      </h3>

      <div className="flex flex-wrap gap-2">
        {displayedSearches.map((city, index) => (
          <button
            key={`${city}-${index}`}
            onClick={() => onSelect(city)}
            disabled={isLoading}
            className={cn(
              'px-3 py-2 rounded-lg text-sm font-medium',
              'bg-gradient-to-r from-blue-50 to-sky-50',
              'dark:from-slate-700 dark:to-slate-800',
              'border border-blue-200 dark:border-slate-600',
              'text-blue-700 dark:text-blue-300',
              'hover:from-blue-100 hover:to-sky-100',
              'dark:hover:from-slate-600 dark:hover:to-slate-700',
              'transition-all duration-200',
              'hover:shadow-md hover:shadow-blue-200 dark:hover:shadow-slate-900/50',
              'disabled:opacity-50 disabled:cursor-not-allowed',
              'active:scale-95'
            )}
            aria-label={`Search for ${city}`}
          >
            <span className="mr-1">📍</span>
            {city}
          </button>
        ))}
      </div>

      <p className="text-xs text-gray-500 dark:text-gray-400 px-2 mt-2">
        {searches.length} searches stored locally
      </p>
    </div>
  )
}
