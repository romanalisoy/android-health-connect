export interface User {
    id: string;
    email: string;
    password: string;
    fcmToken: string;
    full_name: string;
    created_at: Date | string;
    updated_at: Date | string;
}
