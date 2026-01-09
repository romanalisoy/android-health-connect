export interface User {
    id: string;
    email: string;
    password: string;
    fcmToken: string;
    full_name: string;
    birthdate: Date | string | null;
    profile_picture: string | null;
    created_at: Date | string;
    updated_at: Date | string;
}

export interface UpdateProfileData {
    full_name?: string;
    email?: string;
    birthdate?: Date | string;
}

export interface ChangePasswordData {
    current_password: string;
    new_password: string;
    password_confirmation: string;
}
