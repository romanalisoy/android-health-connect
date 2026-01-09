import {Request, Response} from "express";
import HealthService from "../../core/services/health.service";

export default class HealthController {
    private service: HealthService;

    constructor() {
        this.service = new HealthService();
    }

    public checkPermission = async (request: Request, response: Response) => {
        const permissionName = request.params.PERMISSION_NAME;
        await this.service.logPermission(permissionName, request.body?? null);

        return response.status(200).json({
            status: true
        });
    }
}
