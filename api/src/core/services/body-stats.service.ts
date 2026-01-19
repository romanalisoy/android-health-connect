import {randomUUID} from 'crypto';
import {MoreThanOrEqual} from 'typeorm';
import BodyStats from "../../database/entities/BodyStats";
import AppDataSource from "../configs/datasource.config";
import {BodyStatsData, BodyStatField, HistoryPeriod, BodyStatHistoryItem, LatestBodyStats} from "../../../types/body-stats";

const BODY_STAT_FIELDS: BodyStatField[] = [
    'waist', 'neck', 'chest', 'right_arm', 'left_arm',
    'right_forearm', 'left_forearm', 'shoulders',
    'hips', 'right_thigh', 'left_thigh', 'right_calve', 'left_calve'
];

export default class BodyStatsService {
    private getTodayDate(): string {
        return new Date().toISOString().split('T')[0]; // yyyy-mm-dd
    }

    private getStartDate(period: HistoryPeriod): string | null {
        const now = new Date();

        switch (period) {
            case 'month':
                now.setMonth(now.getMonth() - 1);
                return now.toISOString().split('T')[0];
            case 'year':
                now.setFullYear(now.getFullYear() - 1);
                return now.toISOString().split('T')[0];
            case 'all':
                return null;
        }
    }

    public async createOrUpdateToday(userId: string, data: BodyStatsData): Promise<BodyStats> {
        try {
            const today = this.getTodayDate();

        let bodyStats = await BodyStats.findOne({
            where: {user_id: userId, record_date: today}
        });

        if (!bodyStats) {
            const newId = randomUUID();
            const now = new Date();
            const mongoRepo = AppDataSource.getMongoRepository(BodyStats);
            await mongoRepo.insertOne({
                id: newId,
                user_id: userId,
                record_date: today,
                created_at: now,
                updated_at: now,
                ...data
            });
            bodyStats = await BodyStats.findOne({
                where: {id: newId}
            });
        } else {
            await BodyStats.update(
                {user_id: userId, record_date: today},
                data
            );
            bodyStats = await BodyStats.findOne({
                where: {user_id: userId, record_date: today}
            });
        }

        return bodyStats!;
        } catch (error) {
            console.error('Error in createOrUpdateToday:', error);
            throw new Error('Failed to create or update body stats');
        }
    }

    public async getHistory(
        userId: string,
        field: BodyStatField,
        period: HistoryPeriod
    ): Promise<BodyStatHistoryItem[]> {
        const startDate = this.getStartDate(period);

        let whereCondition: any = {user_id: userId};

        if (startDate) {
            whereCondition.record_date = MoreThanOrEqual(startDate);
        }

        const records = await BodyStats.find({
            where: whereCondition,
            order: {record_date: 'ASC'}
        });

        return records
            .filter(record => record[field] !== null)
            .map(record => ({
                record_date: record.record_date,
                value: record[field] as number | null
            }));
    }

    public async getLatest(userId: string): Promise<LatestBodyStats> {
        const result: LatestBodyStats = {} as LatestBodyStats;

        for (const field of BODY_STAT_FIELDS) {
            const record = await BodyStats.findOne({
                where: {user_id: userId},
                order: {record_date: 'DESC'}
            });

            // Find the most recent record with a non-null value for this field
            const records = await BodyStats.find({
                where: {user_id: userId},
                order: {record_date: 'DESC'}
            });

            const latestWithValue = records.find(r => r[field] !== null);

            result[field] = {
                value: latestWithValue ? latestWithValue[field] as number | null : null,
                record_date: latestWithValue ? latestWithValue.record_date : null
            };
        }

        return result;
    }

    public async getTodayStats(userId: string): Promise<BodyStats | null> {
        const today = this.getTodayDate();
        return await BodyStats.findOne({
            where: {user_id: userId, record_date: today}
        });
    }
}
