import AppDataSource from "../configs/datasource.config";
import type {HealthItem, PermissionName} from "../../../types/health";
import BodyMeasurementWeight from "../../database/entities/health/BodyMeasurementWeight";
import BodyMeasurementHeight from "../../database/entities/health/BodyMeasurementHeight";
import BodyMeasurementBodyFat from "../../database/entities/health/BodyMeasurementBodyFat";
import BodyMeasurementBodyWaterMass from "../../database/entities/health/BodyMeasurementBodyWaterMass";
import BodyMeasurementBoneMass from "../../database/entities/health/BodyMeasurementBoneMass";
import BodyMeasurementLeanBodyMass from "../../database/entities/health/BodyMeasurementLeanBodyMass";
import BodyMeasurementBasalMetabolicRate from "../../database/entities/health/BodyMeasurementBasalMetabolicRate";

const PERMISSION_CONFIG: Record<PermissionName, {field: keyof HealthItem; entity: any}> = {
    Weight: {field: 'weight', entity: BodyMeasurementWeight},
    Height: {field: 'height', entity: BodyMeasurementHeight},
    BodyFat: {field: 'percentage', entity: BodyMeasurementBodyFat},
    BodyWaterMass: {field: 'mass', entity: BodyMeasurementBodyWaterMass},
    BoneMass: {field: 'mass', entity: BodyMeasurementBoneMass},
    LeanBodyMass: {field: 'mass', entity: BodyMeasurementLeanBodyMass},
    BasalMetabolicRate: {field: 'basalMetabolicRate', entity: BodyMeasurementBasalMetabolicRate},
};

export default class HealthService {
    public async store(permissionName: string, data: HealthItem[]): Promise<{inserted: number; skipped: string[]}> {
        if (!AppDataSource.isInitialized) {
            await AppDataSource.initialize();
        }

        const config = PERMISSION_CONFIG[permissionName as PermissionName];
        if (!config) {
            throw new Error(`Unsupported permission: ${permissionName}`);
        }

        const repo = AppDataSource.getMongoRepository(config.entity);
        const ids = data.map(item => item.id);

        const existing = ids.length > 0
            ? await repo.findBy({
                id: { $in: ids }
            })
            : [];

        const existingIds = new Set(existing.map(item => item.id));
        const field = config.field;

        const toInsert = data
            .filter(item => !existingIds.has(item.id))
            .map(item => ({
                id: item.id,
                dataOrigin: item.dataOrigin,
                time: item.time,
                [field]: item[field] ?? null,
            }));

        if (toInsert.length > 0) {
            await repo.save(toInsert);
        }

        return {
            inserted: toInsert.length,
            skipped: Array.from(existingIds)
        };
    }
}
