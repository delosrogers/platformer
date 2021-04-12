import express from 'express';
import passport from 'passport';
import Google from 'passport-google-oauth';
import cookieSession from 'cookie-session'
import cryptoRandomString from 'crypto-random-string'
import https from 'https';
import fs from 'fs';
import { getRoutes } from './routes'
import { userLogin, IUser, getUser } from './db'


let hostName: string;
if (process.env.DEV != "TRUE") {

    hostName = "https://platformer.genedataexplorer.space";
} else {

    hostName = "http://localhost";
}

const GoogleStrategy = Google.OAuth2Strategy;

require('dotenv').config();
passport.use(new GoogleStrategy({
    clientID: process.env.GOOGLE_CLIENT_ID,
    clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    callbackURL: hostName + ":3000/auth/google/callback",
},
    userLogin
));




const app = express();
app.use(express.json());
app.use(cookieSession({
    name: 'session',
    maxAge: 24 * 60 * 60 * 1000,
    keys: [cryptoRandomString({ length: 64 })]
}));
app.use(passport.initialize())
app.use(passport.session());

app.set('view engine', 'ejs');


if (process.env.DEV != "TRUE") {
    const privateKey = fs.readFileSync(process.env.PRIVKEYPATH, 'utf8');
    const certificate = fs.readFileSync(process.env.CERTPATH, 'utf8');
    const credentials = { key: privateKey, cert: certificate };
    const httpsServer = https.createServer(credentials, app);
    httpsServer.listen(3000, "0.0.0.0", () => console.log("listening on port 3000"));
} else {
    const port = 3000;
    app.listen(port, () => console.log("listening on port ", port))
}

app.use((err, req, res, next) => {
    if (err.code !== 'EBADCSRFTOKEN') return next(err)

    console.log("CSRF error with user: ", req.user)
    res.status(403);
    res.send('form tampered with')
});


passport.serializeUser(function (user: IUser, done) {
    done(null, user._id.toString());
});

passport.deserializeUser(function (id: string, done) {
    getUser(id)
        .then(
            (user: IUser) => done(null, user)
        );
});

app.use('/', getRoutes())

app.get('/auth/google',
    passport.authenticate(
        'google',
        { scope: ['https://www.googleapis.com/auth/plus.login', 'profile', 'email'] }));

app.get('/auth/google/callback', passport.authenticate('google', { failureRedirect: '/' }),
    (req, res) => res.redirect('/'));
