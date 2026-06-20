<template>
  <div class="carousel" @mouseenter="pause = true" @mouseleave="pause = false">
    <div class="carousel-track" :style="{ transform: `translateX(-${active * 100}%)` }">
      <div v-for="(img, i) in slides" :key="i" class="carousel-slide">
        <img :src="resolveUrl(img)" :alt="alt" loading="lazy" />
      </div>
      <div v-if="slides.length === 0" class="carousel-slide carousel-placeholder">
        <span>{{ placeholder }}</span>
      </div>
    </div>

    <template v-if="slides.length > 1">
      <button class="carousel-btn prev" aria-label="Anterior" @click.stop="prev">‹</button>
      <button class="carousel-btn next" aria-label="Siguiente" @click.stop="next">›</button>
      <div class="carousel-dots">
        <button
          v-for="(_, i) in slides"
          :key="i"
          :class="['dot', i === active ? 'active' : '']"
          @click.stop="active = i"
        />
      </div>
    </template>
  </div>
</template>

<script setup>
import { ref, watch, onMounted, onUnmounted } from 'vue'

const props = defineProps({
  images: { type: Array, default: () => [] },
  alt: { type: String, default: 'Imagen de convocatoria' },
  placeholder: { type: String, default: '🤝' },
  autoplay: { type: Boolean, default: true },
  interval: { type: Number, default: 4000 },
})

const active = ref(0)
const pause  = ref(false)
let timer    = null

const slides = ref([])

watch(() => props.images, (imgs) => {
  slides.value = (imgs || []).map(img => (typeof img === 'string' ? img : img?.url)).filter(Boolean)
  active.value = 0
}, { immediate: true })

function resolveUrl(url) {
  if (!url) return ''
  if (url.startsWith('http') || url.startsWith('/')) return url
  return `/storage/${url}`
}

function next() {
  if (slides.value.length < 2) return
  active.value = (active.value + 1) % slides.value.length
}

function prev() {
  if (slides.value.length < 2) return
  active.value = (active.value - 1 + slides.value.length) % slides.value.length
}

function startAutoplay() {
  stopAutoplay()
  if (!props.autoplay || slides.value.length < 2) return
  timer = setInterval(() => {
    if (!pause.value) next()
  }, props.interval)
}

function stopAutoplay() {
  if (timer) clearInterval(timer)
}

onMounted(startAutoplay)
onUnmounted(stopAutoplay)
watch(slides, startAutoplay)
</script>

<style scoped>
.carousel {
  position: relative;
  overflow: hidden;
  border-radius: inherit;
  background: linear-gradient(135deg, #6366f1, #8b5cf6);
  height: 100%;
  min-height: 160px;
}
.carousel-track {
  display: flex;
  height: 100%;
  transition: transform 0.45s cubic-bezier(0.4, 0, 0.2, 1);
}
.carousel-slide {
  min-width: 100%;
  height: 100%;
  flex-shrink: 0;
}
.carousel-slide img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}
.carousel-placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 48px;
  color: rgba(255,255,255,.85);
  background: linear-gradient(135deg, #6366f1, #06b6d4);
}
.carousel-btn {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  background: rgba(255,255,255,.9);
  border: none;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  cursor: pointer;
  font-size: 18px;
  line-height: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 2px 8px rgba(0,0,0,.15);
  opacity: 0;
  transition: opacity 0.2s;
  z-index: 2;
}
.carousel:hover .carousel-btn { opacity: 1; }
.carousel-btn.prev { left: 8px; }
.carousel-btn.next { right: 8px; }
.carousel-dots {
  position: absolute;
  bottom: 8px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  gap: 5px;
  z-index: 2;
}
.dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  border: none;
  background: rgba(255,255,255,.5);
  cursor: pointer;
  padding: 0;
  transition: all 0.2s;
}
.dot.active { background: #fff; width: 18px; border-radius: 4px; }
</style>
