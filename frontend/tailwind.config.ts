import type { Config } from 'tailwindcss'
import defaultTheme from 'tailwindcss/defaultTheme'

const config: Config = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  darkMode: 'class',
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif', ...defaultTheme.fontFamily.sans],
      },
      colors: {
        // Cloud-inspired colors - SaaS palette
        cloud: {
          light: '#F8FBFF',
          pale: '#E8F2FF',
          soft: '#D4E6FF',
        },
        // DevOps & Monitoring colors
        'saas': {
          'darkest': '#0F1117',
          'dark': '#1C1F26',
          'gray-900': '#292D36',
          'gray-800': '#3D4451',
          'gray-700': '#525B6B',
        },
      },
      boxShadow: {
        // Soft, professional shadows for SaaS
        'soft': '0 1px 3px 0 rgba(0, 0, 0, 0.08)',
        'soft-md': '0 4px 12px 0 rgba(0, 0, 0, 0.08)',
        'soft-lg': '0 12px 24px 0 rgba(0, 0, 0, 0.12)',
        'soft-xl': '0 20px 40px 0 rgba(0, 0, 0, 0.15)',
        'glow-cyan': '0 0 20px rgba(34, 211, 238, 0.4)',
        'glow-blue': '0 0 20px rgba(59, 130, 246, 0.3)',
        'glow-purple': '0 0 20px rgba(168, 85, 247, 0.3)',
      },
      backgroundImage: {
        // Subtle gradients for modern look
        'gradient-radial': 'radial-gradient(var(--tw-gradient-stops))',
        'gradient-conic': 'conic-gradient(from 180deg at 50% 50%, var(--tw-gradient-stops))',
        'gradient-subtle': 'linear-gradient(135deg, var(--tw-gradient-stops))',
      },
      backdropBlur: {
        xs: '2px',
        sm: '4px',
      },
      animation: {
        // Smooth, professional animations
        'fade-in': 'fadeIn 0.5s ease-in-out',
        'slide-up': 'slideUp 0.5s ease-out',
        'pulse-subtle': 'pulseSubtle 2s ease-in-out infinite',
        'glow': 'glow 2s ease-in-out infinite',
        'float': 'float 3s ease-in-out infinite',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { transform: 'translateY(10px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        pulseSubtle: {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0.8' },
        },
        glow: {
          '0%, 100%': { boxShadow: '0 0 20px rgba(59, 130, 246, 0.3)' },
          '50%': { boxShadow: '0 0 30px rgba(59, 130, 246, 0.5)' },
        },
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%': { transform: 'translateY(-5px)' },
        },
      },
      transitionDuration: {
        '2000': '2000ms',
        '3000': '3000ms',
      },
      spacing: {
        safe: 'max(env(safe-area-inset-right), 1rem)',
        'safe-left': 'env(safe-area-inset-left)',
        'safe-right': 'env(safe-area-inset-right)',
      },
      borderRadius: {
        // Modern, softer curves
        '3xl': '1.5rem',
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
}
export default config
