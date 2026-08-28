const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// Create a user profile document when a new user signs up
exports.onUserCreate = functions.auth.user().onCreate(async (user) => {
  const docRef = db.collection('users').doc(user.uid);
  const profile = {
    uid: user.uid,
    name: user.displayName || '',
    email: user.email || null,
    phone: user.phoneNumber || null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    defaultAddressId: null,
  };
  await docRef.set(profile);
  console.log(`Created user profile for ${user.uid}`);
});

// Callable function to set/remove admin custom claim on a user
// Caller must already have admin claim
exports.setAdminClaim = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'The function must be called while authenticated.');
  }

  const callerUid = context.auth.uid;
  const callerToken = context.auth.token || {};
  if (!callerToken.admin) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can set admin claims.');
  }

  const targetUid = data.uid;
  const makeAdmin = !!data.admin;

  if (!targetUid || typeof targetUid !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'Missing target uid');
  }

  try {
    await admin.auth().setCustomUserClaims(targetUid, { admin: makeAdmin });
    return { success: true, uid: targetUid, admin: makeAdmin };
  } catch (err) {
    console.error('setAdminClaim error', err);
    throw new functions.https.HttpsError('internal', 'Unable to set custom claim');
  }
});
