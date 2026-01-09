import {Routing} from "../../core/infrastructure/init.routes.impl";
import {authMiddleware} from "../middlewares/auth.middleware";
import {updateBodyStatsValidation} from "../validations/body-stats.validation";
import BodyStatsController from "../controllers/body-stats.controller";

const router: Routing = new Routing();

// Get latest values for all body stats
router
    .middleware(authMiddleware)
    .get('/latest', [BodyStatsController, 'getLatest']);

// Get history for a specific body stat field
// GET /body-stats/history/:field?period=month|year|all
router
    .middleware(authMiddleware)
    .get('/history/:field', [BodyStatsController, 'getHistory']);

// Update today's body stats
router
    .middleware(authMiddleware)
    .validation(updateBodyStatsValidation)
    .put('/', [BodyStatsController, 'update']);

export default {
    router: router.getRouter(),
    prefix: 'body-stats',
    apiVersion: 1
};
