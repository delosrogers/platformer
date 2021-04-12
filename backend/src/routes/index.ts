import express, { ErrorRequestHandler, NextFunction } from 'express'


import { getApiRoutes } from './api'
import { getGameRoutes } from './game'
import { getAuthRoutes } from './auth'
import logger from 'loglevel'

function getRoutes() {
    const router = express.Router()



    router.use('/api/v1', getApiRoutes())
    router.use('/', getGameRoutes())
    router.use('/auth', getAuthRoutes())

    router.use((err, req, res, next) => {
        if (err.code !== 'EBADCSRFTOKEN') { return next(err) }

        logger.warn("CSRF error with user: ", req.user)
        res.status(403);
        res.send('form tampered with');
    });

    router.use(errorHandler)
    return router
}

function errorHandler(err, req, res, next) {
    if (res.headersSent) {
        next(err)
    } else {
        logger.error(Date.now(), err.error)
        logger.error(err.stack)
        res.sendStatus(500)
    }


}

export { getRoutes }