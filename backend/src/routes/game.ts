import express from 'express'
import csurf from 'csurf'
import path from 'path';
import { logger } from '../logger'

function getGameRoutes() {
    let router = express.Router()
    const csrfProtection = csurf()
    router.get('/', csrfProtection, (req, res) => {
        logger.info("GET, ROUTE: /, current user: ", req.user);
        let scriptLocation: string;
        if (process.env.DEV != 'TRUE') {
            scriptLocation = "https://hl-platformer.netlify.app/elm.js"
        } else {
            scriptLocation = "elm.js"
        }
        res.render('elm.ejs', {
            user: req.user,
            csrfToken: req.csrfToken(),
            scriptLocation: scriptLocation,
        });
    });

    router.get('/elm.js', (req, res) => {
        res.sendFile(path.join(__dirname + '/../static/elm.js'));
    });
    return router
}

export { getGameRoutes }