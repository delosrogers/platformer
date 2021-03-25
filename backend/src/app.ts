import express from 'express';
import path from 'path';
import mongoose, { connect } from 'mongoose';
import { model, Schema, Model, Document } from 'mongoose';


interface IUser extends Document {
    name: string,
    highScore: number
}

const UserSchema: Schema = new Schema({
    name: { type: String, required: true },
    highScore: { type: Number, required: true },
});

const User: Model<IUser> = model('User', UserSchema);


const app = express();
app.use(express.json());

const port = 3000;
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname + '/static/elm.html'));
});

app.get('/elm.js', (req, res) => {
    res.sendFile(path.join(__dirname + '/static/elm.js'));
});

app.get('/api/v1/u/:id', async (req, res) => {
    console.log("got an api get request");
    const userID = req.params.id;
    const user: IUser = await getUser(userID);
    res.send(user);
});

app.post('/api/v1/u', async (req, res) => {
    const userName = req.body.name;
    const id = await newUser(userName);
    res.send({ _id: id, name: userName, highScore: 0 });

});

app.put('/api/v1/u/:id/highscore', async (req, res) => {
    const id: string = req.params.id;
    const score: number = req.body.score;
    await newHighScore(score, id);
    res.sendStatus(200);
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

    await User.updateOne({ _id: id }, { highScore: score });
}