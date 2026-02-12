import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import * as jwt from "jsonwebtoken";
import { v4 as uuidv4 } from "uuid";

admin.initializeApp();

// Use the custom "sishu" database
const db = admin.firestore();
db.settings({ databaseId: 'sishu' });
const rtdb = admin.database();
const messaging = admin.messaging();

// 100ms credentials
const hmsAccessKey = defineSecret("HMS_ACCESS_KEY");
const hmsAppSecret = defineSecret("HMS_APP_SECRET");

/**
 * Generate 100ms auth token for video calling
 * Creates a room and returns tokens for both caller and doctor
 */
export const getHmsToken = onCall(
  { secrets: [hmsAccessKey, hmsAppSecret] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const { roomId, role, userId } = request.data;

    if (!roomId || !role || !userId) {
      throw new HttpsError("invalid-argument", "roomId, role, and userId are required");
    }

    try {
      const accessKey = hmsAccessKey.value();
      const appSecret = hmsAppSecret.value();

      if (!accessKey || !appSecret) {
        throw new Error("100ms credentials not configured");
      }

      // Generate JWT token for 100ms
      const payload = {
        access_key: accessKey,
        room_id: roomId,
        user_id: userId,
        role: role, // "guest" for caller, "host" for doctor
        type: "app",
        version: 2,
        iat: Math.floor(Date.now() / 1000),
        nbf: Math.floor(Date.now() / 1000),
      };

      const token = jwt.sign(payload, appSecret, {
        algorithm: "HS256",
        expiresIn: "24h",
        jwtid: uuidv4(),
      });

      console.log(`Generated 100ms token for user ${userId} in room ${roomId} with role ${role}`);

      return { token, roomId };
    } catch (error) {
      console.error("Error generating 100ms token:", error);
      throw new HttpsError("internal", "Failed to generate video call token");
    }
  }
);

/**
 * Create a 100ms room for a video call
 * Returns room ID and tokens for both participants
 */
export const createHmsRoom = onCall(
  { secrets: [hmsAccessKey, hmsAppSecret] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const { callId, callerId, doctorId } = request.data;

    if (!callId || !callerId || !doctorId) {
      throw new HttpsError("invalid-argument", "callId, callerId, and doctorId are required");
    }

    try {
      const accessKey = hmsAccessKey.value();
      const appSecret = hmsAppSecret.value();

      if (!accessKey || !appSecret) {
        throw new Error("100ms credentials not configured");
      }

      // Use callId as roomId (unique per call)
      const roomId = callId;

      // Generate token for caller (guest role)
      const callerPayload = {
        access_key: accessKey,
        room_id: roomId,
        user_id: callerId,
        role: "guest",
        type: "app",
        version: 2,
        iat: Math.floor(Date.now() / 1000),
        nbf: Math.floor(Date.now() / 1000),
      };

      const callerToken = jwt.sign(callerPayload, appSecret, {
        algorithm: "HS256",
        expiresIn: "24h",
        jwtid: uuidv4(),
      });

      // Generate token for doctor (host role)
      const doctorPayload = {
        access_key: accessKey,
        room_id: roomId,
        user_id: doctorId,
        role: "host",
        type: "app",
        version: 2,
        iat: Math.floor(Date.now() / 1000),
        nbf: Math.floor(Date.now() / 1000),
      };

      const doctorToken = jwt.sign(doctorPayload, appSecret, {
        algorithm: "HS256",
        expiresIn: "24h",
        jwtid: uuidv4(),
      });

      console.log(`Created 100ms room ${roomId} for call between ${callerId} and ${doctorId}`);

      // Store tokens in the call document for the doctor to retrieve
      await db.collection("calls").doc(callId).update({
        hmsRoomId: roomId,
        hmsCallerToken: callerToken,
        hmsDoctorToken: doctorToken,
      });

      return {
        roomId,
        callerToken,
        doctorToken,
      };
    } catch (error) {
      console.error("Error creating 100ms room:", error);
      throw new HttpsError("internal", "Failed to create video call room");
    }
  }
);

/**
 * Send call notification to doctor
 * Called by the client after creating a call document
 */
