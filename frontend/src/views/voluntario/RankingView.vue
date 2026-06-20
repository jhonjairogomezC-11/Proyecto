<template>
  <div>
    <h1 class="page-title mb-2">🏆 Ranking de Voluntarios</h1>
    <p class="text-muted text-sm mb-6">Los voluntarios con más participaciones y puntos acumulados.</p>

    <div class="flex gap-3 mb-6 flex-wrap">
      <button v-for="t in tops" :key="t" :class="['tab-btn', topActivo === t ? 'active' : '']" @click="cambiarTop(t)">
        Top {{ t }}
      </button>
    </div>

    <div v-if="loading" class="loading-center"><AppSpinner /></div>

    <template v-else>
      <!-- Podio Top 3 -->
      <div v-if="ranking.top?.length >= 3" class="podio mb-6">
        <div class="podio-item segundo">
          <div class="podio-avatar">{{ ranking.top[1]?.nombre?.charAt(0) }}</div>
          <p class="podio-nombre">{{ ranking.top[1]?.nombre }}</p>
          <p class="podio-pts">{{ ranking.top[1]?.puntos }} pts</p>
          <div class="podio-base pos2">🥈 2°</div>
        </div>
        <div class="podio-item primero">
          <div class="corona">👑</div>
          <div class="podio-avatar grande">{{ ranking.top[0]?.nombre?.charAt(0) }}</div>
          <p class="podio-nombre">{{ ranking.top[0]?.nombre }}</p>
          <p class="podio-pts">{{ ranking.top[0]?.puntos }} pts</p>
          <div class="podio-base pos1">🥇 1°</div>
        </div>
        <div class="podio-item tercero">
          <div class="podio-avatar">{{ ranking.top[2]?.nombre?.charAt(0) }}</div>
          <p class="podio-nombre">{{ ranking.top[2]?.nombre }}</p>
          <p class="podio-pts">{{ ranking.top[2]?.puntos }} pts</p>
          <div class="podio-base pos3">🥉 3°</div>
        </div>
      </div>

      <!-- Lista completa -->
      <div class="card">
        <div class="card-header">
          <h3>Clasificación completa</h3>
          <span class="text-sm text-muted">{{ ranking.total }} voluntarios</span>
        </div>
        <div class="card-body" style="padding:0">
          <div v-if="!ranking.top?.length" class="empty-state">
            <div class="icon">🏆</div>
            <h3>Ranking vacío</h3>
            <p>Aún no hay voluntarios con puntos acumulados.</p>
          </div>
          <div v-else>
            <div
              v-for="entry in ranking.top"
              :key="entry.voluntario_id"
              :class="['ranking-row', esYo(entry) ? 'yo' : '', entry.posicion <= 3 ? 'top3' : '']"
            >
              <div class="posicion-badge">
                <span v-if="entry.posicion === 1">🥇</span>
                <span v-else-if="entry.posicion === 2">🥈</span>
                <span v-else-if="entry.posicion === 3">🥉</span>
                <span v-else class="num">{{ entry.posicion }}</span>
              </div>
              <div class="entry-avatar">{{ entry.nombre?.charAt(0).toUpperCase() }}</div>
              <div class="entry-info">
                <p class="entry-nombre">
                  {{ entry.nombre }}
                  <span v-if="esYo(entry)" class="badge badge-primary" style="font-size:10px;margin-left:6px">Tú</span>
                </p>
                <p class="entry-municipio text-xs text-muted">📍 {{ entry.municipio || 'Colombia' }}</p>
              </div>
              <div class="entry-stats">
                <div class="stat-chip">
                  <span class="stat-val">{{ entry.puntos }}</span>
                  <span class="stat-lbl">pts</span>
                </div>
                <div class="stat-chip">
                  <span class="stat-val">{{ entry.participaciones }}</span>
                  <span class="stat-lbl">actividades</span>
                </div>
              </div>
            </div>

            <!-- Mi posición si no estoy en el top -->
            <div v-if="ranking.mi_posicion" class="mi-posicion-sep">
              <div class="sep-line"></div>
              <span class="sep-text">Tu posición</span>
              <div class="sep-line"></div>
            </div>
            <div v-if="ranking.mi_posicion" class="ranking-row yo">
              <div class="posicion-badge">
                <span class="num">{{ ranking.mi_posicion.posicion }}</span>
              </div>
              <div class="entry-avatar" style="background:var(--primary)">{{ ranking.mi_posicion.nombre?.charAt(0).toUpperCase() }}</div>
              <div class="entry-info">
                <p class="entry-nombre">{{ ranking.mi_posicion.nombre }} <span class="badge badge-primary" style="font-size:10px;margin-left:6px">Tú</span></p>
                <p class="entry-municipio text-xs text-muted">📍 {{ ranking.mi_posicion.municipio }}</p>
              </div>
              <div class="entry-stats">
                <div class="stat-chip">
                  <span class="stat-val">{{ ranking.mi_posicion.puntos }}</span>
                  <span class="stat-lbl">pts</span>
                </div>
                <div class="stat-chip">
                  <span class="stat-val">{{ ranking.mi_posicion.participaciones }}</span>
                  <span class="stat-lbl">actividades</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import api from '@/services/api'
