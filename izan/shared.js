const C = window.CONFIG;
const SZ = ['S', 'M', 'L', 'XL', 'XXL'];
const $ = s => document.querySelector(s);
const fmt = n => new Intl.NumberFormat('es-CO', { style: 'currency', currency: 'COP', maximumFractionDigits: 0 }).format(n || 0);
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const SHIRT = 'data:image/svg+xml,' + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 500"><rect width="400" height="500" fill="#b4b7bc"/><path d="M135 90l-85 40 22 80 40-14v184h176V196l40 14 22-80-85-40c-8 24-30 36-65 36s-57-12-65-36z" fill="#343339"/></svg>');

/* ===== MODO LOCAL: si config.js no tiene credenciales de Supabase, todo se guarda en este navegador ===== */
const LOCAL = !(C.SUPABASE_URL && C.SUPABASE_ANON_KEY && window.supabase);
function makeLocalClient() {
  const K = 'izan_local_';
  const read = t => { try { return JSON.parse(localStorage.getItem(K + t)) || []; } catch (e) { return []; } };
  const write = (t, v) => localStorage.setItem(K + t, JSON.stringify(v));
  const uid = () => (crypto.randomUUID ? crypto.randomUUID() : Date.now().toString(36) + Math.random().toString(36).slice(2));
  const defs = t => t === 'products' ? { description: '', image_path: null, image_path_back: null, price: 0, price_promo: 0, price_dist: 0, price_mayor: 0, tiers: null, stock_s: 0, stock_m: 0, stock_l: 0, stock_xl: 0, stock_xxl: 0, sold_out: false } : {};
  const toDataURL = b => new Promise((res, rej) => { const r = new FileReader(); r.onload = () => res(r.result); r.onerror = rej; r.readAsDataURL(b); });

  function from(table) {
    let op = 'select', payload = null, filters = [], ord = null;
    const q = {
      select() { return q; }, insert(v) { op = 'insert'; payload = v; return q; }, update(v) { op = 'update'; payload = v; return q; },
      upsert(v) { op = 'upsert'; payload = v; return q; }, delete() { op = 'delete'; return q; },
      eq(c, v) { filters.push([c, v]); return q; },
      order(col, o) { ord = { col, asc: !(o && o.ascending === false) }; return q; },
      then(res, rej) { return run().then(res, rej); }
    };
    async function run() {
      try {
        const rows = read(table), m = r => filters.every(([c, v]) => r[c] == v);
        if (op === 'select') {
          const out = rows.filter(m);
          if (ord) out.sort((a, b) => (a[ord.col] > b[ord.col] ? 1 : a[ord.col] < b[ord.col] ? -1 : 0) * (ord.asc ? 1 : -1));
          return { data: out, error: null };
        }
        if (op === 'insert') {
          if (table === 'wholesale_codes' && rows.some(r => String(r.code).toUpperCase() === String(payload.code).toUpperCase())) return { data: null, error: { message: 'duplicate key: unique' } };
          const list = [].concat(payload).map(r => ({ id: uid(), created_at: new Date().toISOString(), ...defs(table), ...r }));
          write(table, rows.concat(list)); return { data: list, error: null };
        }
        if (op === 'update') { write(table, rows.map(r => m(r) ? { ...r, ...payload } : r)); return { data: null, error: null }; }
        if (op === 'upsert') {
          const i = rows.findIndex(r => r.key === payload.key);
          i >= 0 ? rows[i] = { ...rows[i], ...payload } : rows.push(payload);
          write(table, rows); return { data: null, error: null };
        }
        if (op === 'delete') {
          write(table, rows.filter(r => !m(r)));
          if (table === 'categories') filters.forEach(([c, v]) => { if (c === 'id') write('products', read('products').filter(p => p.category_id != v)); });
          return { data: null, error: null };
        }
      } catch (e) { return { data: null, error: { message: 'Almacenamiento local lleno o no disponible. Exporta una copia y borra fotos pesadas.' } }; }
    }
    return q;
  }
  return {
    from,
    rpc: async (fn, a) => {
      const r = read('wholesale_codes').find(x => x.active && String(x.code).toUpperCase() === String((a && a.p_code) || '').trim().toUpperCase());
      return { data: r ? (r.client_name || 'Mayorista') : null, error: null };
    },
    auth: {
      getSession: async () => ({ data: { session: { user: { email: 'local' } } } }),
      signInWithPassword: async () => ({ error: null }),
      signOut: async () => ({}),
      onAuthStateChange: () => ({ data: { subscription: { unsubscribe() {} } } })
    },
    storage: { from: () => ({
      async upload(path, blob) {
        try { localStorage.setItem(K + 'img_' + path, await toDataURL(blob)); return { error: null }; }
        catch (e) { return { error: { message: 'No hay espacio local para más fotos (límite ~5 MB del navegador).' } }; }
      },
      async remove(paths) { paths.forEach(p => localStorage.removeItem(K + 'img_' + p)); return { error: null }; },
      getPublicUrl: path => ({ data: { publicUrl: localStorage.getItem(K + 'img_' + path) || SHIRT } })
    }) }
  };
}
function localExport() { const o = {}; for (let i = 0; i < localStorage.length; i++) { const k = localStorage.key(i); if (k.startsWith('izan_local_')) o[k] = localStorage.getItem(k); } return o; }
function localImport(o) {
  Object.keys(localStorage).filter(k => k.startsWith('izan_local_')).forEach(k => localStorage.removeItem(k));
  Object.keys(o).forEach(k => { if (k.startsWith('izan_local_')) localStorage.setItem(k, o[k]); });
}
const sb = LOCAL ? makeLocalClient() : window.supabase.createClient(C.SUPABASE_URL, C.SUPABASE_ANON_KEY);
const imgUrl = path => path ? sb.storage.from('products').getPublicUrl(path).data.publicUrl : SHIRT;
/* Precio base = precio al detal. (Si el producto es antiguo y solo tiene price_140/180/220, usa el que tenga valor.) */
const price = p => +p.price || +p.price_220 || +p.price_180 || +p.price_140 || 0;
/* Promoción: price_promo > 0 y menor al precio full => se vende y se muestra a ese precio. */
const onPromo = p => (+p.price_promo || 0) > 0 && (+p.price_promo) < price(p);
const eff = p => onPromo(p) ? +p.price_promo : price(p);
const promoPct = p => onPromo(p) ? Math.round((1 - eff(p) / price(p)) * 100) : 0;

