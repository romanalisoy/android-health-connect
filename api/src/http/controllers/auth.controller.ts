import {Request, Response} from 'express';
import AuthService from "../../core/services/auth.service";
import {HttpStatusCode} from "axios";
import { log } from 'console';


export default class AuthController {
    private service: AuthService;

    constructor() {
        this.service = new AuthService();
    }

    public login = async (request: Request, response: Response) => {
        try {
            const {email, password} = request.body;

            const result = await this.service.login({email, password});

            return response.status(HttpStatusCode.Ok).json({
                success: true,
                message: 'Login successful',
                data: result
            });
        } catch (error) {
            const message = error instanceof Error ? error.message : 'An error occurred';

            return response.status(HttpStatusCode.Unauthorized).json({
                success: false,
                message
            });
        }
    }

    public refreshToken = async (request: Request, response: Response) => {
        try {
            const {refreshToken} = request.body;

            const tokens = await this.service.refreshToken(refreshToken);

            return response.status(HttpStatusCode.Ok).json({
                success: true,
                message: 'Token refreshed successfully',
                data: tokens
            });
        } catch (error) {
            const message = error instanceof Error ? error.message : 'An error occurred';

            return response.status(HttpStatusCode.Unauthorized).json({
                success: false,
                message
            });
        }
    }

    public revokeToken = async (request: Request, response: Response) => {
        try {
            const {refreshToken} = request.body;

            await this.service.revokeToken(refreshToken);

            return response.status(HttpStatusCode.Ok).json({
                success: true,
                message: 'Token revoked successfully'
            });
        } catch (error) {
            const message = error instanceof Error ? error.message : 'An error occurred';

            return response.status(HttpStatusCode.BadRequest).json({
                success: false,
                message
            });
        }
    }

    public updateFcmToken = async (request: Request, response: Response) => {
        try {
            const {fcmToken} = request.body;
            const user = request.user!;

            await this.service.updateFcmToken(user.id, fcmToken);

            return response.status(HttpStatusCode.Ok).json({
                success: true,
                message: 'FCM token updated successfully'
            });
        } catch (error) {
            const message = error instanceof Error ? error.message : 'An error occurred';
log(error)
            return response.status(HttpStatusCode.BadRequest).json({
                success: false,
                message
            });
        }
    }

    public me = async (request: Request, response: Response) => {
        const user = request.user!;

        return response.status(HttpStatusCode.Ok).json({
            success: true,
            data: {
                id: user.id,
                email: user.email,
                full_name: user.full_name,
                birthdate: user.birthdate,
                profile_picture: user.profile_picture ?? null,
                created_at: user.created_at,
                updated_at: user.updated_at
            }
        });
    }

    public updateProfile = async (request: Request, response: Response) => {
        try {
            const user = request.user!;
            const {full_name, email, birthdate} = request.body;

            const updatedUser = await this.service.updateProfile(user.id, {full_name, email, birthdate});

            return response.status(HttpStatusCode.Ok).json({
                success: true,
                message: 'Profile updated successfully',
                data: {
                    id: updatedUser.id,
                    email: updatedUser.email,
                    full_name: updatedUser.full_name,
                    birthdate: updatedUser.birthdate,
                    profile_picture: updatedUser.profile_picture,
                    created_at: updatedUser.created_at,
                    updated_at: updatedUser.updated_at
                }
            });
        } catch (error) {
            const message = error instanceof Error ? error.message : 'An error occurred';

            return response.status(HttpStatusCode.BadRequest).json({
                success: false,
                message
            });
        }
    }

    public updateProfilePicture = async (request: Request, response: Response) => {
        try {
            const user = request.user!;

            if (!request.file) {
                return response.status(HttpStatusCode.BadRequest).json({
                    success: false,
                    message: 'Profile picture is required'
                });
            }

            const profilePictureUrl = await this.service.updateProfilePicture(user.id, request.file.filename);

            return response.status(HttpStatusCode.Ok).json({
                success: true,
                message: 'Profile picture updated successfully',
                data: {
                    profile_picture: profilePictureUrl
                }
            });
        } catch (error) {
            const message = error instanceof Error ? error.message : 'An error occurred';

            return response.status(HttpStatusCode.BadRequest).json({
                success: false,
                message
            });
        }
    }

    public changePassword = async (request: Request, response: Response) => {
        try {
            const user = request.user!;
            const {current_password, new_password, password_confirmation} = request.body;

            await this.service.changePassword(user.id, {
                current_password,
                new_password,
                password_confirmation
            });

            return response.status(HttpStatusCode.Ok).json({
                success: true,
                message: 'Password changed successfully'
            });
        } catch (error) {
            const message = error instanceof Error ? error.message : 'An error occurred';

            return response.status(HttpStatusCode.BadRequest).json({
                success: false,
                message
            });
        }
    }
}
