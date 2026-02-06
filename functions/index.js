const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// Helper: send a push notification to a user by their Firestore userId.
// Returns silently if user has no fcmToken or if sending fails.
async function sendNotificationToUser(userId, title, body, data) {
  const userSnap = await db.collection("users").doc(userId).get();
  if (!userSnap.exists) return;

  const fcmToken = userSnap.data().fcmToken;
  if (!fcmToken) return;

  try {
    await messaging.send({
      token: fcmToken,
      notification: { title, body },
      data: data || {},
    });
  } catch (err) {
    // If token is invalid/expired, remove it from Firestore
    if (
      err.code === "messaging/invalid-registration-token" ||
      err.code === "messaging/registration-token-not-registered"
    ) {
      await db.collection("users").doc(userId).update({ fcmToken: admin.firestore.FieldValue.delete() });
    }
    console.error(`Failed to send notification to ${userId}:`, err.message);
  }
}

// When a post is marked completed, increment the helper's trust score.
exports.onPostCompleted = functions.firestore
  .document("posts/{postId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (before.completed === after.completed) return;
    if (!after.completed || !after.acceptedBy) return;

    const helperId = after.acceptedBy;
    const userRef = db.collection("users").doc(helperId);
    await db.runTransaction(async (t) => {
      const userSnap = await t.get(userRef);
      const current = (userSnap.data() && userSnap.data().trustScore) || 0;
      t.update(userRef, { trustScore: current + 1 });
    });
  });

// When someone accepts a post (acceptedBy changes from null to a userId),
// notify the post owner.
exports.onPostAccepted = functions.firestore
  .document("posts/{postId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only trigger when acceptedBy changes from null/undefined to a value
    if (before.acceptedBy || !after.acceptedBy) return;

    const postId = context.params.postId;
    const postOwnerId = after.userId;
    const helperId = after.acceptedBy;

    // Don't notify if the owner accepted their own post
    if (postOwnerId === helperId) return;

    // Get helper's name for the notification
    const helperSnap = await db.collection("users").doc(helperId).get();
    const helperName = helperSnap.exists ? helperSnap.data().name : "Someone";

    const displayName = after.anonymous ? "Someone" : helperName;

    await sendNotificationToUser(
      postOwnerId,
      "Your post was accepted!",
      `${displayName} is ready to help with: "${after.description.substring(0, 50)}"`,
      { type: "post_accepted", postId: postId }
    );
  });

// When a new message is sent, notify the other participant.
exports.onMessageSent = functions.firestore
  .document("messages/{postId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const messageData = snap.data();
    const postId = context.params.postId;
    const senderId = messageData.senderId;

    // Get the post to determine the other participant
    const postSnap = await db.collection("posts").doc(postId).get();
    if (!postSnap.exists) return;

    const postData = postSnap.data();
    const postOwnerId = postData.userId;
    const helperId = postData.acceptedBy;

    // Determine recipient: if sender is owner, notify helper; otherwise notify owner
    const recipientId = senderId === postOwnerId ? helperId : postOwnerId;
    if (!recipientId) return;

    // Don't notify yourself
    if (recipientId === senderId) return;

    // Get sender's name
    const senderSnap = await db.collection("users").doc(senderId).get();
    const senderName = senderSnap.exists ? senderSnap.data().name : "Someone";

    const messagePreview = messageData.text
      ? messageData.text.substring(0, 60)
      : "New message";

    await sendNotificationToUser(
      recipientId,
      `Message from ${senderName}`,
      messagePreview,
      { type: "new_message", postId: postId }
    );
  });
