# Estrategia de Monetización para PideQR

## 1. Visión General

PideQR tiene el potencial de servir a dos mercados distintos con necesidades diferentes: **negocios fijos** (restaurantes, cafeterías) y **eventos masivos** (festivales, estadios). Un único modelo de monetización no es eficiente para ambos.

Por ello, proponemos una **estrategia híbrida** que maximiza el potencial de ingresos y la captación de clientes en cada segmento:

1.  **Modelo de Suscripción (SaaS):** Para clientes permanentes con un flujo de negocio constante.
2.  **Modelo de Paquete por Evento:** Para clientes esporádicos con un altísimo volumen de transacciones en un corto período de tiempo.

---

## 2. Modelo 1: Suscripción Mensual (SaaS) para Negocios Fijos

Este es el pilar de nuestro negocio, enfocado en la estabilidad y el crecimiento predecible.

*   **Mercado Objetivo:** Restaurantes, bares, cafeterías, hoteles y cualquier local con servicio de comida y bebida recurrente.
*   **Propuesta de Valor:** Ofrecemos una herramienta para optimizar sus operaciones, reducir costos de personal y mejorar la experiencia del cliente final, todo por un precio fijo y predecible.

### Estructura de Planes (Modelo Freemium)

#### **Plan Básico (Gratis)**
*   **Objetivo:** Eliminar la barrera de entrada. Es nuestra principal herramienta de marketing y adquisición.
*   **Características:**
    *   1 Tienda
    *   Funcionalidad completa de menú y pedidos por QR.
*   **Limitaciones:**
    *   Hasta **50 pedidos** al mes.
    *   Hasta **20 productos** en el menú.
    *   Sin roles avanzados (Manager, Vendedor).
*   **Mensaje Clave:** "Digitaliza tu operación y tus primeros 50 pedidos del mes, gratis para siempre."

#### **Plan Profesional (Pago Mensual)**
*   **Objetivo:** Nuestro producto principal. Dirigido a negocios que ya validaron el valor del sistema.
*   **Precio Sugerido:** **$19.990 CLP + IVA mensuales** (aprox. 0.5 - 0.7 UF).
*   **Características:**
    *   Todo lo del Plan Básico.
    *   Pedidos y productos **ilimitados**.
    *   Gestión de roles: **Administrador, Manager y Vendedor**.
    *   Acceso a estadísticas de venta (futura funcionalidad).
    *   Soporte prioritario.

#### **Plan Empresarial (Contacto)**
*   **Objetivo:** Cadenas de restaurantes o negocios con necesidades a medida.
*   **Precio:** Personalizado según requerimientos.
*   **Características:** Gestión multi-sucursal, integraciones personalizadas (ERP, sistemas de facturación), soporte dedicado.

### ¿Por qué el Modelo SaaS?
*   **Ingresos Predecibles:** Facilita la planificación financiera del negocio.
*   **Simplicidad Técnica y Legal:** **No procesamos el dinero de las ventas de nuestros clientes.** Ellos usan sus propias pasarelas de pago. Nuestra responsabilidad se limita a que el software funcione.
*   **Escalabilidad:** Es fácil de gestionar y automatizar a medida que crece la base de clientes.

---

## 3. Modelo 2: Paquete por Evento para Mercados Masivos

Este modelo ataca un nicho muy lucrativo donde el modelo de suscripción no es viable.

*   **Mercado Objetivo:** Productoras de eventos, clubes deportivos, organizadores de festivales musicales y ferias gastronómicas.
*   **Propuesta de Valor:** Somos un socio tecnológico que ofrece una solución "llave en mano" para eliminar las filas, mejorar la experiencia de los asistentes y aumentar el consumo durante el evento.

### ¿Cómo Funciona?
El cliente no es el food truck, sino el **organizador del evento**.

1.  **Venta del Paquete:** Se cobra una **tarifa fija y por adelantado** al organizador. Ejemplo: "$500.000 por habilitar el sistema para 20 puestos durante 2 días".
2.  **Cuenta Maestra del Evento:** El organizador recibe una cuenta especial (`organizador_evento`) en la plataforma.
3.  **Gestión de Vendedores Temporales:** Desde su panel, el organizador puede crear y asignar cuentas temporales a cada uno de los puestos de comida.
4.  **Operación:** Durante el evento, los puestos operan con normalidad. El dinero de sus ventas fluye directamente a sus propias cuentas, **PideQR no interviene en las transacciones**.
5.  **Post-Evento:** Se entregan estadísticas valiosas al organizador (producto más vendido, horas peak, etc.) y las cuentas temporales se desactivan.

### ¿Por qué el Modelo de Paquete por Evento?
*   **Alta Rentabilidad:** Un solo evento puede generar ingresos significativos y predecibles.
*   **Seguridad Máxima:** Al no procesar pagos de terceros, evitamos una complejidad legal, financiera y técnica enorme. El riesgo es bajísimo.
*   **Propuesta de Valor Clara para el Organizador:** Le vendemos eficiencia, datos y una mejor experiencia para sus asistentes, lo que justifica una tarifa premium.

---

## 4. Estrategia de Implementación (Roadmap Sugerido)

Proponemos un desarrollo por fases para asegurar una base sólida antes de expandir.

*   **Fase 1 (Corto Plazo - Producto Mínimo Viable SaaS):**
    *   Consolidar la funcionalidad actual de la app.
    *   Implementar en el código las limitaciones del **Plan Básico (Gratis)**.
    *   Crear un portal simple (puede ser fuera de la app) para que los clientes puedan contratar el **Plan Profesional**.
    *   Conseguir los primeros 10 clientes de pago.

*   **Fase 2 (Largo Plazo - Modo Evento):**
    *   Una vez que el modelo SaaS genere ingresos estables, desarrollar las funcionalidades para el "Modo Evento".
    *   Crear el rol `organizador_evento` y su panel de gestión.
    *   Implementar la lógica para crear y desactivar cuentas de vendedores temporales.
    *   Contactar a productoras de eventos para ofrecer la solución.
