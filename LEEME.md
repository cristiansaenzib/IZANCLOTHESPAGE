# IZAN Clothes · Tienda con panel de administración

Archivos: `index.html` (tienda pública), `admin.html` (panel con login), `styles.css`, `shared.js`, `config.js`, `supabase.sql`.
Costo: Supabase y Netlify tienen plan gratuito suficiente para empezar. El dominio propio (.com / .co) es de pago.

## 1. Crear o reparar la base de datos (Supabase)
1. Abre Supabase → SQL Editor → New query.
2. Copia y ejecuta **una sola vez** el archivo `supabase.sql` completo. Es idempotente: si lo ejecutas otra vez, recrea las políticas administradas y agrega columnas faltantes sin borrar el contenido.
3. El esquema crea las tablas para categorías, productos, fotos, inventario, guías de tallas, campañas/ajustes, códigos mayoristas, cotizaciones y movimientos. La base queda vacía para comenzar a llenar desde Administración.
4. Crea el usuario administrador en Authentication → Users con el correo `saenz1098@gmail.com`, confirma el usuario y asigna una contraseña segura. Ese correo debe coincidir con las políticas SQL y con `ADMIN_EMAIL` de `admin.html`.
5. En Authentication → Sign In / Providers, desactiva los registros públicos si solo tú debes entrar al administrador.

**Si ya habías ejecutado SQL antiguos:** usa también `supabase.sql` completo como reparación idempotente. No ejecutes todas las migraciones históricas una por una después; la estructura actual ya está incluida. Haz una copia de seguridad si ya hay datos que debas conservar.

## 2. Conectar la página
1. En Supabase: **Project Settings → API**. Copia "Project URL" y la clave "anon public".
2. Pégalas en `config.js` (`SUPABASE_URL` y `SUPABASE_ANON_KEY`). La clave anon es pública por diseño; lo que protege tus datos son las políticas del SQL.

## 3. Publicar en internet
Opción rápida: https://app.netlify.com/drop → arrastra la carpeta completa. Te da una dirección pública al instante.
Alternativas: Vercel, Cloudflare Pages o GitHub Pages.

## 4. Entrar como administrador
Ve a `tu-sitio.com/admin.html` (o al enlace discreto "Administrar" del pie de la tienda), entra con tu correo y contraseña y gestiona categorías, diseños, fotos, precios, agotados y el destino de WhatsApp.
`admin.html` lleva `noindex`, así que Google no lo lista.

## 5. Aparecer en Google
1. Compra un dominio y conéctalo en tu hosting (Netlify → Domain management).
2. Regístralo en https://search.google.com/search-console y solicita la indexación de la página principal.
3. Crea o reclama tu ficha en Google Business Profile (tienda en C.C. Gran San) para aparecer en Google Maps.
La indexación puede tardar de días a semanas.

## Precios por cantidad

Reglas por defecto (se configuran en el admin → **0 · Reglas de precios por cantidad**):

| Pedido | Precio |
|---|---|
| 1 unidad | Detal |
| 2 unidades | 5% de descuento |
| 3 unidades | 10% de descuento |
| 4 o más unidades | 15% de descuento, hasta que aplique un precio de distribuidor o mayorista |
| 6 a 11 unidades, en mínimo 3 tallas diferentes | Precio distribuidor |
| 12 o más unidades, en 3 o 4 tallas diferentes | Precio mayorista |
| 12 o más unidades, en exactamente 2 tallas | Precio mayorista si cada talla tiene mínimo 3 unidades |

- Distribuidor y mayorista se evalúan sobre **todo el pedido**: pueden mezclarse diseños y categorías.
- El nivel mayorista reemplaza al distribuidor desde las 12 unidades, siempre que cumpla las condiciones mayoristas.
- Los descuentos de 2, 3 y 4 o más unidades se cuentan por referencia (todas las tallas del mismo diseño) o por pedido; se elige en las reglas.
- Cada producto tiene 3 precios: detal, distribuidor y mayorista (0 = no aplica ese nivel).
- Cada **categoría** define qué niveles usa por defecto; cada **producto** puede usar los de su categoría o elegir los suyos.
- Si un nivel no aplica al producto, se usa el mejor nivel disponible que sí cumpla; si ninguno, se cobra detal.

