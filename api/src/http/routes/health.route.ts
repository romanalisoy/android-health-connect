import {Routing} from "../../core/infrastructure/init.routes.impl";
import {healthDataValidation} from "../validations/health.validation";
import HealthController from "../controllers/health.controller";

const router: Routing = new Routing();

router
    .validation(healthDataValidation)
    .post('/:PERMISSION_NAME', [HealthController, 'store']);

router
    .post('/archive', [HealthController, 'checkPermission']);
export default {
    router: router.getRouter(),
    prefix: 'health',
    apiVersion: 1,
};
