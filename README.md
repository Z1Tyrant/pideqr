# PideQR - Gestión de Pedidos para Eventos Masivos

**PideQR Concerts** es una solución móvil multiplataforma (MVP), construida con Flutter y Firebase, diseñada para optimizar el flujo de pedidos y pagos en entornos de alta concurrencia como festivales y conciertos.

El sistema permite a los asistentes escanear códigos QR para acceder al menú y realizar pedidos sin filas, mejorando la experiencia del usuario y la gestión de los locatarios.

---

## Características del MVP (Fase Actual)

* **Menú Digital en Tiempo Real:** Actualización instantánea de disponibilidad de productos.
* **Pedidos QR:** Flujo optimizado de escaneo, selección y pedido.
* **Roles Definidos:**
    * **Asistente (Cliente):** Realiza pedidos y monitorea el estado (`Pendiente` -> `Listo`).
    * **Locatario (Vendedor):** Visualiza pedidos entrantes y gestiona el despacho.
* **Simulación de Pagos (Sandbox):** Validación segura de flujo transaccional.
* **Gestión de Stock:** Control básico de inventario por sesión.

---

## Stack Tecnológico

* **Frontend:** Flutter (Mobile)
* **Backend:** Firebase (Firestore, Auth, Functions)
* **Estado:** Riverpod
* **Arquitectura:** Cliente-Servidor (Serverless)

---

## Roadmap y Evolución

* **Fase 1 (Completada):** MVP funcional para Eventos (PideQR Concerts). Validación de flujo Pedido-Pago-Retiro.
* **Fase 2 (Próximamente):** Expansión a modelo SaaS para restaurantes fijos y roles administrativos avanzados (Manager/SuperAdmin).
* **Futuro (V2.0):** Mapa de descubrimiento de eventos y analítica avanzada de ventas.