## Códigos de mayorista
En el admin → **4 · Códigos de mayorista** creas un código por cliente (🎲 Generar). El cliente lo escribe en el carrito (o en "¿Eres mayorista?") y todos sus productos pasan a precio mayorista sin condición de tallas. El mensaje de WhatsApp incluye el código para que lo verifiques. Puedes desactivarlo cuando quieras.

La estructura completa actual se encuentra en `supabase.sql`; las migraciones históricas se conservan como referencia, pero no hace falta ejecutarlas después de aplicar el esquema completo.


## Actualización: filtros por color y talla
1. En Supabase, abre **SQL Editor** y ejecuta el contenido de `migracion_colores.sql`.
2. Sube/reemplaza `index.html`, `admin.html` y `styles.css` junto con los demás archivos del sitio.
3. En `admin.html`, al crear o editar un producto, escribe su color en el campo **Color** (por ejemplo: Negro, Blanco, Verde oliva). El filtro de la tienda toma automáticamente los colores que estén guardados en los productos.
4. En el catálogo, el panel lateral permite filtrar por color y por talla con inventario disponible. El filtro de talla se puede desactivar pulsando de nuevo la talla seleccionada.
5. Se eliminó la información pública de precios por cantidad; queda únicamente el acceso **¿Eres mayorista? Ingresa tu código**. Las reglas de precios y descuentos del carrito siguen funcionando.


## Pedidos y cotizaciones
Para activar el apartado **Pedidos** en Administración, ejecuta `migracion_pedidos.sql` en Supabase → SQL Editor → Run. Las nuevas cotizaciones se guardan como pendientes; al marcar una como vendida se descuentan sus cantidades del inventario. Eliminar una cotización no modifica el inventario.


## Portada dinámica editable
En Administración encontrarás **Portada · campañas visuales**. Desde ahí puedes crear campañas con foto, título, descripción, botón y destino; editar, ocultar, activar o eliminar cada una. Las campañas activas se alternan automáticamente en la portada. Para que las fotos se vean en todos los dispositivos, configura Supabase y publica los archivos actualizados. En modo local, los cambios solo quedan guardados en ese navegador. Usa fotos horizontales de aproximadamente 1800 × 900 px y comprímelas para mantener la página rápida.


## Rediseño 2.0: administración por secciones y nuevo estilo visual
- **Administrar ahora tiene un menú lateral** (en celular es una barra deslizable) con una sección por tema: Resumen, Cotizaciones, Campañas, Categorías, Nuevo producto, Catálogo, Reglas de precios, Códigos mayorista y Ajustes. Se puede enlazar directo, por ejemplo `admin.html#pedidos`.
- Cotizaciones tiene filtros Pendientes / Vendidas / Todas y un contador de pendientes en el menú. El Catálogo tiene buscador y filtro por categoría.
- Estilos: `styles.css` (tienda y base compartida) y el nuevo `admin.css` (solo panel). Los colores y formas se cambian en las variables `--acc`, `--acc2`, `--acc3`, `--acc4` al inicio del bloque "IZAN 2.0" de `styles.css`.
- La barra negra superior de la tienda se edita en `index.html` (clase `announce`).
- Corrección: las imágenes de las campañas de portada ahora se resuelven correctamente desde el almacenamiento (Supabase o modo local).
- No hace falta ejecutar ninguna migración nueva: la base de datos no cambió.


## Paleta única (grises)
Toda la página (tienda y administración) usa solo: Gris antracita `#343339`, Gris lobo `#5a5b5d`, Gris Londres `#969799`, Gris perla `#b4b7bc` y Gris visón `#b8b0a5`, más blanco para tarjetas y texto sobre fondos oscuros. Se cambian en las variables del final de `styles.css` (bloque "PALETA ÚNICA"). Se quitó el modo oscuro automático y los emojis de color de los botones del panel.


