const admin = require("firebase-admin");
const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");

admin.initializeApp();

// --- FUNCIÓN #1: Notificar cuando un pedido está listo ---
exports.notifyOrderReady = onDocumentUpdated("pedidos/{pedidoId}", (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();

  if (!beforeData || !afterData) {
    return null;
  }

  const isStatusUnchanged = beforeData.status === afterData.status;
  const isNotReady = afterData.status !== "listo_para_entrega";

  if (isStatusUnchanged || isNotReady) {
    return null;
  }
  console.log(`Pedido ${event.params.pedidoId} listo. Notificando...`);

  const userId = afterData.userId;
  if (!userId) {
    console.error("El pedido no tiene un userId asociado.");
    return null;
  }

  const userRef = admin.firestore().collection("users").doc(userId);
  return userRef.get().then((userDoc) => {
    if (!userDoc.exists) {
      console.error(`Usuario ${userId} no encontrado.`);
      return null;
    }
    const fcmTokens = userDoc.data().fcmTokens;
    if (!fcmTokens || fcmTokens.length === 0) {
      console.log(`Usuario ${userId} no tiene tokens de FCM.`);
      return null;
    }
    const message = {
      notification: {
        title: "¡Tu pedido está listo! 🎉",
        body: `Retira en: ${afterData.deliveryZone || "No especificada"}`,
      },
      tokens: fcmTokens,
    };
    console.log(`Enviando a ${fcmTokens.length} dispositivo(s).`);
    return admin.messaging().sendEachForMulticast(message);
  });
});


// --- FUNCIÓN #2: Promover un cliente a vendedor (Invocable) ---
exports.promoteUserToSeller = onCall(async (request) => {
  // 1. Validar que el que llama es un Manager autenticado
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError("unauthenticated", "Debes estar autenticado.");
  }

  const callerUid = request.auth.uid;
  const callerDoc = await admin.firestore().doc(`users/${callerUid}`).get();

  if (!callerDoc.exists || callerDoc.data().role !== "manager") {
    throw new HttpsError(
        "permission-denied",
        "No tienes permiso para realizar esta acción.",
    );
  }

  const managerData = callerDoc.data();
  const storeId = managerData.tiendaId;
  if (!storeId) {
    throw new HttpsError(
        "failed-precondition",
        "No tienes una tienda asignada.",
    );
  }

  // 2. Validar datos de entrada (email)
  const emailToPromote = request.data.email;
  if (!emailToPromote || typeof emailToPromote !== "string") {
    throw new HttpsError("invalid-argument", "El correo es inválido.");
  }

  // 3. Buscar al usuario a promover
  const userQuery = await admin.firestore()
      .collection("users")
      .where("email", "==", emailToPromote.trim().toLowerCase())
      .limit(1)
      .get();

  if (userQuery.empty) {
    throw new HttpsError("not-found", "Usuario no encontrado.");
  }

  const userToPromoteDoc = userQuery.docs[0];
  const userToPromoteData = userToPromoteDoc.data();

  // 4. Validar que el usuario sea un cliente
  if (userToPromoteData.role !== "cliente") {
    throw new HttpsError(
        "failed-precondition",
        "Solo se puede promover a usuarios con el rol de \"cliente\".",
    );
  }

  // 5. Ejecutar la promoción en una transacción
  const userRef = userToPromoteDoc.ref;
  const sellerInStoreRef = admin.firestore()
      .doc(`tiendas/${storeId}/vendedores/${userToPromoteDoc.id}`);

  try {
    await admin.firestore().runTransaction(async (transaction) => {
      transaction.update(userRef, {
        "role": "vendedor",
        "tiendaId": storeId,
      });
      transaction.set(sellerInStoreRef, {
        "name": userToPromoteData.name,
        "email": userToPromoteData.email,
        "role": "vendedor",
      });
    });
  } catch (error) {
    console.error("Error en la transacción:", error);
    throw new HttpsError("internal", "Ocurrió un error al asignar.");
  }

  return {
    success: true,
    message: `¡${userToPromoteData.name} ahora es vendedor de tu tienda!`,
  };
});

// --- FUNCIÓN #3 (NUEVA): Degradar un vendedor a cliente ---
exports.demoteSellerToCustomer = onCall(async (request) => {
  // 1. Validar que el que llama es un Manager autenticado
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError("unauthenticated", "Debes estar autenticado.");
  }

  const callerUid = request.auth.uid;
  const callerDoc = await admin.firestore().doc(`users/${callerUid}`).get();

  if (!callerDoc.exists || callerDoc.data().role !== "manager") {
    throw new HttpsError(
        "permission-denied",
        "No tienes permiso para realizar esta acción.",
    );
  }

  const managerData = callerDoc.data();
  const storeId = managerData.tiendaId;
  if (!storeId) {
    throw new HttpsError(
        "failed-precondition",
        "No tienes una tienda asignada.",
    );
  }

  // 2. Validar datos de entrada (sellerId)
  const sellerId = request.data.sellerId;
  if (!sellerId || typeof sellerId !== "string") {
    throw new HttpsError("invalid-argument", "El ID del vendedor es inválido.");
  }

  // 3. Obtener el documento del vendedor
  const userRef = admin.firestore().doc(`users/${sellerId}`);
  const sellerInStoreRef = admin.firestore()
      .doc(`tiendas/${storeId}/vendedores/${sellerId}`);

  const userToDemoteDoc = await userRef.get();
  if (!userToDemoteDoc.exists) {
    throw new HttpsError("not-found", "El vendedor a eliminar no existe.");
  }
  const userToDemoteData = userToDemoteDoc.data();

  // 4. Validar que el vendedor pertenece a la tienda del manager
  if (userToDemoteData.tiendaId !== storeId) {
    throw new HttpsError(
        "permission-denied",
        "Este vendedor no pertenece a tu tienda.",
    );
  }

  // 5. Ejecutar la degradación en una transacción
  try {
    await admin.firestore().runTransaction(async (transaction) => {
      // 1. Actualiza el documento principal del usuario
      transaction.update(userRef, {
        "role": "cliente",
        "tiendaId": null,
        "deliveryZone": null,
      });
      // 2. Elimina la copia del vendedor de la sub-colección
      transaction.delete(sellerInStoreRef);
    });
  } catch (error) {
    console.error("Error en la transacción de degradación:", error);
    throw new HttpsError("internal", "Ocurrió un error al quitar al vendedor.");
  }

  return {
    success: true,
    message: `¡${userToDemoteData.name} ha vuelto a ser cliente!`,
  };
});
