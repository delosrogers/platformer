import express from 'express';
import path from 'path';

const app = express();
const port = 3000;
app.get('/', (req, res) => {
    console.log(req);
    res.sendFile(path.join(__dirname + '/elm.html'));
});

app.get('/elm.js', (req, res) => {
    res.sendFile(path.join(__dirname + '/elm.js'))
})

app.get('/')
app.listen(port);