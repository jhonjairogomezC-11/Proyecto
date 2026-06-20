<template>
  <div>
    <h1 class="page-title mb-2">Ranking de Voluntarios</h1>
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
        <!-- 2do lugar -->
        <div class="podio-item segundo">
          <div class="podio-avatar">{{ ranking.top[1]?.nombre?.charAt(0).toUpperCase() }}</div>
          <p class="podio-nombre">{{ ranking.top[1]?.nombre }}</p>
          <p class="podio-pts">{{ ranking.top[1]?.puntos }} pts</p>
          <div class="podio-base pos2">
            <span>2°</span>
          </div>
        </div>
        
        <!-- 1er lugar -->
        <div class="podio-item primero">
          <div class="corona">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--warning);"><path d="M2 4l3 12h14l3-12-6 7-4-7-4 7-6-7z"/><path d="M3 20h18"/></svg>
          </div>
          <div class="podio-avatar grande">{{ ranking.top[0]?.nombre?.charAt(0).toUpperCase() }}</div>
          <p class="podio-nombre">{{ ranking.top[0]?.nombre }}</p>
          <p class="podio-pts">{{ ranking.top[0]?.puntos }} pts</p>
          <div class="podio-base pos1">
            <span>1°</span>
          </div>
        </div>
        
        <!-- 3er lugar -->
        <div class="podio-item tercero">
          <div class="podio-avatar">{{ ranking.top[2]?.nombre?.charAt(0).toUpperCase() }}</div>
          <p class="podio-nombre">{{ ranking.top[2]?.nombre }}</p>
          <p class="podio-pts">{{ ranking.top[2]?.puntos }} pts</p>
          <div class="podio-base pos3">
            <span>3°</span>
          </div>
        </div>
      </div>

      <!-- Lista completa -->
      <div class="card">
        <div class="card-header">
          <h3>Clasificación completa</h3>
          <span class="badge badge-gray">{{ ranking.total }} voluntarios</span>
        </div>
        <div class="card-body" style="padding:0">
          <div v-if="!ranking.top?.length" class="empty-state">
            <svg class="empty-icon" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6"/><path d="M18 9h1.5a2.5 2.5 0 0 0 0-5H18"/><path d="M4 22h16"/><path d="M10 14.66V17c0 .55-.45 1-1 1H4v2h16v-2h-5c-.55 0-1-.45-1-1v-2.34"/></svg>
            <h3>Ranking vacío</h3>
            <p>Aún no hay voluntarios con puntos acumulados.</p>
          </div>
          <div v-else>
            <div
              v-for="entry in ranking.top"
              :key="entry.voluntario_id"
              :class="['ranking-row', esYo(entry) ? 'yo' : '', entry.posicion <= 3 ? 'top' + entry.posicion : '']"
            >
              <div class="posicion-badge">
                <span class="num">{{ entry.posicion }}</span>
              </div>
              <div class="entry-avatar">{{ entry.nombre?.charAt(0).toUpperCase() }}</div>
              <div class="entry-info">
                <p class="entry-nombre">
                  {{ entry.nombre }}
                  <span v-if="esYo(entry)" class="badge badge-primary" style="font-size:10px;margin-left:6px">Tú</span>
                </p>
                <p class="entry-municipio text-xs text-muted">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="vertical-align: middle; margin-right: 4px; color: var(--gray-400);"><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/></svg>
                  <span>{{ entry.municipio || 'Colombia' }}</span>
                </p>
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
                <p class="entry-municipio text-xs text-muted">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="vertical-align: middle; margin-right: 4px; color: var(--gray-400);"><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/></svg>
                  <span>{{ ranking.mi_posicion.municipio }}</span>
                </p>
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
.page-title { font-size: 24px; font-weight: 800; color: var(--gray-900); font-family: 'Outfit', sans-serif; letter-spacing: -0.02em; }
.tab-btn { display: inline-flex; align-items: center; padding: 8px 18px; border-radius: 99px; border: 1.5px solid var(--gray-300); background: var(--white); font-size: 13px; font-weight: 600; cursor: pointer; color: var(--gray-600); transition: var(--transition); }
.tab-btn:hover  { border-color: var(--primary); color: var(--primary); }
.tab-btn.active { background: var(--primary); color: #fff; border-color: var(--primary); }

/* Podio */
.podio { display: flex; align-items: flex-end; justify-content: center; gap: 12px; margin-top: 24px; }
.podio-item { display: flex; flex-direction: column; align-items: center; gap: 6px; }
.podio-avatar {
  width: 52px; height: 52px;
  background: var(--gray-200);
  border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  font-size: 20px; font-weight: 800; color: var(--gray-700);
  font-family: 'Outfit', sans-serif;
  box-shadow: var(--shadow);
}
.podio-avatar.grande {
  width: 68px; height: 68px;
  font-size: 26px;
  background: var(--primary);
  color: #fff;
  border: 3px solid var(--white);
  box-shadow: 0 8px 20px rgba(13, 148, 136, 0.25);
}
.podio-nombre { font-size: 13px; font-weight: 700; color: var(--gray-800); text-align: center; max-width: 90px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-family: 'Outfit', sans-serif; }
.podio-pts { font-size: 12px; font-weight: 600; color: var(--gray-500); }
.podio-base {
  padding: 8px 16px;
  border-radius: var(--radius);
  font-weight: 800;
  font-size: 14px;
  font-family: 'Outfit', sans-serif;
  text-align: center;
}
.pos1 { background: #fef3c7; color: #b45309; min-height: 80px; width: 80px; display: flex; align-items: center; justify-content: center; border: 1.5px solid #fde68a; }
.pos2 { background: #f1f5f9; color: #475569; min-height: 60px; width: 80px; display: flex; align-items: center; justify-content: center; border: 1.5px solid #e2e8f0; }
.pos3 { background: #ffedd5; color: #c2410c; min-height: 45px; width: 80px; display: flex; align-items: center; justify-content: center; border: 1.5px solid #fed7aa; }
.corona { margin-bottom: 2px; }

/* Lista */
.ranking-row { display: flex; align-items: center; gap: 14px; padding: 14px 20px; border-bottom: 1px solid var(--gray-100); transition: var(--transition); }
.ranking-row:last-child { border-bottom: none; }
.ranking-row:hover { background: var(--gray-50); }
.ranking-row.yo { background: var(--primary-light); }
.ranking-row.top1 { background: rgba(254, 243, 199, 0.35); }
.ranking-row.top2 { background: rgba(241, 245, 249, 0.35); }
.ranking-row.top3 { background: rgba(255, 237, 213, 0.35); }

.posicion-badge { width: 36px; flex-shrink: 0; text-align: center; }
.posicion-badge .num {
  font-size: 13.5px;
  font-weight: 800;
  font-family: 'Outfit', sans-serif;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: var(--gray-100);
  color: var(--gray-500);
}
.ranking-row.top1 .posicion-badge .num { background: #fef3c7; color: #b45309; border: 1px solid #fde68a; }
.ranking-row.top2 .posicion-badge .num { background: #f1f5f9; color: #475569; border: 1px solid #e2e8f0; }
.ranking-row.top3 .posicion-badge .num { background: #ffedd5; color: #c2410c; border: 1px solid #fed7aa; }

.entry-avatar { width: 38px; height: 38px; background: var(--gray-200); border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 15px; flex-shrink: 0; color: var(--gray-700); font-family: 'Outfit', sans-serif; }
.entry-info { flex: 1; min-width: 0; }
.entry-nombre { font-size: 14.5px; font-weight: 700; color: var(--gray-900); display: flex; align-items: center; font-family: 'Outfit', sans-serif; }
.entry-stats { display: flex; gap: 10px; flex-shrink: 0; }
.stat-chip { display: flex; flex-direction: column; align-items: center; background: var(--gray-100); border-radius: var(--radius); padding: 6px 12px; min-width: 60px; transition: var(--transition); }
.ranking-row.yo .stat-chip { background: var(--white); }
.stat-val { font-size: 15px; font-weight: 800; color: var(--gray-900); font-family: 'Outfit', sans-serif; }
.stat-lbl { font-size: 10px; color: var(--gray-500); font-weight: 500; }
.mi-posicion-sep { display: flex; align-items: center; gap: 12px; padding: 12px 20px; }
.sep-line { flex: 1; height: 1px; border-top: 1px dashed var(--gray-200); }
.sep-text { font-size: 11.5px; color: var(--gray-400); white-space: nowrap; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; }

.empty-icon {
  margin: 0 auto 12px;
  color: var(--gray-300);
  display: block;
}
</style>
