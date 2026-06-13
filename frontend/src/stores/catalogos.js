import { defineStore } from 'pinia'
import { ref } from 'vue'
import api from '@/services/api'

export const useCatalogosStore = defineStore('catalogos', () => {
  const departamentos = ref([])
  const municipios    = ref([])
  const habilidades   = ref([])
  const intereses     = ref([])
  const areasImpacto  = ref([])

  async function cargarDepartamentos() {
    if (departamentos.value.length) return
    const { data } = await api.get('/catalogos/departamentos')
    departamentos.value = data
  }

  async function cargarMunicipios(departamento_id = null) {
    const params = departamento_id ? { departamento_id } : {}
    const { data } = await api.get('/catalogos/municipios', { params })
    municipios.value = data
    return data
  }

  async function cargarHabilidades() {
    if (habilidades.value.length) return
    const { data } = await api.get('/catalogos/habilidades')
    habilidades.value = data
  }

  async function cargarIntereses() {
    if (intereses.value.length) return
    const { data } = await api.get('/catalogos/intereses')
    intereses.value = data
  }

  async function cargarAreasImpacto() {
    if (areasImpacto.value.length) return
    const { data } = await api.get('/catalogos/areas-impacto')
    areasImpacto.value = data
  }

  return {
    departamentos, municipios, habilidades, intereses, areasImpacto,
    cargarDepartamentos, cargarMunicipios, cargarHabilidades,
    cargarIntereses, cargarAreasImpacto
  }
})
