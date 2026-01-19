export interface BodyStatsData {
    waist?: number | null;
    neck?: number | null;
    chest?: number | null;
    right_arm?: number | null;
    left_arm?: number | null;
    right_forearm?: number | null;
    left_forearm?: number | null;
    shoulders?: number | null;
    hips?: number | null;
    right_thigh?: number | null;
    left_thigh?: number | null;
    right_calve?: number | null;
    left_calve?: number | null;
}

export interface BodyStatsResponse {
    id: string;
    record_date: string;
    waist: number | null;
    neck: number | null;
    chest: number | null;
    right_arm: number | null;
    left_arm: number | null;
    right_forearm: number | null;
    left_forearm: number | null;
    right_shoulder: number | null;
    left_shoulder: number | null;
    hips: number | null;
    right_thigh: number | null;
    left_thigh: number | null;
    right_calve: number | null;
    left_calve: number | null;
    created_at: Date | string;
    updated_at: Date | string;
}

export type BodyStatField =
    | 'waist'
    | 'neck'
    | 'chest'
    | 'right_arm'
    | 'left_arm'
    | 'right_forearm'
    | 'left_forearm'
    | 'right_shoulder'
    | 'left_shoulder'
    | 'hips'
    | 'right_thigh'
    | 'left_thigh'
    | 'right_calve'
    | 'left_calve';

export type HistoryPeriod = 'month' | 'year' | 'all';

export interface BodyStatHistoryItem {
    record_date: string;
    value: number | null;
}

export interface LatestBodyStats {
    waist: { value: number | null; record_date: string | null };
    neck: { value: number | null; record_date: string | null };
    chest: { value: number | null; record_date: string | null };
    right_arm: { value: number | null; record_date: string | null };
    left_arm: { value: number | null; record_date: string | null };
    right_forearm: { value: number | null; record_date: string | null };
    left_forearm: { value: number | null; record_date: string | null };
    right_shoulder: { value: number | null; record_date: string | null };
    left_shoulder: { value: number | null; record_date: string | null };
    hips: { value: number | null; record_date: string | null };
    right_thigh: { value: number | null; record_date: string | null };
    left_thigh: { value: number | null; record_date: string | null };
    right_calve: { value: number | null; record_date: string | null };
    left_calve: { value: number | null; record_date: string | null };
}
