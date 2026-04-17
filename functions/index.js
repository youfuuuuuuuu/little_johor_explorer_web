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