/* ===== PRECIOS POR CANTIDAD =====
   Los descuentos porcentuales se cuentan por referencia o por pedido según la configuración.
   Distribuidor: de 6 a 11 unidades y mínimo 3 tallas diferentes.
   Mayorista: desde 12 unidades; con 3 o 4 tallas aplica directamente. Si solo lleva 2 tallas,
   cada talla debe tener al menos 3 unidades. Las reglas se evalúan sobre el pedido completo.
   Código de mayorista: precio mayorista sin condición de tallas. */
const DEF_TIERS = [
  { key: 'd2', name: 'Descuento', min: 2, kind: 'pct', pct: 5 },
  { key: 'd3', name: 'Descuento', min: 3, kind: 'pct', pct: 10 },
  { key: 'd4', name: 'Descuento', min: 4, kind: 'pct', pct: 15 },
  { key: 'dist', name: 'Distribuidor', kind: 'price', field: 'price_dist', total: 6, sizes: 3, flex: 2 },
  { key: 'may', name: 'Mayorista', kind: 'price', field: 'price_mayor', total: 12, sizes: 2, flex: 2 }
];
const clampSz = (v, d) => Math.min(SZ.length, Math.max(1, parseInt(v) || d));
const fixMin = t => { if (t.kind === 'price') t.min = t.total; return t; };   /* min = unidades totales mínimas */
function parseTiers(rows) {
  const out = DEF_TIERS.map(t => fixMin({ ...t }));
  try {
    const r = (rows || []).find(x => x.key === 'rules'), saved = JSON.parse(r && r.value);
    saved.forEach(x => {
      let t = out.find(o => o.key === x.key);
      if (!t && x && /^custom_[a-z0-9_]+$/.test(String(x.key || '')) && x.kind === 'pct') { t = { key: x.key, name: String(x.name || 'Regla personalizada').slice(0, 60), kind: 'pct', min: 2, pct: 0 }; out.push(t); }
      if (!t) return;
      if (t.kind === 'pct') { t.name = String(x.name || t.name || 'Descuento').slice(0, 60); t.min = Math.max(2, parseInt(x.min) || t.min); t.pct = Math.min(90, Math.max(0, +x.pct || 0)); }
      else { t.total = Math.max(1, parseInt(x.total) || t.total); t.sizes = clampSz(x.sizes, t.sizes); t.flex = clampSz(x.flex, t.flex); fixMin(t); }
    });
  } catch (e) {}
  const gone = parseDeletedRules(rows);
  return out.filter(t => !(t.kind === 'pct' && gone.includes(t.key)));
}
/* Reglas por defecto (d2, d3, d4) que el administrador eliminó: se guardan en settings.rules_deleted. */
const parseDeletedRules = rows => { try { const r = (rows || []).find(x => x.key === 'rules_deleted'), a = JSON.parse(r && r.value); return Array.isArray(a) ? a.map(String) : []; } catch (e) { return []; } };
const parseCountMode = rows => { const r = (rows || []).find(x => x.key === 'count_mode'); return r && r.value === 'order' ? 'order' : 'ref'; };
const parseKeys = v => { if (v == null || v === '') return null; try { const a = Array.isArray(v) ? v : JSON.parse(v); return Array.isArray(a) ? a : null; } catch (e) { return null; } };
/* Niveles que usa un producto: los suyos; si no tiene, los de su categoría; si tampoco, todos. */
const tierKeys = (p, cat, tiers) => parseKeys(p.tiers) || parseKeys(cat && cat.tiers) || tiers.map(t => t.key);
const tierUnit = (p, t) => { const b = eff(p); return t.kind === 'pct' ? Math.round(b * (1 - t.pct / 100)) : (+p[t.field] || 0); };
const tierUsable = (p, t, keys) => keys.includes(t.key) && (t.kind === 'pct' ? t.pct > 0 : +p[t.field] > 0) && tierUnit(p, t) < eff(p);

