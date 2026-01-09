import multer, {FileFilterCallback} from 'multer';
import path from 'path';
import fs from 'fs';
import {Request} from 'express';
import {randomUUID} from 'crypto';

const UPLOAD_DIR = path.join(process.cwd(), 'public', 'uploads', 'profiles');

if (!fs.existsSync(UPLOAD_DIR)) {
    fs.mkdirSync(UPLOAD_DIR, {recursive: true});
}

const storage = multer.diskStorage({
    destination: (_req, _file, cb) => {
        cb(null, UPLOAD_DIR);
    },
    filename: (_req, file, cb) => {
        const ext = path.extname(file.originalname);
        const filename = `${randomUUID()}${ext}`;
        cb(null, filename);
    }
});

const fileFilter = (_req: Request, file: Express.Multer.File, cb: FileFilterCallback) => {
    const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/jpg'];
    
    if (allowedMimeTypes.includes(file.mimetype)) {
        cb(null, true);
    } else {
        cb(new Error('Only image files are allowed (jpeg, png, gif, webp, jpg). Current type: ' + file.mimetype));
    }
};

export const profileUpload = multer({
    storage,
    fileFilter,
    limits: {
        fileSize: 5 * 1024 * 1024 // 5MB
    }
});

export function getProfilePictureUrl(filename: string): string {
    return `/uploads/profiles/${filename}`;
}

export function deleteProfilePicture(filename: string): void {
    const filePath = path.join(UPLOAD_DIR, filename);
    if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
    }
}
