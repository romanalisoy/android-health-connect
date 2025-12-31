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
