/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        // Roxo institucional do console, escala completa para estados de UI.
        brand: {
          50: '#f3f1ff',
          100: '#eae5ff',
          200: '#d8cfff',
          300: '#bcaaff',
          400: '#9d7bff',
          500: '#8148f5',
          600: '#7127e3',
          700: '#611cc4',
          800: '#5119a0',
          900: '#441880',
        },
        ink: {
          50: '#f8f9fb',
          100: '#f1f3f7',
          200: '#e4e7ee',
          300: '#cfd4e0',
          400: '#98a1b5',
          500: '#697285',
          600: '#4c5567',
          700: '#3a4152',
          800: '#242a37',
          900: '#141924',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'Segoe UI', 'sans-serif'],
      },
      boxShadow: {
        card: '0 1px 2px rgba(20, 25, 36, 0.04), 0 1px 3px rgba(20, 25, 36, 0.06)',
        pop: '0 12px 32px rgba(20, 25, 36, 0.16)',
      },
    },
  },
  plugins: [],
}
