import { defineStore } from 'pinia'
import { ref } from 'vue'
import api from '@/services/api'

export const useFavoritosStore = defineStore('favoritos', () => {
  const publicacionIds = ref(new Set())
  const fundacionIds   = ref(new Set())
  const cargado        = ref(false)

  async function cargarIds() {
    try {
      const { data } = await api.get('/voluntario/favoritos/ids')
      publicacionIds.value = new Set(data.publicaciones || [])
      fundacionIds.value   = new Set(data.fundaciones || [])
      cargado.value = true
    } catch {}
  }

  function esFavoritoPublicacion(id) {
    return publicacionIds.value.has(id)
  }

  function esFavoritoFundacion(id) {
    return fundacionIds.value.has(id)
  }

  async function togglePublicacion(id) {
    const { data } = await api.post(`/voluntario/favoritos/publicacion/${id}`)
    const next = new Set(publicacionIds.value)
    if (data.favorito) next.add(id)
    else next.delete(id)
    publicacionIds.value = next
    return data.favorito
  }

  async function toggleFundacion(id) {
    const { data } = await api.post(`/voluntario/favoritos/fundacion/${id}`)
    const next = new Set(fundacionIds.value)
    if (data.favorito) next.add(id)
    else next.delete(id)
    fundacionIds.value = next
    return data.favorito
  }

  return {
    publicacionIds,
    fundacionIds,
    cargado,
    cargarIds,
    esFavoritoPublicacion,
    esFavoritoFundacion,
    togglePublicacion,
    toggleFundacion,
  }
})
