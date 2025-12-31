import {Routing} from "../../core/infrastructure/init.routes.impl";

import {
    loginValidation,
    refreshTokenValidation,
    revokeTokenValidation,
    updateFcmTokenValidation
} from "../validations/auth.validation";

import {authMiddleware} from "../middlewares/auth.middleware";
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

router
    .middleware(authMiddleware)
    .validation(updateFcmTokenValidation)
    .put('/fcm-token', [AuthController, 'updateFcmToken']);

router
    .middleware(authMiddleware)
    .get('/me', [AuthController, 'me']);

export default {
    router: router.getRouter(),
    prefix: 'auth',
    apiVersion: 1
};
