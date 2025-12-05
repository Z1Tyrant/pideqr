const admin = require("firebase-admin");
const {onDocumentUpdated} = require("firebase-functions/v2/firestore");

admin.initializeApp();

/**
 * Cloud Function (v2) que se dispara cuando un pedido se actualiza.
 * Si el estado del pedido cambia a "listo_para_entrega", envía una
 * notificación push al cliente que realizó el pedido.
 */
exports.notifyOrderReady = onDocumentUpdated(
    "pedidos/{pedidoId}",
    async (event) => {
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
      const userDoc = await userRef.get();

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
          // Línea corregida para no superar el límite de longitud
          body: `Retira en: ${afterData.deliveryZone || "No especificada"}`,
        },
        tokens: fcmTokens,
      };

      console.log(`Enviando a ${fcmTokens.length} dispositivo(s).`);

      const response = await admin.messaging()
          .sendEachForMulticast(message);

      const tokensToRemove = [];
      response.responses.forEach((result, index) => {
        if (!result.success) {
          const error = result.error;
          console.error(
              "Fallo al enviar notificación:",
              fcmTokens[index],
              error,
          );
          const errorCode = error.code;
          if (
            errorCode === "messaging/invalid-registration-token" ||
            errorCode === "messaging/registration-token-not-registered"
          ) {
            tokensToRemove.push(fcmTokens[index]);
          }
        }
      });

      if (tokensToRemove.length > 0) {
        console.log(`Eliminando ${tokensToRemove.length} tokens inválidos.`);
        return userRef.update({
          fcmTokens: admin.firestore.FieldValue.arrayRemove(...tokensToRemove),
        });
      }

      return null;
    },
);
