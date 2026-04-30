// 1. All Imports at the top
const { onDocumentDeleted } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

// 2. Initialize Admin SDK
admin.initializeApp();

// 3. Cloud Function: Clean up Auth when Firestore doc is deleted
exports.cleanupChildAuth = onDocumentDeleted("users/{userId}", async (event) => {
  const deletedData = event.data.data();
  const userId = event.params.userId;

  if (deletedData && deletedData.role === 'child') {
    try {
      await admin.auth().deleteUser(userId);
      console.log(`Successfully deleted Auth account for child: ${userId}`);
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        console.log(`User ${userId} was already deleted from Auth.`);
      } else {
        console.error(`Failed to delete Auth account for ${userId}:`, error);
      }
    }
  }
});

// 4. Cloud Function: Update child password from Parent app
exports.updateChildPassword = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'You must be logged in to update a password.');
  }

  const childUid = request.data.childUid;
  const newPassword = request.data.newPassword;

  if (!childUid || !newPassword) {
    throw new HttpsError('invalid-argument', 'Missing childUid or newPassword.');
  }

  try {
    await admin.auth().updateUser(childUid, {
      password: newPassword,
    });
    console.log(`Successfully updated password for child: ${childUid}`);
    return { success: true };
  } catch (error) {
    console.error("Error updating password:", error);
    throw new HttpsError('internal', 'Failed to update password.');
  }
});

// 5. Cloud Function: Delete child Auth account (called from parent app)
exports.deleteChildAuth = onCall(async (request) => {
  // Verify the caller is authenticated
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be logged in.");
  }

  const callerUid = request.auth.uid;
  const childUid = request.data.childUid;

  if (!childUid) {
    throw new HttpsError("invalid-argument", "childUid is required.");
  }

  // Verify caller is actually the parent of this child
  const childDoc = await admin.firestore()
    .collection("users")
    .doc(childUid)
    .get();

  if (!childDoc.exists) {
    throw new HttpsError("not-found", "Child account not found.");
  }

  if (childDoc.data().parentId !== callerUid) {
    throw new HttpsError("permission-denied", "You are not this child's parent.");
  }

  // Delete Firebase Auth account
  try {
    await admin.auth().deleteUser(childUid);
    console.log(`Successfully deleted Auth for child: ${childUid}`);
  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      console.log(`Child ${childUid} Auth already deleted.`);
    } else {
      throw new HttpsError('internal', `Failed to delete Auth: ${error.message}`);
    }
  }

  // Delete progress document
  await admin.firestore().collection("progress").doc(childUid).delete();
  console.log(`Deleted progress doc for child: ${childUid}`);

  return { success: true };
});