import AppSpinner from '@/components/AppSpinner.vue'

const auth    = useAuthStore()
const ranking = ref({ top: [], mi_posicion: null, total: 0 })
const loading = ref(true)
const topActivo = ref(10)
const tops = [10, 25, 50]

function esYo(entry) {
  return ranking.value.mi_posicion === null &&
    auth.user && entry.nombre === auth.user.nombre
}

function cambiarTop(t) {
  topActivo.value = t
  cargar()
}

async function cargar() {
  loading.value = true
  try {
    const { data } = await api.get(`/ranking?top=${topActivo.value}`)
    ranking.value = data
  } finally {
    loading.value = false
  }
}

onMounted(() => cargar())
</script>

<style scoped>
.page-title { font-size: 22px; font-weight: 700; }
.tab-btn { display: inline-flex; align-items: center; padding: 7px 16px; border-radius: 99px; border: 1.5px solid var(--gray-300); background: var(--white); font-size: 13px; font-weight: 500; cursor: pointer; color: var(--gray-700); transition: all .18s; }
.tab-btn:hover  { border-color: var(--primary); color: var(--primary); }
.tab-btn.active { background: var(--primary); color: #fff; border-color: var(--primary); }

/* Podio */
.podio { display: flex; align-items: flex-end; justify-content: center; gap: 8px; }
.podio-item { display: flex; flex-direction: column; align-items: center; gap: 4px; }
.podio-avatar { width: 48px; height: 48px; background: var(--gray-300); border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 20px; font-weight: 700; color: var(--gray-700); }
.podio-avatar.grande { width: 60px; height: 60px; font-size: 26px; background: var(--primary); color: #fff; }
.podio-nombre { font-size: 12px; font-weight: 600; text-align: center; max-width: 80px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.podio-pts { font-size: 11px; color: var(--gray-500); }
.podio-base { padding: 6px 12px; border-radius: var(--radius); font-weight: 700; font-size: 13px; }
.pos1 { background: #fef3c7; color: #92400e; min-height: 70px; display: flex; align-items: center; }
.pos2 { background: #f1f5f9; color: #475569; min-height: 50px; display: flex; align-items: center; }
.pos3 { background: #fdf4f0; color: #92400e; min-height: 35px; display: flex; align-items: center; }
.corona { font-size: 22px; }

/* Lista */
.ranking-row { display: flex; align-items: center; gap: 12px; padding: 12px 18px; border-bottom: 1px solid var(--gray-100); transition: background .15s; }
.ranking-row:last-child { border-bottom: none; }
.ranking-row:hover { background: var(--gray-50); }
.ranking-row.yo { background: #eff6ff; }
.ranking-row.top3 { background: #fffbeb; }
.posicion-badge { width: 32px; flex-shrink: 0; text-align: center; font-size: 18px; }
.posicion-badge .num { font-size: 14px; font-weight: 700; color: var(--gray-500); }
.entry-avatar { width: 38px; height: 38px; background: var(--gray-300); border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 15px; flex-shrink: 0; color: var(--gray-700); }
.entry-info { flex: 1; min-width: 0; }
.entry-nombre { font-size: 14px; font-weight: 600; display: flex; align-items: center; }
.entry-municipio { margin-top: 2px; }
.entry-stats { display: flex; gap: 10px; flex-shrink: 0; }
.stat-chip { display: flex; flex-direction: column; align-items: center; background: var(--gray-100); border-radius: var(--radius); padding: 4px 10px; min-width: 54px; }
.stat-val { font-size: 15px; font-weight: 700; color: var(--gray-800); }
.stat-lbl { font-size: 10px; color: var(--gray-500); }
.mi-posicion-sep { display: flex; align-items: center; gap: 10px; padding: 8px 18px; }
.sep-line { flex: 1; height: 1px; background: var(--gray-200); border-top: 1px dashed var(--gray-300); }
.sep-text { font-size: 11px; color: var(--gray-400); white-space: nowrap; }
</style>
