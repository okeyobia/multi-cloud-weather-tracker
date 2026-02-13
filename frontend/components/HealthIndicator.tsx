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
    healthy: { bg: 'bg-gradient-to-r from-green-500 to-emerald-600', dot: '🟢' },
    degraded: { bg: 'bg-gradient-to-r from-yellow-500 to-orange-600', dot: '🟡' },
    down: { bg: 'bg-gradient-to-r from-red-500 to-rose-600', dot: '🔴' },
  }

  const current = statusColor[health.status as HealthStatus_Visual] || statusColor.down

  return (
    <div>
      {/* Health Banner */}
      <div
        className={cn(
          'rounded-2xl p-4 mb-8 border border-opacity-20 transition-all duration-300',
          current.bg,
          'bg-opacity-10 border-current text-white shadow-lg'
        )}
        role="status"
        aria-label={`System status: ${health.status}`}
      >
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <span className="text-xl">{current.dot}</span>
            <div>
              <p className="font-semibold capitalize">{health.status}</p>
              <p className="text-xs text-gray-300">{health.message}</p>
            </div>
          </div>
          <div className="text-right">
            <p className="text-xs font-mono text-gray-300">{health.activeRegion}</p>
            {isChecking && <span className="text-xs animate-pulse">checking...</span>}
          </div>
        </div>
      </div>

      {/* Failover Warning */}
      {health.status === 'degraded' && (
        <div className="mb-6 p-4 rounded-xl bg-yellow-50 dark:bg-yellow-900/20 border-2 border-yellow-400 dark:border-yellow-600">
          <div className="flex items-start gap-3">
            <span className="text-2xl">⚠️</span>
            <div>
              <h4 className="font-semibold text-yellow-900 dark:text-yellow-100">
                Failover in Progress
              </h4>
              <p className="text-sm text-yellow-800 dark:text-yellow-200 mt-1">
                The system is operating in a degraded state. Requests are being routed to backup
                infrastructure.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Down Warning */}
      {health.status === 'down' && (
        <div className="mb-6 p-4 rounded-xl bg-red-50 dark:bg-red-900/20 border-2 border-red-400 dark:border-red-600">
          <div className="flex items-start gap-3">
            <span className="text-2xl">🔴</span>
            <div>
              <h4 className="font-semibold text-red-900 dark:text-red-100">Service Unavailable</h4>
              <p className="text-sm text-red-800 dark:text-red-200 mt-1">
                Both primary and secondary services are currently offline. Please try again in a few
                moments.
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
