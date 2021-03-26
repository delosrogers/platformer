import express from 'express';
import path from 'path';
import { connect } from 'mongoose';
import mongoose = require('mongoose')
import { model, Schema, Model, Document } from 'mongoose';
import passport from 'passport';
import Google from 'passport-google-oauth';
import cookieSession from 'cookie-session'
import cryptoRandomString from 'crypto-random-string'
import http from 'http';
import https from 'https';
import fs from 'fs';
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
    function (accessToken: string, refreshToken: string, profile, done) {
        connect('mongodb://localhost:27017/platformer', {
            useNewUrlParser: true,
            useUnifiedTopology: true
        });

        User.findOne({ googleId: profile.id }, (err: any, user: IUser) => {
            if (user) {
                done(err, user);
            } else {
                User.create({
                    googleId: profile.id,
                    name: profile.displayName,
                    highScore: 0,
                }, (err: any, user: IUser) => {
                    done(err, user);
                });
            }
        });
    }

));

mongoose.set('toJSON', { transform: true, flattenDecimals: true });

interface IUser extends Document {
    name: string,
    highScore: number,
    googleId: string,
}

const UserSchema: Schema = new Schema({
    name: { type: String, required: true },
    highScore: { type: Number, required: true },
    googleId: { type: String, required: true },
});


const User: Model<IUser> = model('User', UserSchema);


const app = express();
app.use(express.json());
app.use(cookieSession({
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
    httpsServer.listen(3000, "platformer.genedataexplorer.space", () => console.log("listening on port 3000"));
} else {
    const port = 3000;
    app.listen(port, () => console.log("listening on port ", port))
}


passport.serializeUser(function (user: IUser, done) {
    done(null, user._id);
});

passport.deserializeUser(function (id, done) {
    User.findById(id)
        .then(
            (user: IUser) => done(null, user)
        );
});


app.get('/', (req, res) => {
    console.log("current user: ", req.user)
    res.render('elm.ejs', { user: req.user });
});

app.get('/elm.js', (req, res) => {
    res.sendFile(path.join(__dirname + '/static/elm.js'));
});

app.get('/auth/google',
    passport.authenticate(
        'google',
        { scope: ['https://www.googleapis.com/auth/plus.login', 'profile', 'email'] }));

app.get('/auth/google/callback', passport.authenticate('google', { failureRedirect: '/' }),
    (req, res) => res.redirect('/'));

app.get('/api/v1/u/:id', async (req, res) => {
    const userID = req.params.id;
    const currUser: any = req.user;
    if (userID != currUser?._id) {
        res.sendStatus(404);
        return;
    }
    const user: IUser = await getUser(userID);
    if (user) {
        res.send(user);
    } else {
        res.sendStatus(404);
    }
});

app.post('/api/v1/u', async (req, res) => {
    res.sendStatus(418);
    // const userName = req.body.name;
    // const id = await newUser(userName);
    // if (id) {
    //     res.send({ _id: id, name: userName, highScore: 0 });
    // } else {
    //     res.sendStatus(418);
    // }

});

app.put('/api/v1/u/:id/highscore', async (req, res) => {
    const id: string = req.params.id;
    const currUser: any = req.user;
    if (id != currUser?._id) {
        res.sendStatus(404);
        return;
    }
    const score: number = req.body.score;
    try {
        await newHighScore(score, id);
        res.sendStatus(200);
    } catch (e) {
        console.log(e.message);
        if (e.message == "No Such User") {
            res.sendStatus(404);
        } else {
            res.sendStatus(418);
        }
    }
})


async function getUser(id: string): Promise<IUser> {
    await connect('mongodb://localhost:27017/platformer', {
        useNewUrlParser: true,
        useUnifiedTopology: true
    });

    return await User.findById(id).exec();
}

// async function newUser(name: string): Promise<string> {
//     await connect('mongodb://localhost:27017/platformer', {
//         useNewUrlParser: true,
//         useUnifiedTopology: true
//     });

//     const user: IUser = await User.create({
//         name: name,
//         highScore: 0,
//     });

//     return user._id.toString();
// }

async function newHighScore(score: number, id: string) {
    await connect('mongodb://localhost:27017/platformer', {
        useNewUrlParser: true,
        useUnifiedTopology: true
    });

    let user = await User.findOne({ _id: id });
    if (!user) {
        throw new Error('No Such User');
    }

    user.highScore = Math.max(score, user.highScore);
    await user.save();
}