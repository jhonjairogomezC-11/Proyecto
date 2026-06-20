<template>
  <div class="auth-wrapper">
    <div class="auth-card">
      <div class="auth-brand">
        <svg class="auth-logo" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <path d="m11 17 2 2a1 1 0 0 0 1.4 0l4-4a1 1 0 0 0 0-1.4l-2-2"/>
          <path d="m13 13-2-2a1 1 0 0 0-1.4 0l-4 4a1 1 0 0 0 0 1.4l2 2"/>
          <circle cx="12" cy="12" r="10"/>
        </svg>
        <h1>VoluntApp</h1>
        <p>Conectando voluntarios con fundaciones en Colombia</p>
      </div>
      <RouterView />
    </div>
  </div>
</template>

<style scoped>
.auth-wrapper {
  min-height: 100vh;
  background: radial-gradient(circle at 10% 20%, var(--gray-900) 0%, #050b14 90%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  position: relative;
  overflow: hidden;
}

/* Red de fondo sutil */
.auth-wrapper::before {
  content: '';
  position: absolute;
  inset: 0;
  background-image: linear-gradient(rgba(255, 255, 255, 0.03) 1px, transparent 1px),
                    linear-gradient(90deg, rgba(255, 255, 255, 0.03) 1px, transparent 1px);
  background-size: 40px 40px;
  mask-image: radial-gradient(circle at 50% 50%, black, transparent 80%);
  pointer-events: none;
}

.auth-card {
  background: rgba(255, 255, 255, 0.98);
  border-radius: var(--radius-xl);
  box-shadow: 0 20px 40px -15px rgba(0, 0, 0, 0.3);
  width: 100%;
  max-width: 460px;
  padding: 48px 40px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  z-index: 10;
  transition: var(--transition);
}

.auth-brand {
  text-align: center;
  margin-bottom: 32px;
}
.auth-logo {
  color: var(--primary);
  margin-bottom: 12px;
  filter: drop-shadow(0 4px 6px rgba(13, 148, 136, 0.2));
}
.auth-brand h1 {
  font-size: 28px;
  font-weight: 800;
  color: var(--gray-900);
  letter-spacing: -0.03em;
  margin-bottom: 6px;
  font-family: 'Outfit', sans-serif;
}
.auth-brand p {
  font-size: 14px;
  color: var(--gray-500);
  line-height: 1.5;
}

@media (max-width: 480px) {
  .auth-card {
    padding: 32px 24px;
  }
}
</style>
