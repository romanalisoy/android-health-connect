import {Request, Response} from "express";
import HealthService from "../../core/services/health.service";

export default class HealthController {
    private service: HealthService;

    constructor() {
        this.service = new HealthService();
    }

    public store = async (request: Request, response: Response) => {
        const permissionName = request.params.PERMISSION_NAME;
        const {data} = request.body;

        const result = await this.service.store(permissionName, data);

        return response.status(200).json({
            status: true,
            inserted: result.inserted,
            skipped: result.skipped
        });
    }
}
