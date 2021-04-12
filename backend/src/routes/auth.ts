import express from 'express'
import passport from 'passport';

function getAuthRoutes() {
    let router = express.Router()

    router.get('/google',
        passport.authenticate(
            'google',
            { scope: ['https://www.googleapis.com/auth/plus.login', 'profile', 'email'] }));

    router.get('/google/callback', passport.authenticate('google', { failureRedirect: '/' }),
        (req, res) => res.redirect('/'));

    return router
}

export { getAuthRoutes }