import { auth, initializeApp } from "firebase-admin";
import { Express } from "express";
import { print } from "graphql";

export default (app: Express) => (
  initializeApp(),
  app.use(async (request: any, response: any, next: () => void) => {
    const authHeader = request.get("Authorization");
    const unauthorized = (body: string) => response.status(401).send(body);

    if (!authHeader || !authHeader.match(/^Bearer\s/)) {
      return unauthorized("missing authorization header");
    }

    const idToken = authHeader.replace(/^Bearer\s/, "");

    try {
      request.firebaseUser = await auth().verifyIdToken(idToken);
      console.log(request.firebaseUser);
      next();
    } catch (err) {
      return unauthorized(err);
    }
  })
);
