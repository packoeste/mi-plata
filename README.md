# 💸 Mi Plata — control diario de gastos e ingresos

> **Proyecto personal y aparte.** No tiene relación con la web de Pack Oeste (`pack-oeste-web`); es una app independiente.

App web para controlar la plata del día a día:

- La ganancia por día se suma sola cada día trabajado (con historial de aumentos).
- Ingresos extra (horas extra, changas, propinas…) y gastos por categoría.
- Disponible hoy, resumen por mes, gastos por categoría y proyección a fin de mes.
- Se instala en Android como app (Chrome → ⋮ → *Agregar a pantalla principal*) y funciona sin internet.

**Web:** https://packoeste.github.io/mi-plata/

## Dónde están los datos

Este repositorio es **público** pero solo tiene el código de la página: **no contiene ningún dato**.
Los movimientos se guardan en cada dispositivo y, si se conecta la sincronización,
en el archivo `data.json` del repositorio **privado** `mi-plata-datos`, que es un archivo aparte.
Cada dispositivo se conecta con su propio token de GitHub con acceso solo a ese repositorio.
