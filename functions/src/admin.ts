import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import * as cors from "cors";

// Initialize cors handler
const corsHandler = cors({origin: true});

const auth = admin.auth();

/**
 * [V1 HTTP onRequest] Sets or removes admin custom claim on a user.
 */
export const setAdmin = functions.region("asia-northeast3").https.onRequest((req, res) => {
  corsHandler(req, res, async () => {
    // Handle preflight OPTIONS request
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).send({error: "Method Not Allowed"});
      return;
    }

    // Authentication
    const idToken = req.headers.authorization?.split("Bearer ")[1];
    if (!idToken) {
      res.status(403).send({error: "Forbidden", message: "Authorization token is required."});
      return;
    }

    let decodedToken;
    try {
      decodedToken = await auth.verifyIdToken(idToken);
    } catch (error) {
      functions.logger.error("Error verifying ID token:", error);
      res.status(403).send({error: "Forbidden", message: "Invalid or expired authorization token."});
      return;
    }

    // Authorization
    const callerEmail = decodedToken.email;
    const isCallerAdmin = decodedToken.admin === true;
    const allowBootstrap = process.env.ALLOW_ADMIN_BOOTSTRAP === "true";

    if (allowBootstrap) {
      const adminWhitelist = (process.env.ADMIN_EMAIL_WHITELIST || "").split(",").filter((e) => e);
      if (!callerEmail || !adminWhitelist.includes(callerEmail)) {
        res.status(403).send({error: "Forbidden", message: "Caller is not in the bootstrap whitelist."});
        return;
      }
    } else if (!isCallerAdmin) {
      res.status(403).send({error: "Forbidden", message: "Only admins can perform this action."});
      return;
    }

    // Input validation
    const {targetEmail, admin: makeAdmin} = req.body;
    if (typeof targetEmail !== "string" || !targetEmail || typeof makeAdmin !== "boolean") {
      res.status(400).send({
        error: "Bad Request",
        message: "Request body must contain a valid 'targetEmail' (string) and 'admin' (boolean).",
      });
      return;
    }

    // Core logic
    try {
      const targetUser = await auth.getUserByEmail(targetEmail);
      const currentClaims = targetUser.customClaims || {};
      const newClaims = {...currentClaims, admin: makeAdmin};

      await auth.setCustomUserClaims(targetUser.uid, newClaims);

      const action = makeAdmin ? "granted" : "revoked";
      const message = `Success! Admin status has been ${action} for ${targetEmail}.`;
      functions.logger.info(message, {caller: callerEmail, target: targetEmail});
      res.status(200).send({message});
    } catch (error: any) {
      functions.logger.error(`Error processing setAdmin for ${targetEmail}:`, error);
      if (error.code === "auth/user-not-found") {
        res.status(404).send({error: "Not Found", message: `User with email ${targetEmail} not found.`});
      } else {
        res.status(500).send({error: "Internal Server Error", message: "An unexpected error occurred."});
      }
    }
  });
});
