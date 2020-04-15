import { auth } from "firebase-admin";
import { Express } from "express";

export default (app: Express) =>
  app.use(async (request: any, response: any, next: () => void) => {
    const authHeader = request.get("Authorization");
    const unauthorized = (body: string) => response.status(401).send(body);

    if (!authHeader || !authHeader.match(/^Bearer\s/)) {
      return unauthorized("missing authorization header");
    }

    const token = authHeader.replace(/^Bearer\s/, "");

    try {
      request.firebaseUser = await auth().verifyIdToken(token);
      console.log(request.firebaseUser);
      next();
    } catch (err) {
      return unauthorized(err);
    }
  });
