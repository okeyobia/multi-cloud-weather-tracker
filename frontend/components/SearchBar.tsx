'use client'

import React, { useState, useEffect, useCallback, useRef } from 'react'
import { debounce, cn, isValidCity } from '@/lib/utils'

export interface SearchBarProps {
  onSearch: (city: string) => void
  isLoading?: boolean
  onRefresh?: () => void
}

/**
 * SearchBar component with debounced input
 * Handles city search with optimal UX
 */
export default function SearchBar({ onSearch, isLoading = false, onRefresh }: SearchBarProps) {
  const [input, setInput] = useState('')
  const [isFocused, setIsFocused] = useState(false)
  const searchInputRef = useRef<HTMLInputElement>(null)

  // Debounced search function
  const debouncedSearch = useCallback(
    debounce((city: unknown) => {
      const cityStr = city as string
      if (isValidCity(cityStr)) {
        onSearch(cityStr)
      }
    }, 500),
    [onSearch]
  )

  // Handle input change with debounce
  useEffect(() => {
    debouncedSearch(input)
  }, [input, debouncedSearch])

  const handleClear = () => {
    setInput('')
    searchInputRef.current?.focus()
  }

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' && isValidCity(input)) {
      onSearch(input)
    }
  }

  return (
    <div className="w-full">
      <div
        className={cn(
          'relative flex items-center gap-3 px-5 py-4 rounded-xl',
          'bg-white/90 dark:bg-slate-900/60 border-2 transition-all duration-200',
          'backdrop-blur-lg shadow-soft-md',
          isFocused
            ? 'border-blue-500 shadow-soft-lg shadow-blue-500/30'
            : 'border-white/40 dark:border-slate-700/40 hover:border-blue-200/60 dark:hover:border-slate-600/60'
        )}
      >
        {/* Search Icon */}
        <span className="text-xl flex-shrink-0">🔍</span>

        {/* Input Field */}
        <input
          ref={searchInputRef}
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onFocus={() => setIsFocused(true)}
          onBlur={() => setIsFocused(false)}
          onKeyDown={handleKeyDown}
          placeholder="Search for a city..."
          disabled={isLoading}
          className={cn(
            'flex-1 bg-transparent text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500',
            'outline-none text-base font-medium',
            'disabled:opacity-60 disabled:cursor-not-allowed'
          )}
          aria-label="Search for weather by city name"
        />

        {/* Clear Button */}
        {input && (
          <button
            onClick={handleClear}
            className={cn(
              'p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-800',
              'transition-all duration-200 text-gray-400 hover:text-gray-700 dark:hover:text-gray-200',
              'disabled:opacity-50 flex-shrink-0'
            )}
            aria-label="Clear search input"
            disabled={isLoading}
          >
            ✕
          </button>
        )}

        {/* Refresh Button */}
        {onRefresh && (
          <button
            onClick={onRefresh}
            disabled={isLoading}
            className={cn(
              'p-2 rounded-lg hover:bg-blue-50 dark:hover:bg-slate-800 transition-all duration-200',
              'text-gray-400 hover:text-blue-600 dark:hover:text-blue-400',
              'disabled:opacity-50 flex-shrink-0 font-semibold',
              isLoading && 'animate-spin'
            )}
            aria-label="Refresh weather data"
          >
            🔄
          </button>
        )}

        {/* Loading Indicator */}
        {isLoading && (
          <div className="absolute right-16 w-5 h-5 flex-shrink-0">
            <div className="animate-spin rounded-full border-2 border-gray-300 dark:border-slate-700 border-t-blue-500 w-full h-full" />
          </div>
        )}
      </div>

      {/* Help Text */}
      <p className="text-xs text-gray-500 dark:text-gray-500 mt-3 px-2 font-medium">
        💡 Start typing a city name to search (e.g., London, Tokyo, New York)
      </p>
    </div>
  )
}
