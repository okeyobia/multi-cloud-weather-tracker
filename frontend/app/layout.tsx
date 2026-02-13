import type { Metadata } from 'next'
import { ReactNode } from 'react'
import './globals.css'

export const metadata: Metadata = {
  title: 'Multi-Cloud Weather Tracker | AWS & Azure',
  description:
    'Real-time weather tracking powered by multi-cloud infrastructure. Experience intelligent failover and cloud-agnostic weather data.',
  keywords: [
    'weather',
    'multi-cloud',
    'AWS',
    'Azure',
    'real-time',
    'tracker',
    'failover',
    'DevOps',
  ],
  authors: [{ name: 'Cloud Engineer' }],
  viewport: {
    width: 'device-width',
    initialScale: 1,
    maximumScale: 1,
  },
  robots: 'index, follow',
  openGraph: {
    title: 'Multi-Cloud Weather Tracker',
    description:
      'Real-time weather tracking powered by AWS and Azure infrastructure with intelligent failover.',
    type: 'website',
    images: [
      {
        url: '/og-image.png',
        width: 1200,
        height: 630,
        alt: 'Multi-Cloud Weather Tracker',
      },
    ],
  },
}

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <meta charSet="utf-8" />
        <link rel="icon" href="/favicon.ico" />
      </head>
      <body className="bg-gradient-to-br from-blue-50 via-white to-sky-50 dark:from-slate-950 dark:via-slate-900 dark:to-blue-900 text-gray-900 dark:text-gray-100 transition-colors duration-300">
        <div className="min-h-screen flex flex-col">
          {/* Background Elements */}
          <div className="fixed inset-0 -z-10 overflow-hidden pointer-events-none">
            <div className="absolute top-20 left-10 w-72 h-72 bg-blue-200 rounded-full mix-blend-multiply filter blur-3xl opacity-20 dark:opacity-10 animate-blob" />
            <div className="absolute top-40 right-10 w-72 h-72 bg-sky-200 rounded-full mix-blend-multiply filter blur-3xl opacity-20 dark:opacity-10 animate-blob animation-delay-2000" />
            <div className="absolute -bottom-8 left-1/2 w-72 h-72 bg-cyan-200 rounded-full mix-blend-multiply filter blur-3xl opacity-20 dark:opacity-10 animate-blob animation-delay-4000" />
          </div>

          {/* Main Content */}
          <main className="flex-1 flex flex-col relative z-10">
            {children}
          </main>

          {/* Footer */}
          <footer className="mt-12 py-8 px-4 text-center text-sm text-gray-600 dark:text-gray-400 border-t border-gray-200 dark:border-gray-800">
            <p>
              Multi-Cloud Weather Tracker • Powered by{' '}
              <span className="font-semibold">AWS</span> and <span className="font-semibold">Azure</span>
            </p>
            <p className="mt-2 text-xs">
              🌍 Experience enterprise-grade weather tracking infrastructure
            </p>
          </footer>
        </div>
      </body>
    </html>
  )
}
