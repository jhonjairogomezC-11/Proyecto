import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { fileURLToPath, URL } from 'node:url'

// Opcional: varios servidores PHP para concurrencia en Windows
// Ejemplo: VITE_PHP_SERVERS=http://127.0.0.1:8001,http://127.0.0.1:8002
const PHP_SERVERS = (process.env.VITE_PHP_SERVERS || 'http://127.0.0.1:8000')
  .split(',')
  .map(s => s.trim())
  .filter(Boolean)

let rrIndex = 0
function nextServer() {
  const server = PHP_SERVERS[rrIndex % PHP_SERVERS.length]
  rrIndex++
  return server
}

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  },
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: PHP_SERVERS[0],
        changeOrigin: true,
        router: PHP_SERVERS.length > 1 ? () => nextServer() : undefined,
      }
    }
  }
})