export const sendCallNotification = onCall(async (request) => {
  // Verify user is authenticated
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "User must be authenticated to send call notifications"
    );
  }

  const { callId, doctorId, callerName, callerPhoto } = request.data;

  if (!callId || !doctorId) {
    throw new HttpsError(
      "invalid-argument",
      "callId and doctorId are required"
    );
  }

  try {
    // Get doctor's FCM token
    const doctorDoc = await db.collection("users").doc(doctorId).get();
    const doctorData = doctorDoc.data();

    if (!doctorData?.fcmToken) {
      console.log("Doctor does not have FCM token");
      return { success: false, reason: "no_fcm_token" };
    }

    // Send high-priority data message for call notification
    // Format matches flutter_callkit_incoming for automatic background handling
    const message: admin.messaging.Message = {
      token: doctorData.fcmToken,
      data: {
        // Custom fields for our app
        type: "incoming_call",
        callerId: request.auth.uid,
        // Fields for flutter_callkit_incoming (automatic background handling)
        id: callId,
        nameCaller: callerName || "Unknown",
        avatar: callerPhoto || "",
        handle: "Incoming Video Consultation",
        callType: "1", // 1 = video, 0 = audio (must be string for FCM data)
        duration: "60000",
        textAccept: "Accept",
        textDecline: "Decline",
        // Extra data
        extra: JSON.stringify({
          callId: callId,
          type: "incoming_call",
        }),
      },
      android: {
        priority: "high",
        ttl: 60000, // 60 seconds
      },
      apns: {
        headers: {
          "apns-priority": "10",
          "apns-push-type": "voip",
        },
        payload: {
          aps: {
            "content-available": 1,
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    await messaging.send(message);
    console.log(`Call notification sent to doctor ${doctorId}`);
    return { success: true };
  } catch (error) {
    console.error("Error sending call notification:", error);
    throw new HttpsError(
      "internal",
      "Failed to send call notification"
    );
  }
});

/**
 * Cleanup stale calls and signaling data
 * Runs every 5 minutes
 */
export const cleanupStaleCalls = onSchedule("every 5 minutes", async () => {
  const now = admin.firestore.Timestamp.now();
  const sixtySecondsAgo = new Date(now.toMillis() - 60000);

  try {
    // Find calls that are still ringing after 60 seconds
    const staleCalls = await db
      .collection("calls")
      .where("status", "==", "ringing")
      .where("startedAt", "<", admin.firestore.Timestamp.fromDate(sixtySecondsAgo))
      .get();

    const batch = db.batch();
    const callIdsToCleanup: string[] = [];

    staleCalls.forEach((doc) => {
      batch.update(doc.ref, {
        status: "missed",
        endedAt: now,
      });
      callIdsToCleanup.push(doc.id);
    });

    if (staleCalls.size > 0) {
      await batch.commit();
      console.log(`Marked ${staleCalls.size} calls as missed`);
    }

    // Clean up signaling data for these calls
    for (const callId of callIdsToCleanup) {
      try {
        await rtdb.ref(`calls/${callId}`).remove();
        console.log(`Cleaned up signaling data for call ${callId}`);
      } catch (err) {
        console.error(`Error cleaning signaling for ${callId}:`, err);
      }
    }

    // Also cleanup signaling data older than 1 hour
    const oneHourAgo = new Date(now.toMillis() - 3600000);
    const endedCalls = await db
      .collection("calls")
      .where("status", "in", ["ended", "missed", "declined"])
      .where("endedAt", "<", admin.firestore.Timestamp.fromDate(oneHourAgo))
      .limit(50)
      .get();

    for (const doc of endedCalls.docs) {
      try {
        await rtdb.ref(`calls/${doc.id}`).remove();
      } catch {
        // Ignore errors for non-existent signaling data
      }
    }

    console.log("Stale calls cleanup completed");
  } catch (error) {
    console.error("Error in cleanup:", error);
  }
});

/**
 * Update doctor's availability status
 * Can be called by the doctor to toggle their instant call availability
 */
export const updateDoctorAvailability = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const { acceptingInstantCalls } = request.data;

  try {
    // Get user's doctor profile
    const doctorProfileRef = db
      .collection("doctor_profiles")
      .doc(request.auth.uid);
    const doctorProfile = await doctorProfileRef.get();

    if (!doctorProfile.exists) {
      throw new HttpsError(
        "not-found",
        "Doctor profile not found"
      );
    }

    await doctorProfileRef.update({
      acceptingInstantCalls: acceptingInstantCalls,
      statusUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true };
  } catch (error) {
    console.error("Error updating availability:", error);
    throw new HttpsError(
      "internal",
      "Failed to update availability"
    );
  }
});

/**
 * Send admin notification to targeted users
 * Can send to all users, doctors only, or parents only
 */
export const sendAdminNotification = onCall(async (request) => {
  console.log("sendAdminNotification called");
  console.log("Auth:", request.auth?.uid);
  console.log("Data:", JSON.stringify(request.data));

  // Verify user is authenticated
  if (!request.auth) {
    console.log("ERROR: User not authenticated");
    throw new HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const {
    title,
    body,
    imageUrl,
    target,
    type,
    referenceId,
    referenceType,
    extraData,
  } = request.data;

  if (!title || !body) {
    console.log("ERROR: Missing title or body");
    throw new HttpsError(
      "invalid-argument",
      "title and body are required"
    );
  }

  try {
    // Get admin user info
    console.log("Fetching admin user:", request.auth.uid);
    const adminDoc = await db.collection("users").doc(request.auth.uid).get();
    const adminData = adminDoc.data();
    console.log("Admin data:", JSON.stringify(adminData));

    // Verify user is admin
    if (!adminData || (adminData.role !== "admin" && adminData.role !== "creator")) {
      console.log("ERROR: User is not admin, role:", adminData?.role);
      throw new HttpsError(
        "permission-denied",
        "Only admins can send notifications"
      );
    }

    // Build query based on target
    console.log("Building query for target:", target);
    let usersQuery: FirebaseFirestore.Query = db.collection("users");

    if (target === "doctors") {
      usersQuery = usersQuery.where("role", "==", "doctor");
    } else if (target === "parents") {
      usersQuery = usersQuery.where("role", "==", "user");
    }
    // For "all", we don't add any filter

    // Get users with FCM tokens
    const usersSnapshot = await usersQuery.get();
    console.log("Total users found:", usersSnapshot.size);

    const tokens: string[] = [];
    const tokenDetails: { uid: string, token: string }[] = [];

    usersSnapshot.forEach((doc) => {
      const userData = doc.data();
      console.log(`User ${doc.id}: role=${userData.role}, hasToken=${!!userData.fcmToken}`);
      if (userData.fcmToken) {
        tokens.push(userData.fcmToken);
        tokenDetails.push({ uid: doc.id, token: userData.fcmToken.substring(0, 20) + "..." });
      }
    });

    console.log("Users with FCM tokens:", tokens.length);
    console.log("Token details:", JSON.stringify(tokenDetails));

    if (tokens.length === 0) {
      console.log("No users with FCM tokens found for target:", target);
      return { success: true, sentCount: 0, message: "No tokens found" };
    }

    // Build notification message
    const notification: admin.messaging.Notification = {
      title: title,
      body: body,
    };

    if (imageUrl) {
      notification.imageUrl = imageUrl;
    }

    // Build data payload
    const dataPayload: { [key: string]: string } = {
      type: type || "general",
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    };

    if (referenceId) {
      dataPayload.referenceId = referenceId;
    }
    if (referenceType) {
      dataPayload.referenceType = referenceType;
    }

    // Send to all tokens (batch of 500 max per sendEachForMulticast)
    let sentCount = 0;
    const batchSize = 500;

    for (let i = 0; i < tokens.length; i += batchSize) {
      const batch = tokens.slice(i, i + batchSize);

      const message: admin.messaging.MulticastMessage = {
        tokens: batch,
        notification: notification,
        data: dataPayload,
        android: {
          priority: "high",
          notification: {
            channelId: "high_importance_channel",
            priority: "high",
            defaultSound: true,
            defaultVibrateTimings: true,
          },
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
          payload: {
            aps: {
              alert: {
                title: title,
                body: body,
              },
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      console.log(`Sending batch ${i / batchSize + 1} with ${batch.length} tokens`);
      const response = await messaging.sendEachForMulticast(message);
      console.log(`Batch result: success=${response.successCount}, failure=${response.failureCount}`);
      sentCount += response.successCount;

      if (response.failureCount > 0) {
        console.log(`${response.failureCount} messages failed in batch ${i / batchSize + 1}`);
        // Log individual failures
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            console.log(`Token ${idx} failed:`, resp.error?.code, resp.error?.message);
          }
        });
      }
    }

    // Save notification to history
    const notificationRef = db.collection("admin_notifications").doc();
    await notificationRef.set({
      title: title,
      body: body,
      imageUrl: imageUrl || null,
      target: target || "all",
      type: type || "general",
      referenceId: referenceId || null,
      referenceType: referenceType || null,
      extraData: extraData || null,
      sentCount: sentCount,
      sentBy: request.auth.uid,
      sentByName: adminData.name || adminData.displayName || "Admin",
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`Admin notification sent to ${sentCount} users, notificationId: ${notificationRef.id}`);
    return {
      success: true,
      sentCount: sentCount,
      notificationId: notificationRef.id,
    };
  } catch (error) {
    console.error("Error sending admin notification:", error);
    console.error("Error details:", JSON.stringify(error, Object.getOwnPropertyNames(error)));
    throw new HttpsError(
      "internal",
      "Failed to send notification: " + (error as Error).message
    );
  }
});