## Carrito: panel lateral y pantalla completa
- Al pulsar **Añadir** en un diseño se abre un **panel lateral derecho** con el resumen del pedido; la página no cambia de vista.
- El botón **Carrito** de la parte superior (o **Ver carrito** dentro del panel) abre el carrito en **pantalla completa**, con el total, el código de mayorista y las ofertas por cantidad.
- Cada diseño aparece como **una sola tarjeta**: la foto a la izquierda y, a la derecha, una fila por talla (S, M, L, XL) con botones **− / +** y su cantidad, y abajo el **Total** de unidades del diseño. Los botones respetan el inventario disponible y **Quitar** elimina el diseño completo.
- En pantalla completa, los diseños se organizan hasta en tres columnas para resumir pedidos con muchas referencias.
- Solo se modificaron `index.html` y `styles.css`; no hace falta ninguna migración.


## Portada responsive con imagen independiente para celular
En Administración → Campañas puedes cargar una imagen horizontal para computador y otra vertical para celular. La tienda usa automáticamente la versión móvil en pantallas de hasta 700 px; si no cargas una imagen móvil, reutiliza la de computador. Al cambiar el tamaño de la ventana, la portada actualiza la imagen sin recargar.

Las cotizaciones PDF incluyen foto, nombre de cada diseño, tallas, cantidades, valores unitarios, subtotales y total. Para que las fotos se incorporen al PDF, usa imágenes servidas desde el almacenamiento configurado y evita enlaces externos que bloqueen la lectura desde el navegador.

## Actualización: datos de envío en las cotizaciones

La tienda ahora solicita antes de generar la cotización: nombre completo, cédula, celular, dirección, ciudad y correo electrónico. Estos datos aparecen en el PDF del cliente, en el mensaje de WhatsApp y en el apartado Cotizaciones del administrador, incluido el PDF descargable desde administración.

**Importante antes de publicar:** abre Supabase → SQL Editor, ejecuta `migracion_datos_envio.sql` y luego publica los archivos actualizados. La migración agrega las columnas necesarias a `public.orders`. Los registros antiguos seguirán mostrando guiones en los campos que no tengan datos.

## Actualización: guías de tallas
1. En Supabase → **SQL Editor** ejecuta **una vez** `migracion_guias_tallas.sql`.
2. Reemplaza `index.html`, `admin.html`, `shared.js`, `styles.css` y `admin.css`.
3. En `admin.html` → **Tienda → Guías de tallas** crea una guía por categoría (ej. "Camisetas oversized"): escribes las medidas de cada talla (XS a XXL; las que dejes vacías no se muestran) y puedes agregar o renombrar medidas (Ancho, Largo, Manga, Pecho…).
4. Al crear o editar un producto, elige su **Guía de tallas** en el desplegable. En la tienda, al pasar el mouse sobre el producto aparece el botón "Guía de tallas" con la ventana de medidas (en celular el botón se ve siempre).

## Herramientas de administración: inventario, CSV y reportes
La nueva sección **Sistema → Inventario y reportes** permite registrar entradas/salidas de stock con motivo, consultar los movimientos recientes, descargar inventario en CSV para editarlo en Excel, importar cambios a referencias existentes y exportar cotizaciones en CSV. También permite descargar una copia JSON de respaldo.

**Activar el historial en Supabase:** abre Supabase → SQL Editor y ejecuta una sola vez `migracion_inventario_historial.sql`. Usa el mismo correo administrador configurado en las políticas RLS del proyecto. Si cambiaste el correo de administrador, reemplaza `saenz1098@gmail.com` en esa migración antes de ejecutarla.

**Importación CSV:** primero descarga el CSV desde el panel; conserva la columna `id` sin cambios. Los campos numéricos deben ser enteros no negativos. Las celdas vacías se conservan sin cambios; la importación actualiza productos existentes y no crea ni elimina referencias. Revisa el catálogo después de importar. Para reducir riesgos, haz una copia JSON antes de cargas grandes.

