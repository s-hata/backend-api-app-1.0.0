import express, {
  Application,
  Request,
  Response,
  NextFunction
} from 'express';
import * as dotenv from 'dotenv';

dotenv.config();
const GITHUB_APP_IDENTIFIER = process.env.GITHUB_APP_IDENTIFIER;
const GITHUB_PRIVATE_KEY = process.env.GITHUB_PRIVATE_KEY;
const GITHUB_WEBHOOK_SECRET = process.env.GITHUB_WEBHOOK_SECRET;

const app: Application = express();

app.post('/event_handler', (req: Request, res: Response, NextFunction) => {
  console.log(req);
  res.send('Hello from Express');
});

app.listen(80, () => console.log('Server running'));