import {Routing} from "../../core/infrastructure/init.routes.impl";

import {
    loginValidation,
    refreshTokenValidation,
    revokeTokenValidation,
    updateFcmTokenValidation,
    updateProfileValidation,
    changePasswordValidation
} from "../validations/auth.validation";

import {authMiddleware} from "../middlewares/auth.middleware";
import {profileUpload} from "../../core/utils/upload.util";
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

router
    .middleware(authMiddleware)
    .validation(updateProfileValidation)
    .put('/me', [AuthController, 'updateProfile']);

router
    .middleware(authMiddleware)
    .middleware(profileUpload.single('profile_picture'))
    .post('/profile-picture', [AuthController, 'updateProfilePicture']);

router
    .middleware(authMiddleware)
    .validation(changePasswordValidation)
    .put('/change-password', [AuthController, 'changePassword']);

export default {
    router: router.getRouter(),
    prefix: 'auth',
    apiVersion: 1
};
