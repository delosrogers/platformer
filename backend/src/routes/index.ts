import express from 'express'


import { getApiRoutes } from './api'
import { getGameRoutes } from './game'

function getRoutes() {


    const router = express.Router()

    router.use('/api/v1', getApiRoutes())
    router.use('/', getGameRoutes())


    return router

}

export { getRoutes }