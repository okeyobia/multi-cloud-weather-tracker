/**
 * Utility functions
 */

export function cn(...classes: (string | undefined | false)[]): string {
  return classes.filter(Boolean).join(' ')
}

/**
 * Debounce function for search input
 */
export function debounce<T extends (...args: unknown[]) => unknown>(
  func: T,
  delay: number
): (...args: Parameters<T>) => void {
  let timeoutId: NodeJS.Timeout

  return function debounced(...args: Parameters<T>) {
    clearTimeout(timeoutId)
    timeoutId = setTimeout(() => func(...args), delay)
  }
}

/**
 * Check if running in dark mode
 */
export function isDarkMode(): boolean {
  if (typeof window === 'undefined') return false
  return window.matchMedia('(prefers-color-scheme: dark)').matches
}

/**
 * Get contrasting text color based on background
 */
export function getContrastingText(background: string): string {
  if (background.includes('blue') || background.includes('dark')) {
    return 'text-white'
  }
  return 'text-gray-900'
}

/**
 * Validate city name
 */
export function isValidCity(city: string): boolean {
  return city.trim().length > 0 && city.trim().length <= 100
}
