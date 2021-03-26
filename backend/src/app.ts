import express from 'express';
import path from 'path';
import { connect } from 'mongoose';
import mongoose = require('mongoose')
import { model, Schema, Model, Document } from 'mongoose';
import passport from 'passport';
import Google from 'passport-google-oauth';
import findOrCreate from 'mongoose-findorcreate'
import cookieSession from 'cookie-session'
import cryptoRandomString from 'crypto-random-string'

const GoogleStrategy = Google.OAuth2Strategy;

require('dotenv').config();
passport.use(new GoogleStrategy({
    clientID: process.env.GOOGLE_CLIENT_ID,
    clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    callbackURL: "http://localhost:3000/auth/google/callback",
},
    function (accessToken: string, refreshToken: string, profile, done) {
        connect('mongodb://localhost:27017/platformer', {
            useNewUrlParser: true,
            useUnifiedTopology: true
        });

        User.findOne({ googleId: profile.id }, (err, user) => {
            if (user) {
                done(err, user);
            } else {
                User.create({
                    googleId: profile.id,
                    name: profile.displayName,
                    highScore: 0,
                }, (err, user) => {
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

UserSchema.plugin(findOrCreate);

const User: Model<IUser> = model('User', UserSchema);


const app = express();
app.use(express.json());
app.use(cookieSession({
    maxAge: 24 * 60 * 60 * 1000,
    keys: [cryptoRandomString({ length: 20 })]
}));
app.use(passport.initialize())
app.use(passport.session());



passport.serializeUser(function (user: IUser, done) {
    done(null, user._id);
});

passport.deserializeUser(function (id, done) {
    User.findById(id)
        .then(
            (user) => done(null, user)
        );
});


const port = 3000;
app.get('/', (req, res) => {
    console.log('current user', req.user)
    res.sendFile(path.join(__dirname + '/static/elm.html'));
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
    const user: IUser = await getUser(userID);
    if (user) {
        res.send(user);
    } else {
        res.sendStatus(404);
    }
});

app.post('/api/v1/u', async (req, res) => {
    const userName = req.body.name;
    const id = await newUser(userName);
    if (id) {
        res.send({ _id: id, name: userName, highScore: 0 });
    } else {
        res.sendStatus(418);
    }

});

app.put('/api/v1/u/:id/highscore', async (req, res) => {
    const id: string = req.params.id;
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

app.listen(port, () => console.log("serving on port" + port));

async function getUser(id: string): Promise<IUser> {
    await connect('mongodb://localhost:27017/platformer', {
        useNewUrlParser: true,
        useUnifiedTopology: true
    });

    return await User.findById(id).exec();
}

async function newUser(name: string): Promise<string> {
    await connect('mongodb://localhost:27017/platformer', {
        useNewUrlParser: true,
        useUnifiedTopology: true
    });

    const user: IUser = await User.create({
        name: name,
        highScore: 0,
    });

    return user._id.toString();
}

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