/* ctx = { sz: {S:n, M:n, L:n, XL:n} unidades por talla de TODO el pedido, code: true si hay código de mayorista } */
const orderTotal = ctx => SZ.reduce((a, z) => a + ((ctx && ctx.sz && ctx.sz[z]) || 0), 0);
/* ¿Cumple un nivel por tallas? cnt = unidades por talla [S,M,L,XL] */
function qualCounts(t, cnt) {
  const tot = cnt.reduce((a, n) => a + n, 0);
  const present = cnt.filter(n => n > 0);
  const mayTier = t.key === 'may';
  const distTier = t.key === 'dist';

  if (distTier) {
    // Distribuidor solo entre 6 y 11 unidades, surtido en al menos 3 tallas.
    const upper = ((typeof tiers !== 'undefined' ? tiers : DEF_TIERS).find(x => x.key === 'may') || { total: 12 }).total;
    return tot >= t.total && tot < upper && present.length >= 3;
  }
  if (mayTier) {
    if (tot < t.total) return false;
    // Con 3 o 4 tallas entra directamente; con 2, mínimo 3 unidades por talla.
    return present.length >= 3 || (present.length === 2 && Math.min(...present) >= 3);
  }

  // Compatibilidad para futuros niveles de precio personalizados.
  if (tot < t.total) return false;
  if (tot > t.total && present.length >= t.flex) return true;
  for (let k = t.sizes; k <= SZ.length; k++) {
    const need = Math.max(1, Math.floor(t.total / k));
    if (cnt.filter(n => n >= need).length >= k) return true;
  }
  return false;
}
const countsOf = ctx => SZ.map(z => (ctx && ctx.sz && ctx.sz[z]) || 0);
const qualifies = (t, ctx) => qualCounts(t, countsOf(ctx));
const tierActive = (t, q, ctx) => t.kind === 'pct' ? q >= t.min : qualifies(t, ctx);
/* Mínimo de unidades que faltan (en las tallas que convenga) para cumplir un nivel por tallas */
function deficit(t, ctx) {
  ctx._d = ctx._d || {}; if (t.key in ctx._d) return ctx._d[t.key];
  const base = countsOf(ctx); let res = 0;
  const rec = (i, left, cur) => { if (i == SZ.length - 1) return qualCounts(t, [...cur, base[i] + left]); for (let x = 0; x <= left; x++) if (rec(i + 1, left - x, [...cur, base[i] + x])) return true; return false; };
  for (let add = 1; add <= 30 && !res; add++) if (rec(0, add, [])) res = add;
  return ctx._d[t.key] = res || 30;
}
/* ALGORITMO: q = unidades de ese producto (o del pedido, según la configuración) para los descuentos %.
   1) Con código de mayorista y el producto ofrece precio mayorista => ese precio.
   2) Si no: de los niveles que el producto usa y que se cumplen, gana el de menor precio. Si ninguno => detal. */
