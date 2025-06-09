import {Request, Response} from 'express';
import AuthService from "../../core/services/auth.service";
import {HttpStatusCode} from "axios";


export default class AuthController {
    private service: AuthService;

    constructor() {
        this.service = new AuthService();
    }

    public login = async (request: Request, response: Response) => {}
    public refreshToken = async (request: Request, response: Response) => {}
    public revokeToken = async (request: Request, response: Response) => {}
}