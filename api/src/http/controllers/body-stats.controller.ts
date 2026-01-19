import {Request, Response} from 'express';
import {HttpStatusCode} from "axios";
import BodyStatsService from "../../core/services/body-stats.service";
import {BodyStatField, HistoryPeriod} from "../../../types/body-stats";

const VALID_FIELDS: BodyStatField[] = [
    'waist', 'neck', 'chest', 'right_arm', 'left_arm',
    'right_forearm', 'left_forearm', 'shoulders',
    'hips', 'right_thigh', 'left_thigh', 'right_calve', 'left_calve',
    'weight', 'height', 'bmi'
];

const VALID_PERIODS: HistoryPeriod[] = ['month', 'year', 'all'];

export default class BodyStatsController {
    private service: BodyStatsService;

    constructor() {
        this.service = new BodyStatsService();
    }

    public update = async (request: Request, response: Response) => {
        try {
            const user = request.user!;
            const data = request.body;
console.log(data);
            const bodyStats = await this.service.createOrUpdateToday(user.id, data);

            return response.status(HttpStatusCode.Ok).json({
                success: true,
                message: 'Body stats updated successfully',
                data: {
                    id: bodyStats.id,
                    record_date: bodyStats.record_date,
                    waist: bodyStats.waist,
                    neck: bodyStats.neck,
                    chest: bodyStats.chest,
                    right_arm: bodyStats.right_arm,
                    left_arm: bodyStats.left_arm,
                    right_forearm: bodyStats.right_forearm,
                    left_forearm: bodyStats.left_forearm,
                    shoulders: bodyStats.shoulders,
                    hips: bodyStats.hips,
                    right_thigh: bodyStats.right_thigh,
                    left_thigh: bodyStats.left_thigh,
                    right_calve: bodyStats.right_calve,
                    left_calve: bodyStats.left_calve,
                    created_at: bodyStats.created_at,
                    updated_at: bodyStats.updated_at
                }
            });
        } catch (error) {
            const message = error instanceof Error ? error.message : 'An error occurred';

            return response.status(HttpStatusCode.BadRequest).json({
                success: false,
                message
            });
        }
    }

    public getHistory = async (request: Request, response: Response) => {
        try {
            const user = request.user!;
            const field = request.params.field as BodyStatField;
            const period = (request.query.period || 'month') as HistoryPeriod;

            if (!VALID_FIELDS.includes(field)) {
                return response.status(HttpStatusCode.BadRequest).json({
                    success: false,
                    message: `Invalid field. Must be one of: ${VALID_FIELDS.join(', ')}`
                });
            }

            if (!VALID_PERIODS.includes(period)) {
                return response.status(HttpStatusCode.BadRequest).json({
                    success: false,
                    message: `Invalid period. Must be one of: ${VALID_PERIODS.join(', ')}`
                });
            }

            const history = await this.service.getHistory(user.id, field, period);

            return response.status(HttpStatusCode.Ok).json({
                success: true,
                data: {
                    field,
                    period,
                    history
                }
            });
        } catch (error) {
            const message = error instanceof Error ? error.message : 'An error occurred';

            return response.status(HttpStatusCode.BadRequest).json({
                success: false,
                message
            });
        }
    }

    public getLatest = async (request: Request, response: Response) => {
        try {
            const user = request.user!;

            const latest = await this.service.getLatest(user.id);

            return response.status(HttpStatusCode.Ok).json({
                success: true,
                data: latest
            });
        } catch (error) {
            const message = error instanceof Error ? error.message : 'An error occurred';

            return response.status(HttpStatusCode.BadRequest).json({
                success: false,
                message
            });
        }
    }
}
