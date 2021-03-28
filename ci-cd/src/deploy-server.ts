import express from 'express';
import { exec } from 'child_process';
import fs from 'fs';
import https from 'https';

const app = express();

const privateKey = fs.readFileSync(process.env.PRIVKEYPATH, 'utf8');
const certificate = fs.readFileSync(process.env.CERTPATH, 'utf8');
const credentials = { key: privateKey, cert: certificate };
const httpsServer = https.createServer(credentials, app);
httpsServer.listen(3001, "0.0.0.0", () => console.log("listening on port 3001"));


app.post('/deploy', (_, res) => {
    exec("ci-cd/redeploy.sh");
    res.sendStatus(200);
});