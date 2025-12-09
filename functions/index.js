const admin = require("firebase-admin");
const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {WebpayPlus, Options, Environment} = require("transbank-sdk");

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
  const emailToPromote = request.data.email;
  if (!emailToPromote || typeof emailToPromote !== "string") {
    throw new HttpsError("invalid-argument", "El correo es inválido.");
  }
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
  if (userToPromoteData.role !== "cliente") {
    throw new HttpsError(
        "failed-precondition",
        "Solo se puede promover a usuarios con el rol de \"cliente\".",
    );
  }
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

// --- FUNCIÓN #3: Degradar un vendedor a cliente ---
exports.demoteSellerToCustomer = onCall(async (request) => {
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
  const sellerId = request.data.sellerId;
  if (!sellerId || typeof sellerId !== "string") {
    throw new HttpsError("invalid-argument", "El ID del vendedor es inválido.");
  }
  const userRef = admin.firestore().doc(`users/${sellerId}`);
  const sellerInStoreRef = admin.firestore()
      .doc(`tiendas/${storeId}/vendedores/${sellerId}`);
  const userToDemoteDoc = await userRef.get();
  if (!userToDemoteDoc.exists) {
    throw new HttpsError("not-found", "El vendedor a eliminar no existe.");
  }
  const userToDemoteData = userToDemoteDoc.data();
  if (userToDemoteData.tiendaId !== storeId) {
    throw new HttpsError(
        "permission-denied",
        "Este vendedor no pertenece a tu tienda.",
    );
  }
  try {
    await admin.firestore().runTransaction(async (transaction) => {
      transaction.update(userRef, {
        "role": "cliente",
        "tiendaId": null,
        "deliveryZone": null,
      });
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

// --- FUNCIÓN DE WEBPAY #1: Crear la transacción ---
exports.createWebpayTransaction = onCall({appCheck: false}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "El usuario debe estar autenticado para realizar un pago.");
  }

  const {tiendaId, buyOrder, amount} = request.data;
  if (!tiendaId || !buyOrder || !amount || amount <= 0) {
    throw new HttpsError("invalid-argument", "Los datos del pedido (tiendaId, buyOrder, amount) son inválidos.");
  }

  try {
    const credsDoc = await admin.firestore().collection("tiendas").doc(tiendaId).collection("private_credentials").doc("transbank").get();

    if (!credsDoc.exists) {
      throw new HttpsError("not-found", `No se encontraron credenciales para la tienda: ${tiendaId}`);
    }

    const {commerce_code, api_key} = credsDoc.data();
    if (!commerce_code || !api_key) {
      throw new HttpsError("data-loss", "Las credenciales de la tienda están incompletas.");
    }
    
    console.log(`Intentando crear transacción para tienda ${tiendaId} con código de comercio: ${commerce_code}`);
    const integerAmount = Math.round(amount);
    console.log(`Monto original: ${amount}, Monto a enviar (entero): ${integerAmount}`);

    const tx = new WebpayPlus.Transaction(new Options(commerce_code, api_key, Environment.Integration));
    
    const sessionId = request.auth.uid; 
    const returnUrl = "https://pideqr.app/payment_return";

    const response = await tx.create(buyOrder, sessionId, integerAmount, returnUrl);

    return {url: response.url, token: response.token};
  } catch (error) {
    console.error("Error al crear la transacción en Transbank:", error);
    throw new HttpsError("internal", "Ocurrió un error al procesar el pago. Por favor, inténtalo de nuevo.", error.message);
  }
});


// --- FUNCIÓN DE WEBPAY #2: Confirma la transacción y guarda el pedido ---
exports.confirmWebpayTransaction = onCall({appCheck: false}, async (request) => {
  console.log("Iniciando confirmación de transacción.");

  // 1. Validar autenticación y datos de entrada
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "El usuario debe estar autenticado.");
  }

  const {token_ws, tiendaId, items, total} = request.data;
  if (!token_ws || !tiendaId || !items || !total) {
    throw new HttpsError("invalid-argument", "Faltan datos para confirmar el pedido (token, tiendaId, items, total).");
  }

  try {
    // 2. Obtener credenciales seguras de la tienda
    const credsDoc = await admin.firestore().collection("tiendas").doc(tiendaId).collection("private_credentials").doc("transbank").get();
    if (!credsDoc.exists) {
      throw new HttpsError("not-found", "No se encontraron las credenciales de Transbank para esta tienda.");
    }
    const {commerce_code, api_key} = credsDoc.data();

    // 3. Confirmar la transacción con Transbank
    const tx = new WebpayPlus.Transaction(new Options(commerce_code, api_key, Environment.Integration));
    const commitResponse = await tx.commit(token_ws);
    console.log("Respuesta de commit de Transbank:", commitResponse);

    // 4. Verificar que el pago fue exitoso (status 'AUTHORIZED')
    if (commitResponse.status !== "AUTHORIZED") {
      throw new HttpsError("aborted", `El pago fue rechazado por Transbank. Estado: ${commitResponse.status}`);
    }

    // 5. El pago fue exitoso. Ahora, guardamos el pedido en Firestore.
    console.log("Pago confirmado. Guardando pedido en Firestore.");
    const userId = request.auth.uid;

    const pedidoRef = admin.firestore().collection("pedidos").doc();
    
    // Iniciar una transacción de Firestore para asegurar consistencia
    await admin.firestore().runTransaction(async (transaction) => {
      // a. Crear el documento del pedido principal
      transaction.set(pedidoRef, {
        userId: userId,
        tiendaId: tiendaId,
        total: total,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        status: "pagado", // Estado inicial después de un pago exitoso
        buyOrder: commitResponse.buy_order,
        paymentDetails: {
          authorizationCode: commitResponse.authorization_code,
          paymentTypeCode: commitResponse.payment_type_code,
          responseCode: commitResponse.response_code,
          installmentsNumber: commitResponse.installments_number,
        },
      });

      // b. Crear cada item del pedido en la subcolección 'items'
      for (const item of items) {
        const itemRef = pedidoRef.collection("items").doc();
        transaction.set(itemRef, {
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          subtotal: item.subtotal,
        });
      }
    });

    console.log(`Pedido ${pedidoRef.id} guardado exitosamente en Firestore.`);

    // 6. Devolver éxito a la app
    return {success: true, pedidoId: pedidoRef.id};

  } catch (error) {
    console.error("Error al confirmar la transacción de Webpay:", error);
    throw new HttpsError("internal", "Ocurrió un error al confirmar el pago.", error.message);
  }
});