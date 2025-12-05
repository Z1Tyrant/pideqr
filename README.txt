# PideQR - Sistema de Gestión de Pedidos por QR

**PideQR** es una aplicación móvil multiplataforma, construida con Flutter y Firebase, diseñada para modernizar y optimizar el flujo de pedidos en la industria gastronómica y de eventos.

El sistema permite a los clientes escanear un código QR en su mesa o ubicación para acceder instantáneamente al menú, realizar su pedido y pagarlo, todo desde su propio dispositivo. Esto reduce las filas, minimiza los errores en la toma de pedidos y mejora significativamente la experiencia del cliente.

---

## Características Principales

*   **Menú Digital:** Los clientes acceden a un menú interactivo y siempre actualizado.
*   **Pedidos Directos:** Los pedidos realizados por los clientes llegan directamente a la cocina o barra.
*   **Sistema de Roles:**
    *   **Cliente:** Realiza y sigue el estado de sus pedidos.
    *   **Vendedor:** Reclama y gestiona la preparación y entrega de pedidos.
    *   **Manager:** Gestiona su tienda, sus productos y a sus vendedores.
    *   **Admin:** Supervisa todo el sistema, gestiona tiendas y usuarios.
*   **Seguimiento en Tiempo Real:** Tanto el cliente como el personal pueden ver el estado de un pedido (`Pagado`, `En preparación`, `Listo para entrega`, `Entregado`).
*   **Notificaciones Push:** Los clientes reciben notificaciones automáticas cuando su pedido está listo para ser retirado.
*   **Gestión de Stock:** El stock de los productos se descuenta automáticamente con cada pedido.

---

## Stack Tecnológico

*   **Frontend:** Flutter
*   **Backend & Base de Datos:** Firebase (Firestore, Authentication, Storage, Cloud Functions)
*   **Gestión de Estado:** Flutter Riverpod
*   **Escaneo QR:** `mobile_scanner`
*   **Generación de QR:** `qr_flutter`

---

## Modelo de Negocio

La estrategia de monetización de PideQR se basa en un modelo híbrido diseñado para capturar valor tanto en mercados de clientes fijos como en eventos masivos.

1.  **Modelo de Suscripción (SaaS):** Un modelo freemium con planes escalonados (Gratis, Profesional, Empresarial) para restaurantes y locales fijos.
2.  **Modelo de Paquete por Evento:** Un paquete de servicio con tarifa fija para los organizadores de festivales, conciertos y eventos deportivos.

> Para un análisis detallado de la estrategia, los planes y el roadmap de implementación, consulta el documento [**ESTRATEGIA_DE_NEGOCIO.md**](ESTRATEGIA_DE_NEGOCIO.md).

---

## Roadmap de Desarrollo

*   **Fase 1 (Corto Plazo):** Consolidar el producto SaaS. Implementar en el código las limitaciones del plan gratuito y habilitar la contratación del plan profesional.
*   **Fase 2 (Largo Plazo):** Desarrollar el "Modo Evento", incluyendo el rol de `organizador_evento` y la gestión de vendedores temporales.
*   **Futuro (V2.0):** Explorar la implementación de un mapa de descubrimiento para que los clientes puedan encontrar locales afiliados a PideQR en su área.
