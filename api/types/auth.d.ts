export interface TokenPayload {
    userId: string;
    email: string;
}

export interface TokenPair {
    accessToken: string;
    refreshToken: string;
    expiresIn: number;
}

export interface LoginCredentials {
    email: string;
    password: string;
}

export interface AuthResponse {
    user: {
        id: string;
        email: string;
        full_name: string;
    };
    tokens: TokenPair;
}
