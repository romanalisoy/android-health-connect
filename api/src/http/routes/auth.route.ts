import {Routing} from "../../core/infrastructure/init.routes.impl";

import {loginValidation, refreshTokenValidation, revokeTokenValidation} from "../validations/auth.validation";
import AuthController from "../controllers/auth.controller";

const router: Routing = new Routing();

router
    .validation(loginValidation)
    .post('/login', [AuthController, 'login']);
router
    .validation(refreshTokenValidation)
    .post('/refresh-token', [AuthController, 'refreshToken']);

router
    .validation(revokeTokenValidation)
    .delete('/revoke-token', [AuthController, 'revokeToken']);

export default {
    router: router.getRouter(),
    prefix: '/auth',
    apiVersion: 1
};
