import { getApp } from "../dist/server.js";

export default async function handler(req, res) {
  const app = await getApp();
  app(req, res);
}
