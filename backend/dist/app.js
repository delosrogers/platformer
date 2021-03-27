"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const path_1 = __importDefault(require("path"));
const mongoose_1 = require("mongoose");
const mongoose = require("mongoose");
const mongoose_2 = require("mongoose");
const passport_1 = __importDefault(require("passport"));
const passport_google_oauth_1 = __importDefault(require("passport-google-oauth"));
const cookie_session_1 = __importDefault(require("cookie-session"));
const crypto_random_string_1 = __importDefault(require("crypto-random-string"));
const https_1 = __importDefault(require("https"));
const fs_1 = __importDefault(require("fs"));
const csurf_1 = __importDefault(require("csurf"));
let hostName;
if (process.env.DEV != "TRUE") {
    hostName = "https://platformer.genedataexplorer.space";
}
else {
    hostName = "http://localhost";
}
const GoogleStrategy = passport_google_oauth_1.default.OAuth2Strategy;
require('dotenv').config();
passport_1.default.use(new GoogleStrategy({
    clientID: process.env.GOOGLE_CLIENT_ID,
    clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    callbackURL: hostName + ":3000/auth/google/callback",
}, function (accessToken, refreshToken, profile, done) {
    mongoose_1.connect('mongodb://localhost:27017/platformer', {
        useNewUrlParser: true,
        useUnifiedTopology: true
    });
    User.findOne({ googleId: profile.id }, (err, user) => {
        if (user) {
            done(err, user);
        }
        else {
            User.create({
                googleId: profile.id,
                name: profile.displayName,
                highScore: 0,
            }, (err, user) => {
                done(err, user);
            });
        }
    });
}));
mongoose.set('toJSON', { transform: true, flattenDecimals: true });
const UserSchema = new mongoose_2.Schema({
    name: { type: String, required: true },
    highScore: { type: Number, required: true },
    googleId: { type: String, required: true },
});
const User = mongoose_2.model('User', UserSchema);
const csrfProtection = csurf_1.default();
const app = express_1.default();
app.use(express_1.default.json());
app.use(cookie_session_1.default({
    name: 'session',
    maxAge: 24 * 60 * 60 * 1000,
    keys: [crypto_random_string_1.default({ length: 64 })]
}));
app.use(passport_1.default.initialize());
app.use(passport_1.default.session());
app.set('view engine', 'ejs');
if (process.env.DEV != "TRUE") {
    const privateKey = fs_1.default.readFileSync(process.env.PRIVKEYPATH, 'utf8');
    const certificate = fs_1.default.readFileSync(process.env.CERTPATH, 'utf8');
    const credentials = { key: privateKey, cert: certificate };
    const httpsServer = https_1.default.createServer(credentials, app);
    httpsServer.listen(3000, "platformer.genedataexplorer.space", () => console.log("listening on port 3000"));
}
else {
    const port = 3000;
    app.listen(port, () => console.log("listening on port ", port));
}
passport_1.default.serializeUser(function (user, done) {
    done(null, user._id);
});
passport_1.default.deserializeUser(function (id, done) {
    User.findById(id)
        .then((user) => done(null, user));
});
app.get('/', csrfProtection, (req, res) => {
    console.log("current user: ", req.user);
    res.render('elm.ejs', { user: req.user, csrfToken: req.csrfToken() });
});
app.get('/elm.js', (req, res) => {
    res.sendFile(path_1.default.join(__dirname + '/static/elm.js'));
});
app.get('/auth/google', passport_1.default.authenticate('google', { scope: ['https://www.googleapis.com/auth/plus.login', 'profile', 'email'] }));
app.get('/auth/google/callback', passport_1.default.authenticate('google', { failureRedirect: '/' }), (req, res) => res.redirect('/'));
app.get('/api/v1/u/:id', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const userID = req.params.id;
    const currUser = req.user;
    if (userID != (currUser === null || currUser === void 0 ? void 0 : currUser._id)) {
        console.log("un authenticated get current user id was", currUser);
        res.sendStatus(404);
        return;
    }
    const user = yield getUser(userID);
    if (user) {
        res.send(user);
    }
    else {
        console.log("couldn't find user");
        res.sendStatus(404);
    }
}));
app.post('/api/v1/u', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    res.sendStatus(418);
    // const userName = req.body.name;
    // const id = await newUser(userName);
    // if (id) {
    //     res.send({ _id: id, name: userName, highScore: 0 });
    // } else {
    //     res.sendStatus(418);
    // }
}));
app.put('/api/v1/u/:id/highscore', csrfProtection, (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    console.log(req.session);
    const id = req.params.id;
    const currUser = req.user;
    if (id != (currUser === null || currUser === void 0 ? void 0 : currUser._id)) {
        res.sendStatus(404);
        return;
    }
    const score = req.body.score;
    try {
        yield newHighScore(score, id);
        res.sendStatus(200);
    }
    catch (e) {
        console.log(e.message);
        if (e.message == "No Such User") {
            res.sendStatus(404);
        }
        else {
            res.sendStatus(418);
        }
    }
}));
function getUser(id) {
    return __awaiter(this, void 0, void 0, function* () {
        yield mongoose_1.connect('mongodb://localhost:27017/platformer', {
            useNewUrlParser: true,
            useUnifiedTopology: true
        });
        return yield User.findById(id).exec();
    });
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
function newHighScore(score, id) {
    return __awaiter(this, void 0, void 0, function* () {
        yield mongoose_1.connect('mongodb://localhost:27017/platformer', {
            useNewUrlParser: true,
            useUnifiedTopology: true
        });
        let user = yield User.findOne({ _id: id });
        if (!user) {
            console.log("couldn't find user");
            throw new Error('No Such User');
        }
        user.highScore = Math.max(score, user.highScore);
        yield user.save();
    });
}
//# sourceMappingURL=app.js.map