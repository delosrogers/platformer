
import logger from 'loglevel'

if (process.env.DEV !== "TRUE") {
    logger.setLevel("info")
} else {
    logger.setLevel("trace");
}

export { logger }