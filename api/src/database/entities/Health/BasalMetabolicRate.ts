import {
    Column,
    Entity,
} from "typeorm";
import BaseEntity from "../BaseEntity";
import {DECIMAL_PRECISION} from "../../../core/configs/defaults.config";

@Entity({
    name: 'BasalMetabolicRates',
})
export default class BasalMetabolicRate extends BaseEntity implements IModel {
    @Column('decimal', DECIMAL_PRECISION)
    inWatts: number;

    @Column('decimal', DECIMAL_PRECISION)
    inKilocaloriesPerDay: number;
}