<template>
  <span :class="['badge', cls]">{{ label }}</span>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({ estado: String, tipo: { type: String, default: 'postulacion' } })

const POSTULACION = {
  PENDIENTE:   { label: 'Pendiente',   cls: 'badge-warning' },
  ACEPTADO:    { label: 'Aceptado',    cls: 'badge-success' },
  RECHAZADO:   { label: 'Rechazado',   cls: 'badge-danger'  },
  RETIRADO:    { label: 'Retirado',    cls: 'badge-gray'    },
  ASISTIO:     { label: 'Asistió',     cls: 'badge-primary' },
  NO_ASISTIO:  { label: 'No asistió',  cls: 'badge-danger'  },
}
const PUBLICACION = {
  BORRADOR:              { label: 'Borrador',             cls: 'badge-gray'    },
  PENDIENTE_APROBACION:  { label: 'Pendiente aprobación', cls: 'badge-warning' },
  PUBLICADA:             { label: 'Publicada',            cls: 'badge-success' },
  CERRADA:               { label: 'Cerrada',              cls: 'badge-warning' },
  CANCELADA:             { label: 'Cancelada',            cls: 'badge-danger'  },
  COMPLETADA:            { label: 'Completada',           cls: 'badge-primary' },
  FINALIZADA:            { label: 'Finalizada',           cls: 'badge-gray'    },
}
const FUNDACION = {
  PENDIENTE:   { label: 'Pendiente',   cls: 'badge-warning' },
  APROBADA:    { label: 'Aprobada',    cls: 'badge-success' },
  RECHAZADA:   { label: 'Rechazada',   cls: 'badge-danger'  },
  SUSPENDIDA:  { label: 'Suspendida',  cls: 'badge-danger'  },
}
const REPORTE = {
  PENDIENTE:   { label: 'Pendiente',    cls: 'badge-warning' },
  EN_REVISION: { label: 'En revisión',  cls: 'badge-primary' },
  RESUELTO:    { label: 'Resuelto',     cls: 'badge-success' },
  DESESTIMADO: { label: 'Desestimado',  cls: 'badge-gray'    },
}

const map = computed(() => ({
  postulacion: POSTULACION,
  publicacion: PUBLICACION,
  fundacion: FUNDACION,
  reporte: REPORTE,
}[props.tipo] || {}))

const item = computed(() => map.value[props.estado] || { label: props.estado, cls: 'badge-gray' })
const cls   = computed(() => item.value.cls)
const label = computed(() => item.value.label)
</script>
