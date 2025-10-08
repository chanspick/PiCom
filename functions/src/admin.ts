import * as admin from "firebase-admin";
import {onRequest} from "firebase-functions/v2/https"; // Use v2 onRequest
import {logger} from "firebase-functions/v2"; // Add logger for v2 functions

const auth = admin.auth();

/**

 * [V2 HTTP onRequest] Sets or removes admin custom claim on a user.

 */

export const setAdmin = onRequest(

  {region: "asia-northeast3", cors: ["https://kream-132e4.web.app"]}, // Use v2 onRequest with explicit CORS

  async (req, res) => {

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

      logger.error("Error verifying ID token:", error); // Use v2 logger

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

      logger.info(message, {caller: callerEmail, target: targetEmail}); // Use v2 logger

      res.status(200).send({message});

    } catch (error: any) {

      logger.error(`Error processing setAdmin for ${targetEmail}:`, error); // Use v2 logger

      if (error.code === "auth/user-not-found") {

        res.status(404).send({error: "Not Found", message: `User with email ${targetEmail} not found.`});

      } else {

        res.status(500).send({error: "Internal Server Error", message: "An unexpected error occurred."});

      }

    }

  });
