
import { connect } from 'mongoose';
import mongoose = require('mongoose')
import { model, Schema, Model, Document } from 'mongoose';

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


function userLogin(accessToken: string, refreshToken: string, profile, done) {
    connect('mongodb://platformer-mongodb:27017/platformer', {
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
async function getAllUsers(): Promise<IUser[]> {
    await connect('mongodb://platformer-mongodb:27017/platformer', {
        useNewUrlParser: true,
        useUnifiedTopology: true
    });
    let users: IUser[];
    try {
        users = await User.find().exec();
    } catch {
        throw Error("error getting all users");
    }


    return users;
}


async function getUser(id: string): Promise<IUser> {
    await connect('mongodb://platformer-mongodb:27017/platformer', {
        useNewUrlParser: true,
        useUnifiedTopology: true
    });

    return await User.findById(id).exec();
}


async function newHighScore(score: number, id: string) {
    await connect('mongodb://platformer-mongodb:27017/platformer', {
        useNewUrlParser: true,
        useUnifiedTopology: true
    });

    let user = await User.findOne({ _id: id });
    if (!user) {
        console.log("couldn't find user");
        throw new Error('No Such User');
    }

    user.highScore = Math.max(score, user.highScore);
    await user.save();
}

export { userLogin, getAllUsers, getUser, newHighScore, IUser }