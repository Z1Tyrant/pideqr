# Modelo de Datos de Firestore: PideQR

Este documento describe la estructura de la base de datos NoSQL (Firestore) para la aplicación PideQR.

## Colección: `users`

Almacena el perfil de cada usuario registrado en la aplicación.

| Campo          | Tipo de Dato      | Descripción                                                              |
| :------------- | :---------------- | :----------------------------------------------------------------------- |
| `name`         | `string`          | Nombre de usuario o apodo.                                               |
| `email`        | `string`          | Correo electrónico (usado para el login).                                |
| `role`         | `string`          | Rol del usuario: `cliente`, `vendedor`, `manager`, `admin`.              |
| `tiendaId`     | `string` (nullable) | ID de la tienda a la que pertenece (si es `vendedor` o `manager`).         |
| `deliveryZone` | `string` (nullable) | Zona de entrega asignada (si es `vendedor`).                             |
| `fcmTokens`    | `array<string>`   | Lista de tokens de Firebase Cloud Messaging para notificaciones push.    |

---

## Colección: `tiendas`

Representa cada una de las tiendas o locales del negocio.

| Campo           | Tipo de Dato    | Descripción                                    |
| :-------------- | :-------------- | :--------------------------------------------- |
| `name`          | `string`        | Nombre comercial de la tienda.                 |
| `deliveryZones` | `array<string>` | Lista de zonas de entrega que gestiona la tienda. |

### Sub-colección: `tiendas/{tiendaId}/productos`

Contiene el catálogo o menú de productos para una tienda específica.

| Campo         | Tipo de Dato    | Descripción                                |
| :------------ | :-------------- | :----------------------------------------- |
| `name`        | `string`        | Nombre del producto (ej. "Café Americano").|
| `description` | `string`        | Descripción detallada del producto.        |
| `price`       | `number`        | Precio de venta.                           |
| `stock`       | `number`        | Cantidad de unidades disponibles.          |
| `imageUrl`    | `string` (nullable) | URL de la imagen del producto en Firebase Storage. |

### Sub-colección: `tiendas/{tiendaId}/vendedores`

Copia de los perfiles de los vendedores asignados a una tienda. Optimiza las consultas de los `Managers`. El ID del documento es el `userId` del vendedor.

| Campo   | Tipo de Dato | Descripción                         |
| :------ | :----------- | :---------------------------------- |
| `name`  | `string`     | Nombre del vendedor.                |
| `email` | `string`     | Correo electrónico del vendedor.      |
| `role`  | `string`     | Debería ser siempre `"vendedor"`.     |

---

## Colección: `pedidos`

Almacena cada una de las órdenes generadas por los clientes.

| Campo          | Tipo de Dato      | Descripción                                                                 |
| :------------- | :---------------- | :-------------------------------------------------------------------------- |
| `userId`       | `string`          | ID del cliente que realizó el pedido.                                       |
| `tiendaId`     | `string`          | ID de la tienda donde se realizó el pedido.                                 |
| `total`        | `number`          | Monto total del pedido.                                                     |
| `status`       | `string`          | Estado actual: `pagado`, `en_preparacion`, `listo_para_entrega`, `entregado`. |
| `timestamp`    | `timestamp`       | Fecha y hora de creación del pedido.                                        |
| `deliveredAt`  | `timestamp` (nullable) | Fecha y hora de entrega del pedido.                                       |
| `preparedBy`   | `string` (nullable) | Nombre del vendedor que preparó el pedido.                                  |
| `deliveryZone` | `string` (nullable) | Zona donde el vendedor preparó el pedido para la entrega.                   |

### Sub-colección: `pedidos/{pedidoId}/items`

Contiene el detalle de los productos incluidos en un pedido.

| Campo         | Tipo de Dato | Descripción                               |
| :------------ | :----------- | :---------------------------------------- |
| `productId`   | `string`     | ID del producto original.                 |
| `productName` | `string`     | Nombre del producto (guardado por si cambia el original). |
| `quantity`    | `number`     | Cantidad de unidades de este producto.    |
| `price`       | `number`     | Precio unitario en el momento de la compra. |
