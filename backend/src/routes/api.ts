import express from 'express'
import csurf from 'csurf'
import { IUser, getUser, getAllUsers, newHighScore } from '../db'

function getApiRoutes() {
    const csrfProtection = csurf();
    let router = express.Router()
    router.get('/u/:id', async (req, res) => {
        const userID = req.params.id;
        const currUser: any = req.user;
        if (userID != currUser?._id) {
            console.log("un authenticated get current user id was", currUser)
            res.sendStatus(404);
            return;
        }
        const user: IUser = await getUser(userID);
        if (user) {
            res.send(user);
        } else {
            console.log("couldn't find user");
            res.sendStatus(404);
        }
    });


    router.put('/u/:id/highscore', csrfProtection, async (req, res) => {
        const id: string = req.params.id;
        const currUser: any = req.user;
        console.log("PUT, ROUTE: /api/v1/u/" + id + "/highscore, user: ", currUser)
        if (id != currUser?._id) {
            console.log("not authenticated new highscore")
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

    router.get('/leaderboard', async (req, res) => {
        console.log("GET, ROUTE: /api/v1/leaderboard, user: ", req.user);
        if (!req.user) {
            res.sendStatus(418);
            return;
        }
        let users: IUser[];
        try {
            users = await getAllUsers();
        } catch {
            res.sendStatus(500);
            return;
        }
        const leaderboard = users.map((user) => {
            return { name: user.name, highScore: user.highScore }
        })
            .sort((first, second) => second.highScore - first.highScore)
            .slice(0, 10);
        res.send(leaderboard);
    })
    return router
}

export { getApiRoutes }