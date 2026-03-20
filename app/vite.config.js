import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  base: process.env.VITE_BASE_PATH || '/Test_cycle_TDD/',
  define: {
    __VITE_API_URL__: JSON.stringify(process.env.VITE_API_URL || '')
  }
})
