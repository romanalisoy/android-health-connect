export interface User {
    id: string;
    organization_id: string;
    name: string;
    surname: string;
    father_name: string;
    phone_number: string;
    email: string;
    birthday: DateString;
    is_manager: "0" | "1";
    created_at: DateString;
    updated_at: DateString;
    email_verified_at: DateString | null;
    deleted_at: DateString | null;
}