**Historial:** registra los ajustes manuales hechos desde esta nueva sección. Los movimientos de ventas anteriores a activar el historial no se reconstruyen retroactivamente. Para una trazabilidad contable completa de ventas, el descuento de stock y el registro de movimiento deben ejecutarse dentro de una transacción del servidor; esta versión conserva el control manual y el historial de ajustes.

**Alertas y duplicación:** el resumen muestra referencias con inventario bajo (entre 1 y 3 unidades por talla) y el catálogo permite duplicar un producto como borrador agotado, con todas las existencias en cero, para evitar vender stock inexistente.


## Campañas: una imagen o tres imágenes

La portada se administra en **Administrar → Diseño de la tienda → Campañas**. Al crear o editar una campaña eliges su formato:

- **Una imagen**: foto grande (horizontal ~1800 × 900 px; opcional una vertical para celular) con texto superior, título, descripción y botón.
- **Tres imágenes**: tres fotos simétricas, del mismo ancho y alto, que juntas ocupan exactamente el mismo espacio que una campaña de una imagen. Cada una tiene su fotografía (vertical 4:5, ~1000 × 1250 px, producto centrado), título, descripción, botón, destino y, si quieres, una categoría que se abre al pulsar. En celular se apilan una debajo de otra, también del mismo tamaño.

Las campañas activas se alternan automáticamente (puedes mezclar de una y de tres imágenes) y los puntos numerados permiten cambiar de campaña. Se guardan en `settings` con la clave `hero_banners`; no requiere migración SQL. El alto de la campaña se ajusta en `styles.css`, variable `--campaign-h` (bloque "Campaña").

Si venías de la versión anterior con "Portada · 3 imágenes", en Campañas aparece el botón **Convertirla en campaña** que conserva tus fotos y textos. Mientras no haya campañas activas, la tienda sigue mostrando esa portada antigua.

## Color de fondo y pie de página editable

**Color de fondo.** En **Administrar → Diseño de la tienda → Contenido visual** hay tres paletas minimalistas: **Marfil** (blanco cálido, la de siempre), **Arena** (beige suave) y **Niebla** (gris azulado). La elegida cambia el fondo, las líneas y los tonos de texto de toda la tienda. Las paletas se definen en `shared.js` (`BG_PALETTES`); para agregar otra basta con sumar un bloque con sus seis colores.

**Pie de página.** El nuevo apartado **Pie de página** (mismo grupo del menú) tiene un campo para cada texto y una vista previa que se actualiza mientras escribes:
- Marca: frase destacada y descripción corta junto al logo.
- Tienda: título de la columna y varias líneas (la primera se resalta como dirección principal).
- Horario: filas con formato `Días | Horas`, que se muestran en dos columnas alineadas.
- Contacto (opcional): filas `Etiqueta | Dato`; los correos y teléfonos se vuelven enlaces solos.
- Redes: enlace y texto de Instagram y TikTok (solo se muestran las que tengan enlace), con opción de ocultar el usuario junto al ícono.
- Línea inferior: texto legal (`{año}` se actualiza solo), texto del enlace de la política de datos y enlace discreto "Administrar".
Cada columna se puede ocultar. Los textos del pie que ya tenías guardados se aprovechan automáticamente la primera vez. No requiere ninguna migración SQL.

## Menú con letras flotantes
La barra superior ya no tiene fondo ni recuadros: el logo y las opciones (Categorías, Best sellers, Últimas unidades, Lo más nuevo, Carrito, Pedido rápido) son texto que flota y se subraya al pasar el cursor. El color cambia solo: blanco cuando el menú pasa sobre la campaña y oscuro cuando pasa sobre el fondo claro (script al final de `index.html`, clase `on-light`; estilos en el bloque "Menú sin barra" de `styles.css`). En celular queda el texto "Menú" y, al abrirlo, las opciones salen en un panel oscuro.

## Foto frontal y trasera por producto
Cada camiseta puede tener dos fotos: **frontal** y **trasera**. En la tienda, al pasar el mouse sobre el producto la foto cambia sola a la trasera (con un desvanecido suave) y vuelve a la frontal al retirar el mouse. En celular y tablet (pantallas táctiles) se muestra siempre la frontal.

