const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// When a post is marked completed, increment the helper's trust score.
exports.onPostCompleted = functions.firestore
  .document("posts/{postId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (before.completed === after.completed) return;
    if (!after.completed || !after.acceptedBy) return;

    const helperId = after.acceptedBy;
    const db = admin.firestore();
    const userRef = db.collection("users").doc(helperId);
    await db.runTransaction(async (t) => {
      const userSnap = await t.get(userRef);
      const current = (userSnap.data() && userSnap.data().trustScore) || 0;
      t.update(userRef, { trustScore: current + 1 });
    });
  });