function applied(p, cat, tiers, q, ctx) {
  const keys = tierKeys(p, cat, tiers);
  if (ctx && ctx.code) { const m = tiers.find(t => t.key === 'may'); if (m && tierUsable(p, m, keys)) return { unit: tierUnit(p, m), tier: m, code: true }; }
  let best = { unit: eff(p), tier: null };
  tiers.forEach(t => { if (tierActive(t, q, ctx) && tierUsable(p, t, keys)) { const u = tierUnit(p, t); if (u < best.unit) best = { unit: u, tier: t }; } });
  return best;
}
/* Siguiente mejora de precio: { tier, need (unidades que faltan), unit } o null */
function nextOffer(p, cat, tiers, q, ctx) {
  const keys = tierKeys(p, cat, tiers), cur = applied(p, cat, tiers, q, ctx).unit;
  return tiers.filter(t => tierUsable(p, t, keys) && tierUnit(p, t) < cur && !tierActive(t, q, ctx))
    .map(t => ({ tier: t, need: t.kind === 'pct' ? t.min - q : deficit(t, ctx), unit: tierUnit(p, t) }))
    .filter(o => o.need > 0).sort((a, b) => a.need - b.need)[0] || null;
}
const tierLabel = t => !t ? 'Detal' : t.kind === 'pct' ? t.pct + '% dto.' : t.name;
/* Texto de rango para los niveles %: "2", "4 a 5", "12+" según los mínimos ordenados */
function tierRange(tiers, t) {
  const m = tiers.map(x => x.min).sort((a, b) => a - b), nx = m.find(x => x > t.min);
  return nx ? (nx - 1 > t.min ? `${t.min} a ${nx - 1}` : `${t.min}`) : `${t.min}+`;
}
const tierReq = (tiers, t) => {
  if (t.kind === 'pct') return `${tierRange(tiers, t)} unidades`;
  if (t.key === 'dist') {
    const may = tiers.find(x => x.key === 'may');
    return `${t.total} a ${Math.max(t.total, (may ? may.total : 12) - 1)} unidades · mínimo 3 tallas diferentes`;
  }
  if (t.key === 'may') return `Desde ${t.total} unidades · 3 o 4 tallas, o 2 tallas con mínimo 3 unidades de cada una`;
  const pats = []; for (let k = t.sizes; k <= SZ.length; k++) pats.push(`${k} tallas con mín. ${Math.max(1, Math.floor(t.total / k))} c/u`);
  return `${t.total} unidades surtidas: ${pats.join(' o ')} · desde ${t.total + 1} unidades basta con ${t.flex} tallas`;
};
const stock = (p, z) => Math.max(0, parseInt(p['stock_' + z.toLowerCase()]) || 0);
const sizes = p => { const c = (typeof cats !== 'undefined' ? cats : []).find(x => String(x.id) === String(p.category_id)); let allowed = []; try { allowed = Array.isArray(c?.sizes) ? c.sizes : JSON.parse(c?.sizes || '[]'); } catch(e) {} if (!allowed.length) allowed = ['S','M','L','XL']; return SZ.filter(z => allowed.includes(z)); };

/* ===== GUÍAS DE TALLAS ===== */
const GSZ = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
function parseGuide(g) {
  let cols = [], rows = {};
  try { cols = JSON.parse(g.measures); } catch (e) {}
  try { rows = JSON.parse(g.sizes); } catch (e) {}
  return { id: g.id, name: g.name || '', note: g.note || '', cols: Array.isArray(cols) ? cols : [], rows: rows && typeof rows === 'object' ? rows : {} };
}

