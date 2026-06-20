<template>
  <div>
    <h1 class="page-title mb-2">Mis Favoritos</h1>
    <p class="text-muted mb-6">Actividades y fundaciones que guardaste para revisar después.</p>

    <div class="tabs mb-6">
      <button :class="['tab', tab === 'actividades' ? 'active' : '']" @click="tab = 'actividades'">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right: 6px;"><path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/></svg>
        <span>Actividades</span>
        <span class="tab-count">{{ actividades.length }}</span>
      </button>
      <button :class="['tab', tab === 'fundaciones' ? 'active' : '']" @click="tab = 'fundaciones'">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right: 6px;"><rect x="4" y="2" width="16" height="20" rx="2" ry="2"/><line x1="9" y1="22" x2="9" y2="16"/><line x1="15" y1="22" x2="15" y2="16"/></svg>
        <span>Fundaciones</span>
        <span class="tab-count">{{ fundaciones.length }}</span>
      </button>
    </div>

    <div v-if="loading" class="loading-center"><AppSpinner /></div>

    <template v-else>
      <!-- Actividades -->
      <template v-if="tab === 'actividades'">
        <div v-if="actividades.length === 0" class="empty-state">
          <svg class="empty-icon" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/></svg>
          <h3>Sin actividades favoritas</h3>
          <p>Marca con el corazón las convocatorias que te interesen.</p>
          <RouterLink :to="{ name: 'convocatorias' }" class="btn btn-primary mt-4">Explorar convocatorias</RouterLink>
        </div>
        <div v-else class="pub-grid">
          <div v-for="fav in actividades" :key="fav.id" class="pub-card">
            <div class="pub-img-wrap">
              <ImageCarousel :images="fav.publicacion?.imagenes?.length ? fav.publicacion.imagenes : [fav.publicacion?.imagen]" />
            </div>
            <div class="pub-content">
              <h3 class="pub-title">{{ fav.publicacion?.titulo }}</h3>
              
              <div class="pub-info-list">
                <p class="pub-info-item">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="4" y="2" width="16" height="20" rx="2" ry="2"/><line x1="9" y1="22" x2="9" y2="16"/><line x1="15" y1="22" x2="15" y2="16"/></svg>
                  <span>{{ fav.publicacion?.fundacion?.nombre }}</span>
                </p>
                <p class="pub-info-item">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
                  <span>{{ formatDate(fav.publicacion?.fecha_inicio) }}</span>
                </p>
              </div>

              <div class="pub-actions">
                <RouterLink :to="{ name: 'convocatorias' }" class="btn btn-primary btn-sm">Ver convocatoria</RouterLink>
                <button class="btn-fav active" @click="quitar(fav)" title="Quitar de favoritos">
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" stroke-width="2" style="color: var(--danger);"><path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/></svg>
                </button>
              </div>
            </div>
          </div>
        </div>
      </template>

      <!-- Fundaciones -->
      <template v-else>
        <div v-if="fundaciones.length === 0" class="empty-state">
          <svg class="empty-icon" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="4" y="2" width="16" height="20" rx="2" ry="2"/><line x1="9" y1="22" x2="9" y2="16"/><line x1="15" y1="22" x2="15" y2="16"/></svg>
          <h3>Sin fundaciones favoritas</h3>
          <p>Guarda fundaciones desde las convocatorias para seguirlas.</p>
        </div>
        <div v-else class="fund-grid">
          <div v-for="fav in fundaciones" :key="fav.id" class="fund-card">
            <div class="fund-avatar">{{ fav.fundacion?.nombre?.charAt(0).toUpperCase() }}</div>
            <div class="fund-info">
              <h3>{{ fav.fundacion?.nombre }}</h3>
              <p class="text-sm text-muted">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="vertical-align: middle; margin-right: 4px;"><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/></svg>
                <span>{{ fav.fundacion?.municipio?.nombre || 'Colombia' }}</span>
              </p>
            </div>
            <button class="btn-fav active" @click="quitar(fav)">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" stroke-width="2" style="color: var(--danger);"><path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/></svg>
            </button>
          </div>
        </div>
      </template>
    </template>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import api from '@/services/api'
import { useFavoritosStore } from '@/stores/favoritos'
import AppSpinner from '@/components/AppSpinner.vue'
import ImageCarousel from '@/components/ImageCarousel.vue'

