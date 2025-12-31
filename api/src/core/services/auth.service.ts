import bcrypt from 'bcrypt';
import User from "../../database/entities/User";
import {generateTokenPair, verifyRefreshToken} from "../utils/jwt.util";
import {TokenPair, TokenPayload, LoginCredentials, AuthResponse} from "../../../types/auth";
import { log } from 'console';

export default class AuthService {
    private revokedTokens: Set<string> = new Set();

    public async login(credentials: LoginCredentials): Promise<AuthResponse> {
        const {email, password} = credentials;

        const user = await User.findOne({where: {email}});

        if (!user) {
            throw new Error('Invalid email or password');
        }
        const isPasswordValid = await bcrypt.compare(password, user.password);

        if (!isPasswordValid) {
            throw new Error('Invalid email or password');
        }

        const tokenPayload: TokenPayload = {
            userId: user.id,
            email: user.email
        };

        const tokens = generateTokenPair(tokenPayload);

        return {
            user: {
                id: user.id,
                email: user.email,
                full_name: user.full_name
            },
            tokens
        };
    }

    public async refreshToken(refreshToken: string): Promise<TokenPair> {
        if (this.revokedTokens.has(refreshToken)) {
            throw new Error('Token is invalid');
        }

        const payload = verifyRefreshToken(refreshToken);

        if (!payload) {
            throw new Error('Refresh token is invalid or expired');
        }

        const user = await User.findOne({where: {id: payload.userId}});

        if (!user) {
            throw new Error('User not found');
        }

        const tokenPayload: TokenPayload = {
            userId: user.id,
            email: user.email
        };

        return generateTokenPair(tokenPayload);
    }

    public async revokeToken(refreshToken: string): Promise<void> {
        const payload = verifyRefreshToken(refreshToken);

        if (!payload) {
            throw new Error('Token is invalid');
        }

        this.revokedTokens.add(refreshToken);
    }

    public async updateFcmToken(userId: string, fcmToken: string): Promise<void> {
        const result = await User.update({id: userId}, {fcmToken});
        if (result.affected === 0 && result.raw.matchedCount === 0) {
            throw new Error('User not found');
        }
    }
}
