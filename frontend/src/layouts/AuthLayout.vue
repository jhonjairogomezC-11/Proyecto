<template>
  <div class="auth-wrapper">
    <div class="auth-card">
      <div class="auth-brand">
        <span>🤝</span>
        <h1>VoluntApp</h1>
        <p>Conectando voluntarios con fundaciones</p>
      </div>
      <RouterView />
    </div>
  </div>
</template>

<style scoped>
.auth-wrapper {
  min-height: 100vh;
  background: linear-gradient(135deg, #1e3a8a 0%, #2563eb 50%, #059669 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
}
.auth-card {
  background: var(--white);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-lg);
  width: 100%;
  max-width: 440px;
  padding: 40px 36px;
}
.auth-brand {
  text-align: center;
  margin-bottom: 30px;
}
.auth-brand span { font-size: 42px; }
.auth-brand h1 { font-size: 26px; font-weight: 700; color: var(--primary); margin: 6px 0 4px; }
.auth-brand p  { font-size: 14px; color: var(--gray-500); }
</style>