/* ===== Paletas de fondo minimalistas (se eligen en Administrar → Contenido visual) ===== */
const BG_PALETTES = {
  marfil: { name: 'Marfil', desc: 'Blanco cálido, limpio y luminoso.', bg: '#f7f7f4', card: '#ffffff', ink: '#171717', mute: '#696969', line: '#deded9', chip: '#e9e9e4' },
  arena:  { name: 'Arena',  desc: 'Beige suave, cálido y elegante.',   bg: '#efebe4', card: '#faf8f4', ink: '#1f1c18', mute: '#6f675c', line: '#d9d2c6', chip: '#e4ded3' },
  niebla: { name: 'Niebla', desc: 'Gris azulado, sobrio y moderno.',   bg: '#eceeef', card: '#fafbfb', ink: '#17191b', mute: '#61676c', line: '#d3d7da', chip: '#dfe3e5' }
};
const DEFAULT_PALETTE = 'marfil';
function applyPalette(key) {
  const p = BG_PALETTES[key] || BG_PALETTES[DEFAULT_PALETTE], root = document.documentElement;
  const vars = { '--bg': p.bg, '--card': p.card, '--ink': p.ink, '--mute': p.mute, '--line': p.line, '--chip': p.chip };
  Object.keys(vars).forEach(n => root.style.setProperty(n, vars[n]));
  try { localStorage.setItem('izan_palette_css', Object.keys(vars).map(n => n + ':' + vars[n]).join(';')); } catch (e) {}
}

