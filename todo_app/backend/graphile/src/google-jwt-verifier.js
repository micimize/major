import { OAuth2Client } from 'google-auth-library'

function decodedTokenToUser({
  // protocole concerns
  iss,
  azp,
  aud,
  at_hash,
  iat,
  exp,

  // actual user info
  sub: id,
  email,
  email_verified,
  name,
  given_name,
  family_name,
  picture,
  locale,
}) {
  return {
    id,
    email,
    email_verified,
    name,
    picture,
    given_name,
    family_name,
    locale,
  }
}

function verifier(client_id) {
  async function verifyAndDecode(token) {
    // building this outside of scope breaks after ~5 days
    // trying inside of scope
    const client = new OAuth2Client(client_id)

    const ticket = await client.verifyIdToken({
      idToken: token,
      audience: client_id,
    })
    return ticket.getPayload()
  }

  return verifyAndDecode
}

export default function express(client_id) {
  const verify = verifier(client_id)

  return async (request, response, next) => {
    const auth_header = request.get('Authorization')
    const unauthorized = body => response.status(401).send(body)

    if (!auth_header || !auth_header.match(/^Bearer\s/)) {
      return unauthorized('missing authorization header')
    }

    const token = auth_header.replace(/^Bearer\s/, '')
    console.log(token);

    try {
      const payload = await verify(token)
      request.user = decodedTokenToUser(payload)
      next()
    } catch (err) {
      console.log({err});
      return unauthorized(err)
    }
  }
}

/* USAGE *

  app.use(
    '/authenticated',
    googleJWT(GOOGLE_CLIENT_IDS),
  )

/* */
