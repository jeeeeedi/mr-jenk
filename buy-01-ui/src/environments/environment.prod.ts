// src/environments/environment.prod.ts
// This is the PRODUCTION file for Docker builds
export const environment = {
  production: true,
  apiUrl: 'http://51.21.198.139:8080/api',
  apiGatewayUrl: 'http://51.21.198.139:8080',
  authUrl: 'http://51.21.198.139:8080/api/auth',
  usersUrl: 'http://51.21.198.139:8080/api/users',
  productsUrl: 'http://51.21.198.139:8080/api/products',
  mediaUrl: 'http://51.21.198.139:8080/api/media',
  enableDebugLogging: false,
};
