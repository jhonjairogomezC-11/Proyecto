<template>
  <div>
    <h1 class="page-title mb-2">Mis Favoritos</h1>
    <p class="text-muted mb-6">Actividades y fundaciones que guardaste para revisar después.</p>

    <div class="tabs mb-6">
      <button :class="['tab', tab === 'actividades' ? 'active' : '']" @click="tab = 'actividades'">
        🤝 Actividades <span class="tab-count">{{ actividades.length }}</span>
      </button>
      <button :class="['tab', tab === 'fundaciones' ? 'active' : '']" @click="tab = 'fundaciones'">
        🏢 Fundaciones <span class="tab-count">{{ fundaciones.length }}</span>
      </button>
    </div>

    <div v-if="loading" class="loading-center"><AppSpinner /></div>

    <template v-else>
      <!-- Actividades -->
      <template v-if="tab === 'actividades'">
        <div v-if="actividades.length === 0" class="empty-state">
          <div class="icon">❤️</div>
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
              <p class="text-sm text-muted">🏢 {{ fav.publicacion?.fundacion?.nombre }}</p>
              <p class="text-sm text-muted">📅 {{ formatDate(fav.publicacion?.fecha_inicio) }}</p>
              <div class="pub-actions">
                <RouterLink :to="{ name: 'convocatorias' }" class="btn btn-primary btn-sm">Ver convocatoria</RouterLink>
                <button class="btn-fav active" @click="quitar(fav)" title="Quitar de favoritos">❤️</button>
              </div>
            </div>
          </div>
        </div>
      </template>

      <!-- Fundaciones -->
      <template v-else>
        <div v-if="fundaciones.length === 0" class="empty-state">
          <div class="icon">🏢</div>
          <h3>Sin fundaciones favoritas</h3>
          <p>Guarda fundaciones desde las convocatorias para seguirlas.</p>
        </div>
        <div v-else class="fund-grid">
          <div v-for="fav in fundaciones" :key="fav.id" class="fund-card">
            <div class="fund-avatar">{{ fav.fundacion?.nombre?.charAt(0) }}</div>
            <div class="fund-info">
              <h3>{{ fav.fundacion?.nombre }}</h3>
              <p class="text-sm text-muted">{{ fav.fundacion?.municipio?.nombre || 'Colombia' }}</p>
            </div>
            <button class="btn-fav active" @click="quitar(fav)">❤️</button>
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

onMounted(cargar)
</script>

<style scoped>
.page-title { font-size: 24px; font-weight: 800; }
.tabs { display: flex; gap: 8px; flex-wrap: wrap; }
.tab {
  display: inline-flex; align-items: center; gap: 8px;
  padding: 9px 18px; border-radius: 99px;
  border: 1.5px solid var(--gray-300);
  background: var(--white); font-size: 14px; font-weight: 500;
  cursor: pointer; transition: all .2s;
}
.tab:hover { border-color: var(--primary); color: var(--primary); }
.tab.active { background: var(--primary); color: #fff; border-color: var(--primary); }
.tab-count { font-size: 11px; background: rgba(0,0,0,.1); padding: 1px 7px; border-radius: 99px; }
.tab.active .tab-count { background: rgba(255,255,255,.25); }

.pub-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 20px; }
.pub-card {
  background: var(--white); border: 1px solid var(--gray-200);
  border-radius: 16px; overflow: hidden;
  transition: transform .2s, box-shadow .2s;
}
.pub-card:hover { transform: translateY(-4px); box-shadow: var(--shadow-lg); }
.pub-img-wrap { height: 160px; }
.pub-content { padding: 16px; }
.pub-title { font-size: 16px; font-weight: 700; margin-bottom: 6px; }
.pub-actions { display: flex; gap: 8px; margin-top: 12px; align-items: center; }

.fund-grid { display: flex; flex-direction: column; gap: 12px; }
.fund-card {
  display: flex; align-items: center; gap: 14px;
  padding: 16px 20px; background: var(--white);
  border: 1px solid var(--gray-200); border-radius: 14px;
  transition: box-shadow .2s;
}
.fund-card:hover { box-shadow: var(--shadow-md); }
.fund-avatar {
  width: 48px; height: 48px; border-radius: 12px;
  background: linear-gradient(135deg, #6366f1, #8b5cf6);
  color: #fff; font-weight: 800; font-size: 20px;
  display: flex; align-items: center; justify-content: center;
}
.fund-info { flex: 1; }
.fund-info h3 { font-size: 15px; font-weight: 700; }

.btn-fav {
  background: none; border: 2px solid var(--gray-300);
  border-radius: 50%; width: 38px; height: 38px;
  font-size: 18px; cursor: pointer; transition: all .2s;
  display: flex; align-items: center; justify-content: center;
  flex-shrink: 0;
}
.btn-fav:hover { border-color: #f43f5e; transform: scale(1.1); }
.btn-fav.active { border-color: #f43f5e; background: #fff1f2; }
</style>
