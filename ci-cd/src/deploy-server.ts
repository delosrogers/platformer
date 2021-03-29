import express from 'express';
import { exec } from 'child_process';
import fs from 'fs';
import https from 'https';

const app = express();
app.use(express.json());

const privateKey = fs.readFileSync(process.env.PRIVKEYPATHNODOCKER, 'utf8');
const certificate = fs.readFileSync(process.env.CERTPATHNODOCKER, 'utf8');
const credentials = { key: privateKey, cert: certificate };
const httpsServer = https.createServer(credentials, app);
httpsServer.listen(3001, "platformer.genedataexplorer.space", () => console.log("listening on port 3001"));
app.listen(3002, () => console.log("listening on 3002"))


app.post('/deploy', (req, res) => {
    if (req.body.secret != process.env.DEPLOY_SECRET) {
        res.send(404);
        return
    }
    console.log("started exec")
    exec("cd ~/code/platformer && cat ci-cd/redeploy.sh | bash", (error, stdout, stderr) => {
        if (error) {
            console.log(`error: ${error.message}`);
            return;
        }
        if (stderr) {
            console.log(`stderr: ${stderr}`);
            return;
        }
        console.log(`stdout: ${stdout}`);
    })
    console.log("finished exec")
    res.sendStatus(200);
});