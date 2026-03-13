import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      'assets': '/src/assets',
      '@': '/src'
    }
  },
  server: {
    host: true, // Allows access from any device on the network
    port: 5173, // You can change this if needed
    strictPort: false,
  }
})
