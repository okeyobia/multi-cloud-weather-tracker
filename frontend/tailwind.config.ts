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
        sans: ['var(--font-sans)', ...defaultTheme.fontFamily.sans],
      },
      colors: {
        // Cloud-inspired colors
        cloud: {
          light: '#F8FBFF',
          pale: '#E8F2FF',
          soft: '#D4E6FF',
        },
      },
      boxShadow: {
        // Enhanced shadows for depth
        'cloud-sm': '0 1px 3px 0 rgba(2, 132, 199, 0.1)',
        'cloud-md': '0 4px 6px 0 rgba(2, 132, 199, 0.1)',
        'cloud-lg': '0 10px 15px 0 rgba(2, 132, 199, 0.15)',
        'cloud-xl': '0 20px 25px 0 rgba(2, 132, 199, 0.2)',
      },
      backgroundImage: {
        // Gradient backgrounds
        'gradient-radial': 'radial-gradient(var(--tw-gradient-stops))',
        'gradient-conic': 'conic-gradient(from 180deg at 50% 50%, var(--tw-gradient-stops))',
      },
      animation: {
        // Custom animations
        'fade-in': 'fadeIn 0.5s ease-in-out',
        'slide-up': 'slideUp 0.5s ease-out',
        'bounce-light': 'bounce 3s infinite',
        'spin-slow': 'spin 3s linear infinite',
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
      },
      transitionDuration: {
        '2000': '2000ms',
        '3000': '3000ms',
      },
      blur: {
        xs: '2px',
      },
      backdropBlur: {
        xs: '2px',
      },
      spacing: {
        safe: 'max(env(safe-area-inset-right), 1rem)',
        'safe-left': 'env(safe-area-inset-left)',
        'safe-right': 'env(safe-area-inset-right)',
      },
      borderRadius: {
        // Softer, more modern rounded corners
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
