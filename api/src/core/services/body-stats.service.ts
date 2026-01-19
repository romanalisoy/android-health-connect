import {randomUUID} from 'crypto';
import BodyStats from "../../database/entities/BodyStats";
import BodyMeasurementHeight from "../../database/entities/health/BodyMeasurementHeight";
import BodyMeasurementWeight from "../../database/entities/health/BodyMeasurementWeight";
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

    private getStartTimestamp(period: HistoryPeriod): number | null {
        const now = new Date();

        switch (period) {
            case 'month':
                now.setMonth(now.getMonth() - 1);
                return now.getTime();
            case 'year':
                now.setFullYear(now.getFullYear() - 1);
                return now.getTime();
            case 'all':
                return null;
        }
    }

    private epochToDateString(epoch: number): string {
        return new Date(epoch).toISOString().split('T')[0];
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
        // Handle weight from BodyMeasurementWeight table
        if (field === 'weight') {
            return this.getWeightHistory(period);
        }

        // Handle height from BodyMeasurementHeight table
        if (field === 'height') {
            return this.getHeightHistory(period);
        }

        // Handle BMI calculation from weight and height
        if (field === 'bmi') {
            return this.getBmiHistory(period);
        }

        // Original logic for BodyStats fields
        const startDate = this.getStartDate(period);

        // Query Mongo with $gte on ISO date strings to avoid in-memory filtering cost
        const mongoRepo = AppDataSource.getMongoRepository(BodyStats);
        const records = await mongoRepo.find({
            where: startDate
                ? {user_id: userId, record_date: {$gte: startDate}}
                : {user_id: userId},
            order: {record_date: 'ASC'}
        });

        return records
            .filter(record => record[field] !== null)
            .map(record => ({
                record_date: record.record_date,
                value: record[field] as number | null
            }));
    }

    private async getWeightHistory(period: HistoryPeriod): Promise<BodyStatHistoryItem[]> {
        const startTimestamp = this.getStartTimestamp(period);
        const mongoRepo = AppDataSource.getMongoRepository(BodyMeasurementWeight);

        const records = await mongoRepo.find({
            where: startTimestamp
                ? {time: {$gte: startTimestamp}}
                : {},
            order: {time: 'ASC'}
        });

        return records.map(record => ({
            record_date: this.epochToDateString(record.time),
            value: record.weight
        }));
    }

    private async getHeightHistory(period: HistoryPeriod): Promise<BodyStatHistoryItem[]> {
        const startTimestamp = this.getStartTimestamp(period);
        const mongoRepo = AppDataSource.getMongoRepository(BodyMeasurementHeight);

        const records = await mongoRepo.find({
            where: startTimestamp
                ? {time: {$gte: startTimestamp}}
                : {},
            order: {time: 'ASC'}
        });

        return records.map(record => ({
            record_date: this.epochToDateString(record.time),
            value: record.height
        }));
    }

    private async getBmiHistory(period: HistoryPeriod): Promise<BodyStatHistoryItem[]> {
        const startTimestamp = this.getStartTimestamp(period);
        const weightRepo = AppDataSource.getMongoRepository(BodyMeasurementWeight);
        const heightRepo = AppDataSource.getMongoRepository(BodyMeasurementHeight);

        // Get weight records
        const weightRecords = await weightRepo.find({
            where: startTimestamp
                ? {time: {$gte: startTimestamp}}
                : {},
            order: {time: 'ASC'}
        });

        // Get the latest height (height changes rarely)
        const latestHeight = await heightRepo.findOne({
            where: {},
            order: {time: 'DESC'}
        });

        if (!latestHeight || latestHeight.height <= 0) {
            return [];
        }

        // Height in meters (assuming stored in cm)
        const heightInMeters = latestHeight.height;

        // Calculate BMI for each weight record
        return weightRecords.map(record => ({
            record_date: this.epochToDateString(record.time),
            value: Math.round((record.weight / (heightInMeters * heightInMeters)) * 10) / 10
        }));
    }

    public async getLatest(userId: string): Promise<LatestBodyStats> {
        const result: LatestBodyStats = {} as LatestBodyStats;

        // Get latest weight from BodyMeasurementWeight
        const latestWeight = await AppDataSource.getMongoRepository(BodyMeasurementWeight).findOne({
            where: {},
            order: {time: 'DESC'}
        });

        result['weight'] = {
            value: latestWeight ? latestWeight.weight : null,
            record_date: latestWeight ? this.epochToDateString(latestWeight.time) : null
        };

        // Get latest height from BodyMeasurementHeight
        const latestHeight = await AppDataSource.getMongoRepository(BodyMeasurementHeight).findOne({
            where: {},
            order: {time: 'DESC'}
        });

        result['height'] = {
            value: latestHeight ? latestHeight.height : null,
            record_date: latestHeight ? this.epochToDateString(latestHeight.time) : null
        };

        // Calculate BMI from latest weight and height
        if (latestWeight && latestHeight && latestHeight.height > 0) {
            const heightInMeters = latestHeight.height;
            const bmiValue = Math.round((latestWeight.weight / (heightInMeters * heightInMeters)) * 10) / 10;
            // Use the more recent date between weight and height
            const bmiDate = latestWeight.time >= latestHeight.time
                ? latestWeight.time
                : latestHeight.time;

            result['bmi'] = {
                value: bmiValue,
                record_date: this.epochToDateString(bmiDate)
            };
        } else {
            result['bmi'] = {
                value: null,
                record_date: null
            };
        }

        // Get other fields from BodyStats
        for (const field of BODY_STAT_FIELDS) {

            // Find the most recent record with a non-null value for this field
            const records = await BodyStats.find({
                where: {user_id: userId},
                order: {record_date: 'DESC'}
            });

            const latestWithValue = records.find(r => r[field] != null);

            result[field] = {
                value: latestWithValue?.[field] as number | null ?? null,
                record_date: latestWithValue?.record_date ?? null
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
