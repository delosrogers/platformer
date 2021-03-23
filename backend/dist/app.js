"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const path_1 = __importDefault(require("path"));
const app = express_1.default();
const port = 3000;
app.get('/', (req, res) => {
    console.log(req);
    res.sendFile(path_1.default.join(__dirname + '/elm.html'));
});
app.get('/elm.js', (req, res) => {
    res.sendFile(path_1.default.join(__dirname + '/elm.js'));
});
app.get('/');
app.listen(port);
//# sourceMappingURL=app.js.map