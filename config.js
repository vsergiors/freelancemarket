// ============================================================
// FREELANCEMARKET - Supabase Configuration
// ============================================================
// Reemplaza estos valores con los de tu proyecto Supabase
// Dashboard: https://supabase.com/dashboard

const SUPABASE_URL = 'https://lsougtrfsbpvadyikyfm.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxzb3VndHJmc2JwdmFkeWlreWZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2NzAyMTcsImV4cCI6MjA5MTI0NjIxN30.NeqCGj-b7nK9EBXBhpFN65fY4yYwqnuTpX_jigDV38s';

// Inicializa el cliente Supabase (cargado vía CDN en cada HTML)
function getSupabaseClient() {
  return supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
}

// Colores y constantes globales
const APP_NAME = 'FreelanceMarket';
const APP_VERSION = '1.0.0';

// Categorías de servicios
const CATEGORIES = [
  { id: 'design', label: 'Diseño Gráfico', icon: '🎨' },
  { id: 'dev', label: 'Desarrollo Web', icon: '💻' },
  { id: 'marketing', label: 'Marketing Digital', icon: '📣' },
  { id: 'video', label: 'Video & Animación', icon: '🎬' },
  { id: 'writing', label: 'Redacción & Traducción', icon: '✍️' },
  { id: 'music', label: 'Música & Audio', icon: '🎵' },
  { id: 'business', label: 'Negocios', icon: '💼' },
  { id: 'ai', label: 'Servicios con IA', icon: '🤖' },
];
