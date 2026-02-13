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
    debounce((city: string) => {
      if (isValidCity(city)) {
        onSearch(city)
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
          'relative flex items-center gap-2 px-4 py-3 rounded-2xl',
          'bg-white dark:bg-slate-800 border-2 transition-all duration-200',
          isFocused
            ? 'border-blue-500 shadow-lg shadow-blue-500/20'
            : 'border-gray-200 dark:border-slate-700 shadow-md',
          'backdrop-blur-sm'
        )}
      >
        {/* Search Icon */}
        <span className="text-gray-400 dark:text-gray-500 text-xl">🔍</span>

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
            'flex-1 bg-transparent text-gray-900 dark:text-white placeholder-gray-400',
            'outline-none text-base',
            'disabled:opacity-60'
          )}
          aria-label="Search for weather by city name"
        />

        {/* Clear Button */}
        {input && (
          <button
            onClick={handleClear}
            className={cn(
              'p-1 rounded-full hover:bg-gray-100 dark:hover:bg-slate-700',
              'transition-colors duration-200 text-gray-500 hover:text-gray-900',
              'dark:hover:text-gray-200'
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
              'p-2 rounded-lg hover:bg-blue-50 dark:hover:bg-slate-700',
              'transition-all duration-200 text-gray-500 hover:text-blue-600',
              'dark:hover:text-blue-400 disabled:opacity-50',
              isLoading && 'animate-spin'
            )}
            aria-label="Refresh weather data"
          >
            🔄
          </button>
        )}

        {/* Loading Indicator */}
        {isLoading && (
          <div className="absolute right-12 w-4 h-4">
            <div className="animate-spin rounded-full border-2 border-gray-300 border-t-blue-500" />
          </div>
        )}
      </div>

      {/* Help Text */}
      <p className="text-xs text-gray-500 dark:text-gray-400 mt-2 px-2">
        Start typing a city name to search
      </p>
    </div>
  )
}
