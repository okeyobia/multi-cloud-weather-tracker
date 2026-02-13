'use client'

import React from 'react'
import { cn } from '@/lib/utils'

export interface CloudBadgeProps {
  provider: 'AWS' | 'Azure'
  isFailover?: boolean
}

/**
 * CloudBadge component displays which cloud provider is active
 * Shows a visual indicator of the current active cloud
 */
export default function CloudBadge({ provider, isFailover = false }: CloudBadgeProps) {
  const isAWS = provider === 'AWS'
  const bgColor = isAWS
    ? 'bg-gradient-to-r from-orange-500 to-orange-600'
    : 'bg-gradient-to-r from-sky-500 to-blue-600'

  const icon = isAWS ? '☁️' : '⛅'
  const providerName = isAWS ? 'AWS' : 'Azure'

  return (
    <div
      className={cn(
        'inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-sm font-semibold text-white',
        bgColor,
        'shadow-md hover:shadow-lg transition-shadow duration-200',
        isFailover && 'ring-2 ring-yellow-400 ring-offset-2'
      )}
      role="status"
      aria-label={`${providerName} cloud provider${isFailover ? ' (failover active)' : ''}`}
    >
      <span>{icon}</span>
      <span>{providerName}</span>
      {isFailover && <span className="text-xs ml-1">⚠️</span>}
    </div>
  )
}