/* ===== Pie de página editable (misma plantilla en la tienda y en la vista previa del admin) ===== */
const DEFAULT_FOOTER = {
  slogan: 'Hecho en Colombia.', tagline: 'Ropa oversized, boxy fit y acid wash hecha en Bogotá.',
  show_store: true, store_title: 'Tienda', store_lines: 'Bogotá\nC.C. Punto Once | 5018',
  show_hours: true, hours_title: 'Horario', hours: 'Lun–Sáb | 9am–5pm\nDom y festivos | 10am–3pm',
  show_contact: false, contact_title: 'Contacto', contact_lines: 'WhatsApp | +57 300 000 0000\nCorreo | hola@izanclothes.com',
  social_title: 'Síguenos', instagram_label: '@izan_clothes', instagram_url: 'https://www.instagram.com/izan_clothes/',
  tiktok_label: '@izanclothes', tiktok_url: 'https://www.tiktok.com/@izanclothes', show_handles: true,
  legal: '© {año} IZAN Clothes. Todos los derechos reservados.', policy_text: 'Política de tratamiento de datos personales', show_admin: true
};
/* Si aún no hay pie guardado, se aprovechan los textos de la versión anterior. */
function parseFooter(vc) {
  vc = vc || {}; const f = vc.footer && typeof vc.footer === 'object' ? vc.footer : null, legacy = {};
  if (!f) {
    if (vc.footer_slogan) legacy.slogan = vc.footer_slogan;
    if (vc.store_location) legacy.store_lines = vc.store_location;
    if (vc.store_hours) legacy.hours = String(vc.store_hours).split(/\n+/).map(l => l.includes('|') ? l : l.replace(/^(.*?)\s+(\d{1,2}(?::\d{2})?\s?(?:am|pm).*)$/i, '$1 | $2')).join('\n');
    if (vc.instagram_label) legacy.instagram_label = vc.instagram_label;
    if (vc.instagram_url) legacy.instagram_url = vc.instagram_url;
  }
  return { ...DEFAULT_FOOTER, ...legacy, ...(f || {}) };
}
function footerHTML(f, o = {}) {
  const lines = s => String(s || '').split(/\n+/).map(x => x.trim()).filter(Boolean);
  const httpsOnly = u => /^https:\/\//i.test(u || '') ? u : '';
  const noNav = o.preview ? ' onclick="return false"' : '';
  const linkify = v => {
    if (/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v)) return `<a href="mailto:${esc(v)}"${noNav}>${esc(v)}</a>`;
    if (/^\+?[\d\s().-]{7,}$/.test(v)) return `<a href="tel:${esc(v.replace(/[^\d+]/g, ''))}"${noNav}>${esc(v)}</a>`;
    if (httpsOnly(v)) return `<a href="${esc(v)}" target="_blank" rel="noopener noreferrer"${noNav}>${esc(v.replace(/^https:\/\//i, ''))}</a>`;
    return esc(v);
  };
  const col = (title, body) => `<div class="foot-col"><h4>${esc(title)}</h4>${body}</div>`;
  const store = lines(f.store_lines);
  const hours = lines(f.hours);
  const contact = lines(f.contact_lines);
  const ig = httpsOnly(f.instagram_url), tt = httpsOnly(f.tiktok_url);
  const igSvg = '<svg viewBox="0 0 24 24" aria-hidden="true" focusable="false"><rect x="3" y="3" width="18" height="18" rx="5" fill="none" stroke="currentColor" stroke-width="2"/><circle cx="12" cy="12" r="4" fill="none" stroke="currentColor" stroke-width="2"/><circle cx="17.5" cy="6.5" r="1.25" fill="currentColor"/></svg>';
  const ttSvg = '<svg viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path fill="currentColor" d="M19.6 7.1a6.7 6.7 0 0 1-4.2-1.5v8.1a6.1 6.1 0 1 1-5.3-6.05v3.25a2.9 2.9 0 1 0 2.1 2.8V2.5h3.2c.2 2 1.8 3.8 4.2 4.1z"/></svg>';
  const social = (url, svg, name, label, cls) => url ? `<a class="foot-social" href="${esc(url)}" target="_blank" rel="noopener noreferrer" aria-label="Abrir ${name} de IZAN Clothes" title="${name}"${noNav}><span class="social-icon ${cls}">${svg}</span>${f.show_handles && label ? `<span class="foot-handle">${esc(label)}</span>` : ''}</a>` : '';
  const socials = social(ig, igSvg, 'Instagram', f.instagram_label, 'instagram-icon') + social(tt, ttSvg, 'TikTok', f.tiktok_label, 'tiktok-icon');
  const legal = String(f.legal || '').replace(/\{año\}/g, new Date().getFullYear());
  const policy = f.policy_text ? `<a href="politica-tratamiento-datos.html" target="_blank" rel="noopener"${noNav}>${esc(f.policy_text)}</a>` : '';
  const adm = f.show_admin ? `<a class="adm" href="admin.html"${noNav}>Administrar</a>` : '';
  return `<div class="in">
    <div class="foot-brand"><a class="footer-logo" href="#"${o.preview ? ' onclick="return false"' : ' onclick="return goTop(event)"'} aria-label="IZAN Clothes · volver al inicio"><img src="img/logo-izan-blanco.png" alt="IZAN Clothes" width="374" height="158"></a>${f.slogan ? `<p class="foot-slogan">${esc(f.slogan)}</p>` : ''}${f.tagline ? `<p class="foot-tagline">${esc(f.tagline)}</p>` : ''}</div>
    ${f.show_store && store.length ? col(f.store_title, store.map((l, i) => `<p class="${i ? 'foot-line' : 'foot-main'}">${esc(l)}</p>`).join('')) : ''}
    ${f.show_hours && hours.length ? col(f.hours_title, `<dl class="foot-hours">${hours.map(l => { const i = l.indexOf('|'); return i < 0 ? `<div class="solo"><dt>${esc(l)}</dt></div>` : `<div><dt>${esc(l.slice(0, i).trim())}</dt><dd>${esc(l.slice(i + 1).trim())}</dd></div>`; }).join('')}</dl>`) : ''}
    ${f.show_contact && contact.length ? col(f.contact_title, contact.map(l => { const i = l.indexOf('|'); return i < 0 ? `<p class="foot-line">${linkify(l)}</p>` : `<p class="foot-contact"><span>${esc(l.slice(0, i).trim())}</span>${linkify(l.slice(i + 1).trim())}</p>`; }).join('')) : ''}
    ${socials ? col(f.social_title, `<div class="foot-socials">${socials}</div>`) : ''}
  </div>
  <div class="foot-bottom"><span>${esc(legal)}</span><span class="foot-links">${policy}${adm}</span></div>`;
}
