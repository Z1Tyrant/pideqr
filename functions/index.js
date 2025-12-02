    const functions = require("firebase-functions");
    const admin = require("firebase-admin");

    admin.initializeApp();
    const db = admin.firestore();

    /**
     * Esta Cloud Function se dispara cada vez que se crea un nuevo
     * documento en la colección 'pedidos'.
     */
    exports.generateReadableOrderId = functions.firestore
      .document("pedidos/{pedidoId}")
      .onCreate(async (snap, context) => {
        // 1. Referencia al documento que usaremos como contador.
        const counterRef = db.collection("counters").doc("order_counter");

        try {
          // 2. Ejecutar una transacción para asegurar que la operación es atómica.
          //    Esto evita que dos pedidos obtengan el mismo número al mismo tiempo.
          const newOrderNumber = await db.runTransaction(async (transaction) => {
            const counterDoc = await transaction.get(counterRef);

            // Si el contador no existe, empezamos en 1000.
            let lastNumber = 1000;
            if (counterDoc.exists) {
              // Si existe, le sumamos 1 al último número guardado.
              lastNumber = counterDoc.data().lastNumber + 1;
            }

            // Actualizamos el contador con el nuevo número para el siguiente pedido.
            transaction.set(counterRef, { lastNumber: lastNumber });

            return lastNumber;
          });

          // 3. Formateamos el ID legible (ej: "P-1001").
          const readableId = `P-${newOrderNumber}`;

          // 4. Actualizamos el documento del pedido que se acaba de crear.
          return snap.ref.update({ readableId: readableId });

        } catch (error) {
          console.error(
            "Fallo al generar el ID para el pedido:",
            context.params.pedidoId,
            error
          );
          return null;
        }
      });
    