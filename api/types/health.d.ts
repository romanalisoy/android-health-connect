export interface SpeedMeasurement {
    inMilesPerHour: number;
    inMetersPerSecond: number;
    inKilometersPerHour: number;
}

export interface SpeedSample {
    speed: SpeedMeasurement;
    time: string;
}

export interface CaloriesBurnedEnergy {
    inKilocalories: number;
    inKilojoules: number;
    inJoules: number;
    inCalories: number;
}

export type SleepStage = {
    stage: number;
    startTime: string;
    endTime: string;
}

export type PermissionName =
    | 'Weight'
    | 'Height'
    | 'BodyFat'
    | 'BodyWaterMass'
    | 'BoneMass'
    | 'LeanBodyMass'
    | 'BasalMetabolicRate';

export interface HealthItem {
    id: string;
    dataOrigin: string;
    time: number;
    weight?: number;
    height?: number;
    percentage?: number;
    mass?: number;
    basalMetabolicRate?: number;
}