1. En Supabase → **SQL Editor** ejecuta **una vez** `migracion_foto_trasera.sql`.
2. Reemplaza `index.html`, `admin.html`, `shared.js`, `styles.css` y `admin.css`.
3. En Administrar → **Nuevo producto** hay un campo **Foto frontal** y otro **Foto trasera (opcional)**. En el **Catálogo**, cada producto tiene los botones **Foto frontal**, **+ Foto trasera** / **Cambiar trasera** y **Quitar trasera**; la trasera se ve como una miniatura sobre la foto del producto.
4. Los productos sin foto trasera siguen funcionando igual que antes. Si aún no ejecutas la migración, el panel lo avisa y oculta los controles de foto trasera.
5. Al duplicar un producto, la copia comparte las mismas fotos; ya no se borran del almacenamiento si otro producto todavía las usa.

## Ícono de administrador en el menú superior
El menú superior de la tienda termina con un **ícono de usuario** (sin texto; su etiqueta accesible es "Administrar") que lleva a `admin.html` (el panel sigue protegido por correo y contraseña). En celular aparece como última fila del panel que se abre con "Menú". Se edita en `index.html` (clase `nav-admin`) y `styles.css` (bloque "Botón Administrar"). El enlace discreto del pie de página sigue existiendo y se puede ocultar en Administrar → Pie de página.


## Precio de promoción
Cada producto tiene un campo opcional **Precio promoción (COP)**: en *Nuevo producto*, en el modal *Editar* y en la fila del *Catálogo* (junto a Detal, Distribuidor y Mayorista). `0` = sin promoción. Si el precio de promoción es menor al detal, el catálogo del index muestra el precio full tachado, el precio de promoción y la etiqueta **Promo −X%**. En el carrito, la promoción es el precio base: los descuentos por cantidad, distribuidor y mayorista solo se aplican si dan un precio todavía menor.

**Activar en Supabase:** ejecuta **una vez** `migracion_promocion.sql` (SQL Editor → Run) y luego reemplaza `index.html`, `admin.html`, `shared.js`, `styles.css` y `admin.css`. El CSV de inventario ahora incluye la columna `price_promo`.

## Probar el administrador en tu computador (sin Supabase)
Con `config.js` vacío (sin `SUPABASE_URL` ni `SUPABASE_ANON_KEY`), abre `admin.html` desde tu computador y el panel entra directo, con 3 productos de ejemplo (uno sin promoción). Lo mejor es usar un servidor local: en la carpeta del proyecto ejecuta `python3 -m http.server 8000` y abre `http://localhost:8000/admin.html` y `http://localhost:8000/index.html` (así tienda y panel comparten los mismos datos de prueba). Este acceso **solo funciona en localhost o abriendo el archivo directamente**; en el sitio publicado el panel sigue protegido por correo y contraseña. Los datos de prueba se guardan en el navegador y no tocan tu base de datos.


## Carga inicial de contenido
- Conecta `config.js` con la URL y la clave anon/public del proyecto Supabase.
- Entra a `admin.html` con el usuario administrador.
- Crea primero las categorías; después crea los productos y asígnales categoría, precio y existencias.
- Las fotos frontales y traseras se guardan en el bucket `products`. Usa archivos de imagen optimizados para web.
- Las secciones de campañas, contenido visual, pie de página, reglas y WhatsApp se guardan como claves de `settings`; no necesitan datos precargados.
- Las guías de tallas, códigos mayoristas y movimientos pueden quedar vacíos hasta que los necesites.
- La tienda no debe mostrar productos de ejemplo en producción: el modo de demostración local solo funciona en `localhost` o abriendo el archivo sin Supabase.

## Solución de errores de permisos
El correo de administrador debe ser idéntico en `admin.html` y en las políticas SQL (`saenz1098@gmail.com`). Si usas otro correo, cambia ambos lugares y vuelve a ejecutar `supabase.sql`. Nunca pongas una `service_role` key en `config.js`; solo la clave pública anon/publishable.
