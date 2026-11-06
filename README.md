# 💸 Mi Plata — control diario de gastos e ingresos

> **Proyecto personal y aparte.** No tiene relación con la web de Pack Oeste (`pack-oeste-web`); es una app independiente.

App web para controlar la plata del día a día:

- La ganancia por día se suma sola cada día trabajado (con historial de aumentos).
- Ingresos extra (horas extra, changas, propinas…) y gastos por categoría.
- Disponible hoy, resumen por mes, gastos por categoría y proyección a fin de mes.
- Se instala en Android como app (Chrome → ⋮ → *Agregar a pantalla principal*) y funciona sin internet.

**Web:** https://packoeste.github.io/mi-plata/

## Contraseña y datos

- Se entra con **una sola contraseña**, la misma en el celular y en la Mac. La primera vez que se abre la web, se elige.
- Los datos se guardan en una base de datos propia (proyecto Supabase `mi-plata`, **aparte** del de Pack Oeste),
  así que se ven iguales en todos los dispositivos.
- Este repositorio es público pero solo tiene el código de la página: **no contiene ningún dato**.
  La contraseña se guarda encriptada y sin ella no se puede leer ni escribir nada.
- La estructura de la base está en [`supabase/esquema.sql`](supabase/esquema.sql).
