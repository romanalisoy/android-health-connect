import jwt, {JwtPayload, SignOptions} from 'jsonwebtoken';
import {TokenPayload, TokenPair} from "../../../types/auth";

const JWT_SECRET = process.env.JWT_SECRET || 'your-super-secret-key-change-in-production';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'your-refresh-secret-key-change-in-production';

// Token expiry in seconds
const ACCESS_TOKEN_EXPIRY_SECONDS = parseInt(process.env.ACCESS_TOKEN_EXPIRY_SECONDS || '900'); // 15 minutes
const REFRESH_TOKEN_EXPIRY_SECONDS = parseInt(process.env.REFRESH_TOKEN_EXPIRY_SECONDS || '604800'); // 7 days

export function generateAccessToken(payload: TokenPayload): string {
    const options: SignOptions = {
        expiresIn: ACCESS_TOKEN_EXPIRY_SECONDS,
    };

    return jwt.sign(payload, JWT_SECRET, options);
}

export function generateRefreshToken(payload: TokenPayload): string {
    const options: SignOptions = {
        expiresIn: REFRESH_TOKEN_EXPIRY_SECONDS,
    };

    return jwt.sign(payload, JWT_REFRESH_SECRET, options);
}

export function generateTokenPair(payload: TokenPayload): TokenPair {
    return {
        accessToken: generateAccessToken(payload),
        refreshToken: generateRefreshToken(payload),
        expiresIn: ACCESS_TOKEN_EXPIRY_SECONDS,
    };
}

export function verifyAccessToken(token: string): TokenPayload | null {
    try {
        const decoded = jwt.verify(token, JWT_SECRET) as JwtPayload & TokenPayload;
        return {
            userId: decoded.userId,
            email: decoded.email,
        };
    } catch {
        return null;
    }
}

export function verifyRefreshToken(token: string): TokenPayload | null {
    try {
        const decoded = jwt.verify(token, JWT_REFRESH_SECRET) as JwtPayload & TokenPayload;
        return {
            userId: decoded.userId,
            email: decoded.email,
        };
    } catch {
        return null;
    }
}

export function extractTokenFromHeader(authHeader: string | undefined): string | null {
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return null;
    }
    return authHeader.substring(7);
}
