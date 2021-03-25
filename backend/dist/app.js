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
const mongoose_2 = require("mongoose");
const UserSchema = new mongoose_2.Schema({
    name: { type: String, required: true },
    highScore: { type: Number, required: true },
});
const User = mongoose_2.model('User', UserSchema);
const app = express_1.default();
app.use(express_1.default.json());
const port = 3000;
app.get('/', (req, res) => {
    console.log(req);
    res.sendFile(path_1.default.join(__dirname + '/static/elm.html'));
});
app.get('/elm.js', (req, res) => {
    res.sendFile(path_1.default.join(__dirname + '/static/elm.js'));
});
app.get('/api/v1/u/:id', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const userID = req.params.id;
    const user = yield getUser(userID);
    res.send(user);
}));
app.post('/api/v1/u', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const userName = req.body.name;
    const id = yield newUser(userName);
    res.send({ _id: id, name: userName, highScore: 0 });
}));
app.put('/api/v1/u/:id/highscore', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const id = req.params.id;
    const score = req.body.score;
    yield newHighScore(score, id);
    res.send(200);
}));
app.get('/');
app.listen(port, () => console.log("serving on port" + port));
function getUser(id) {
    return __awaiter(this, void 0, void 0, function* () {
        yield mongoose_1.connect('mongodb://localhost:27017/platformer', {
            useNewUrlParser: true,
            useUnifiedTopology: true
        });
        return yield User.findById(id).exec();
    });
}
function newUser(name) {
    return __awaiter(this, void 0, void 0, function* () {
        yield mongoose_1.connect('mongodb://localhost:27017/platformer', {
            useNewUrlParser: true,
            useUnifiedTopology: true
        });
        const user = yield User.create({
            name: name,
            highScore: 0,
        });
        return user._id.toString();
    });
}
function newHighScore(score, id) {
    return __awaiter(this, void 0, void 0, function* () {
        yield mongoose_1.connect('mongodb://localhost:27017/platformer', {
            useNewUrlParser: true,
            useUnifiedTopology: true
        });
        yield User.updateOne({ _id: id }, { highScore: score });
    });
}
//# sourceMappingURL=app.js.map