import {Routing} from "../../core/infrastructure/init.routes.impl";
import {healthPermissionValidation} from "../validations/health.validation";
import HealthController from "../controllers/health.controller";

const router: Routing = new Routing();
router
    .validation(healthPermissionValidation)
    .post('/archive', [HealthController, 'checkPermission']);
router
    .validation(healthPermissionValidation)
    .post('/:PERMISSION_NAME', [HealthController, 'checkPermission']);

export default {
    router: router.getRouter(),
    prefix: 'health',
    apiVersion: 1,
};
