import { createHmac } from 'crypto';
import express, {
  Application,
  Request,
  Response,
  NextFunction
} from 'express';
import * as dotenv from 'dotenv';
import { App } from "octokit";

dotenv.config();
const GITHUB_APP_IDENTIFIER = process.env.GITHUB_APP_IDENTIFIER as string;
const GITHUB_PRIVATE_KEY = process.env.GITHUB_PRIVATE_KEY as string;
const GITHUB_WEBHOOK_SECRET = process.env.GITHUB_WEBHOOK_SECRET as string;

const app: Application = express();
app.use(express.json());

app.post('/', async (req: Request, res: Response, NextFunction) => {
  //console.log(req.headers);
  //console.log(createHmac('sha256', GITHUB_WEBHOOK_SECRET).update(JSON.stringify(req.body)).digest('hex'));
  //console.log(req.body);
  
  const installationId = req.body.installation.id;
  const app = new App({
    appId: GITHUB_APP_IDENTIFIER,
    privateKey: GITHUB_PRIVATE_KEY
  })
  const client = await app.getInstallationOctokit(installationId);
  const response = await client.request("GET /meta")
  console.log(response);
  res.send('Hello from Express');
});

app.listen(80, () => console.log('Server running'));