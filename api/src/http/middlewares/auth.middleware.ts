import {NextFunction, Request, Response} from "express";
import {HttpStatusCode} from "axios";
import {ObjectId} from "mongodb";
import {extractTokenFromHeader, verifyAccessToken} from "../../core/utils/jwt.util";
import User from "../../database/entities/User";

export async function authMiddleware(request: Request, response: Response, next: NextFunction) {
    const authHeader = request.headers.authorization;
    const token = extractTokenFromHeader(authHeader);

    if (!token) {
        return response.status(HttpStatusCode.Unauthorized).json({
            success: false,
            message: 'Authorization token is required'
        });
    }

    const payload = verifyAccessToken(token);

    if (!payload) {
        return response.status(HttpStatusCode.Unauthorized).json({
            success: false,
            message: 'Token is invalid or expired'
        });
    }

    const user = await User.findOne({where: {id: payload.userId}});

    if (!user) {
        return response.status(HttpStatusCode.Unauthorized).json({
            success: false,
            message: 'User not found'
        });
    }

    request.user = user;

    next();
}
