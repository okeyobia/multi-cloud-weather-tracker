'use client'

import React, { useState, useEffect } from 'react'
import { fetchHealthStatus, HealthStatus } from '@/lib/api'
import { cn } from '@/lib/utils'

export interface HealthIndicatorProps {
  pollInterval?: number // milliseconds
}

type HealthState = HealthStatus | null
type HealthStatus_Visual = 'healthy' | 'degraded' | 'down'

/**
 * HealthIndicator component displays system health
 * Polls /health endpoint every 15 seconds by default
 */
export default function HealthIndicator({ pollInterval = 15000 }: HealthIndicatorProps) {
  const [health, setHealth] = useState<HealthState>(null)
  const [isChecking, setIsChecking] = useState(false)

  useEffect(() => {
    const checkHealth = async () => {
      setIsChecking(true)
      try {
        const data = await fetchHealthStatus()
        setHealth(data)
      } catch (error) {
        setHealth({
          status: 'down',
          message: 'Unable to connect to backend',
          primaryRegion: 'unknown',
          activeRegion: 'unknown',
          lastChecked: new Date().toISOString(),
        })
      } finally {
        setIsChecking(false)
      }
    }

    // Initial check
    checkHealth()

    // Set up polling
    const interval = setInterval(checkHealth, pollInterval)

    return () => clearInterval(interval)
  }, [pollInterval])

  if (!health) {
    return null
  }

  const statusColor = {
    healthy: { 
      bg: 'bg-gradient-to-r from-emerald-500 to-teal-600', 
      darkBg: 'dark:from-emerald-600 dark:to-teal-700',
      dot: '🟢', 
      bgLight: 'from-emerald-50/90 to-teal-50/90 dark:from-emerald-900/20 dark:to-teal-900/20',
      border: 'border-emerald-200/50 dark:border-emerald-800/50'
    },
    degraded: { 
      bg: 'bg-gradient-to-r from-amber-500 to-orange-600', 
      darkBg: 'dark:from-amber-600 dark:to-orange-700',
      dot: '🟡', 
      bgLight: 'from-amber-50/90 to-orange-50/90 dark:from-amber-900/20 dark:to-orange-900/20',
      border: 'border-amber-200/50 dark:border-amber-800/50'
    },
    down: { 
      bg: 'bg-gradient-to-r from-red-500 to-rose-600', 
      darkBg: 'dark:from-red-600 dark:to-rose-700',
      dot: '🔴', 
      bgLight: 'from-red-50/90 to-rose-50/90 dark:from-red-900/20 dark:to-rose-900/20',
      border: 'border-red-200/50 dark:border-red-800/50'
    },
  }

  const current = statusColor[health.status as HealthStatus_Visual] || statusColor.down

  return (
    <div className="space-y-4">
      {/* Health Banner */}
      <div
        className={cn(
          'rounded-xl p-5 border transition-all duration-300 backdrop-blur-lg',
          `${current.bg} ${current.darkBg}`,
          'text-white shadow-soft-lg hover:shadow-soft-xl'
        )}
        role="status"
        aria-label={`System status: ${health.status}`}
      >
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <span className="text-2xl animate-pulse">{current.dot}</span>
            <div>
              <p className="font-bold text-lg capitalize">{health.status}</p>
              <p className="text-sm text-white/90">{health.message}</p>
            </div>
          </div>
          <div className="text-right text-sm">
            <p className="font-semibold text-white/95 flex items-center gap-1">
              🌍 {health.activeRegion}
            </p>
            {isChecking && (
              <p className="text-xs text-white/75 animate-pulse mt-1">verifying...</p>
            )}
          </div>
        </div>
      </div>

      {/* Failover Warning */}
      {health.status === 'degraded' && (
        <div className={cn(
          'p-5 rounded-xl border-2 backdrop-blur-lg transition-all duration-300',
          'bg-gradient-to-br from-amber-50/90 to-orange-50/90',
          'dark:from-amber-900/20 dark:to-orange-900/20',
          'border-amber-300 dark:border-amber-700/50',
          'shadow-soft-md'
        )}>
          <div className="flex items-start gap-3">
            <span className="text-2xl flex-shrink-0">⚠️</span>
            <div>
              <h4 className="font-bold text-amber-900 dark:text-amber-100">
                Failover in Progress
              </h4>
              <p className="text-sm text-amber-800 dark:text-amber-200 mt-1">
                The system is operating in a degraded state. Requests are being routed to backup infrastructure.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Service Down Alert */}
      {health.status === 'down' && (
        <div className={cn(
          'p-5 rounded-xl border-2 backdrop-blur-lg transition-all duration-300',
          'bg-gradient-to-br from-red-50/90 to-rose-50/90',
          'dark:from-red-900/20 dark:to-rose-900/20',
          'border-red-300 dark:border-red-700/50',
          'shadow-soft-md'
        )}>
          <div className="flex items-start gap-3">
            <span className="text-2xl flex-shrink-0">🚨</span>
            <div>
              <h4 className="font-bold text-red-900 dark:text-red-100">
                Service Unavailable
              </h4>
              <p className="text-sm text-red-800 dark:text-red-200 mt-1">
                The backend service is currently unavailable. Please try again in a few moments.
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