const favoritosStore = useFavoritosStore()
const loading  = ref(true)
const tab      = ref('actividades')
const items    = ref([])

const actividades = computed(() => items.value.filter(f => f.tipo === 'PUBLICACION'))
const fundaciones = computed(() => items.value.filter(f => f.tipo === 'FUNDACION'))

function formatDate(d) {
  if (!d) return ''
  return new Date(d).toLocaleDateString('es-CO', { day: '2-digit', month: 'short', year: 'numeric' })
}

async function cargar() {
  loading.value = true
  try {
    const { data } = await api.get('/voluntario/favoritos')
    items.value = Array.isArray(data) ? data : (data.data || [])
    await favoritosStore.cargarIds()
  } finally {
    loading.value = false
  }
}

async function quitar(fav) {
  await api.delete(`/voluntario/favoritos/${fav.id}`)
  items.value = items.value.filter(f => f.id !== fav.id)
  if (fav.publicacion_id) favoritosStore.publicacionIds.delete(fav.publicacion_id)
  if (fav.fundacion_id) favoritosStore.fundacionIds.delete(fav.fundacion_id)
}

onMounted(() => {
  cargar()
})
</script>

<style scoped>
.page-title { font-size: 24px; font-weight: 800; color: var(--gray-900); font-family: 'Outfit', sans-serif; letter-spacing: -0.02em; }
.tabs { display: flex; gap: 8px; border-bottom: 1px solid var(--gray-200); padding-bottom: 1px; }
.tab {
  display: flex;
  align-items: center;
  padding: 12px 20px;
  background: transparent;
  border: none;
  border-bottom: 2px solid transparent;
  font-size: 14px;
  font-weight: 600;
  color: var(--gray-500);
  cursor: pointer;
  transition: var(--transition);
}
.tab:hover { color: var(--gray-800); }
.tab.active {
  color: var(--primary);
  border-bottom-color: var(--primary);
}
.tab-count {
  margin-left: 6px;
  background: var(--gray-100);
  color: var(--gray-600);
  font-size: 11px;
  font-weight: 700;
  padding: 2px 6px;
  border-radius: 99px;
  transition: var(--transition);
}
.tab.active .tab-count {
  background: var(--primary-light);
  color: var(--primary);
}

.pub-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 20px; margin-bottom: 24px; }
.pub-card {
  background: var(--white);
  border: 1px solid var(--gray-200);
  border-radius: var(--radius-lg);
  overflow: hidden;
  transition: var(--transition);
}
.pub-card:hover { transform: translateY(-4px); box-shadow: var(--shadow-md); }
.pub-img-wrap {
  position: relative;
  height: 180px;
  overflow: hidden;
}
.pub-content { padding: 20px; display: flex; flex-direction: column; gap: 8px; }
.pub-title { font-size: 16px; font-weight: 700; color: var(--gray-900); font-family: 'Outfit', sans-serif; }
.pub-info-list {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin: 6px 0;
}
.pub-info-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: var(--gray-500);
  font-weight: 500;
}
.pub-info-item svg {
  color: var(--gray-400);
}
.pub-actions { display: flex; justify-content: space-between; align-items: center; margin-top: 8px; }
.btn-fav {
  background: transparent;
  border: none;
  cursor: pointer;
  padding: 8px;
  border-radius: 50%;
  transition: var(--transition);
  display: flex;
  align-items: center;
  justify-content: center;
}
.btn-fav:hover { background: var(--gray-100); }

.fund-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 16px; }
.fund-card {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px;
  border: 1px solid var(--gray-200);
  border-radius: var(--radius-lg);
  background: var(--white);
  transition: var(--transition);
}
.fund-card:hover { box-shadow: var(--shadow-md); }
.fund-avatar {
  width: 44px;
  height: 44px;
  background: var(--primary-light);
  color: var(--primary);
  border-radius: var(--radius);
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 16px;
  font-family: 'Outfit', sans-serif;
  flex-shrink: 0;
}
.fund-info { flex: 1; min-width: 0; }
.fund-info h3 { font-size: 15px; font-weight: 700; color: var(--gray-900); font-family: 'Outfit', sans-serif; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }

.empty-icon {
  margin: 0 auto 12px;
  color: var(--gray-300);
  display: block;
}
</style>
