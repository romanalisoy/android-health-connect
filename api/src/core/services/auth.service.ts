import bcrypt from 'bcrypt';
import User from "../../database/entities/User";
import {generateTokenPair, verifyRefreshToken} from "../utils/jwt.util";
import {TokenPair, TokenPayload, LoginCredentials, AuthResponse} from "../../../types/auth";
import {UpdateProfileData, ChangePasswordData} from "../../../types/user";
import {deleteProfilePicture, getProfilePictureUrl} from "../utils/upload.util";

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

    public async updateProfile(userId: string, data: UpdateProfileData): Promise<User> {
        // Check if email is being updated and if it's already taken
        if (data.email) {
            const existingUser = await User.findOne({where: {email: data.email}});
            if (existingUser && existingUser.id !== userId) {
                throw new Error('Email is already in use');
            }
        }

        const result = await User.update({id: userId}, data);

        if (result.affected === 0 && result.raw.matchedCount === 0) {
            throw new Error('User not found');
        }

        const user = await User.findOne({where: {id: userId}});
        return user!;
    }

    public async updateProfilePicture(userId: string, filename: string): Promise<string> {
        const user = await User.findOne({where: {id: userId}});

        if (!user) {
            throw new Error('User not found');
        }

        // Delete old profile picture if exists
        if (user.profile_picture) {
            const oldFilename = user.profile_picture.split('/').pop();
            if (oldFilename) {
                deleteProfilePicture(oldFilename);
            }
        }

        const profilePictureUrl = getProfilePictureUrl(filename);
        await User.update({id: userId}, {profile_picture: profilePictureUrl});

        return profilePictureUrl;
    }

    public async changePassword(userId: string, data: ChangePasswordData): Promise<void> {
        const user = await User.findOne({where: {id: userId}});

        if (!user) {
            throw new Error('User not found');
        }

        const isCurrentPasswordValid = await bcrypt.compare(data.current_password, user.password);

        if (!isCurrentPasswordValid) {
            throw new Error('Current password is incorrect');
        }

        const hashedPassword = await bcrypt.hash(data.new_password, 10);
        await User.update({id: userId}, {password: hashedPassword});
    }
}
